# Software Preparation

We will use Nix to build an installation ISO that we can boot off of. If building an ISO on your own end isn't possible, then you can use an ISO automatically built by [GitHub Releases ](https://github.com/nix-community/nixos-apple-silicon/releases) which also provides the corresponding SHA256 hash for verification.

## Building the ISO
If you have flakes enabled in your Nix installation: you can easily build an installation ISO through this one-liner:

```shellsession
nix build github:nix-community/nixos-apple-silicon/release-2025-08-23#installer-bootstrap -o installer -L
```

Otherwise, you can follow step by step instructions on how to build the ISO from a checkout of the repository. You can also follow these steps if building the ISO directly using the one-liner above fails for whatever reason.

### Clone this repository
Firstly, clone this repository onto your host PC using git. This will provide the working area for building the specified Asahi Linux components as well as being able to easily update to a newer released version if needed.

You may also download a source artifact from  [GitHub Releases ](https://github.com/nix-community/nixos-apple-silicon/releases) of the specific release you want to construct an ISO out of.

```shellsession
$ git clone https://github.com/nix-community/nixos-apple-silicon
$ cd nixos-apple-silicon
$ git checkout release-2025-08-23
```

### Build the ISO

#### m1n1
The Asahi Linux project has developed m1n1 as a bridge between Apple's boot firmware and the Linux world. m1n1 is installed as a faux macOS kernel into a stub macOS installation. In addition to booting Linux (or U-Boot), m1n1 also sets up the hardware and allows remote control and debugging over USB.

```shellsession
nix build --extra-experimental-features 'nix-command flakes' .#m1n1 -o m1n1 -L 
```

m1n1 has been built and the build products are now in `m1n1/build/`. You can also run m1n1's scripts such as `chainload.py` using a command like `m1n1/bin/m1n1-chainload`.

#### Das U-Boot
In the default installation, m1n1 loads U-Boot and U-Boot is used to set up a standard UEFI environment from which GRUB or systemd-boot or whatever can be booted. Due to the limitations of the Apple boot picker, there must be one EFI system partition per installed OS.

Use Nix to build U-Boot along with m1n1 and the device trees:

```
nix build --extra-experimental-features 'nix-command flakes' .#uboot-asahi -o u-boot -L
```

#### Linux Asahi
The Asahi team maintain a vendor kernel which contains all the necessary modules required to boot and run Linux on Apple silicon devices. This kernel unfortunately cannot be upstreamed into nixpkgs itself, so it will have to be built from source.

```
nix build --extra-experimental-features 'nix-command flakes' .#linux-asahi -o linux-asahi -L
```


#### Installer Bootstrap ISO
The bootstrap NixOS installer ISO contains UEFI-compatible GRUB, the Asahi Linux kernel, its initrd, and enough packages and drivers to allow connection to the Internet in order to download and install a full NixOS system.

Building the image requires downloading of a large amount of data and compilation of a number of packages, including the kernel. On my six core Xeon laptop, building it took about 11 minutes (90 CPU minutes). Your mileage may vary. You can use the `-j` option to specify the number of packages to build in parallel. Each is allowed to use all cores, but for this build, most do not use more than one. Therefore, it is recommended to set it to less than the number of physical cores in your machine. You can also use the `-L` option to view detailed build logs.

```shellsession
nix build --extra-experimental-features 'nix-command flakes' .#installer-bootstrap -o installer -j4 -L
```

The installer ISO is now available as `installer/iso/nixos-*.iso`. Use `dd` or similar to transfer it to your USB flash drive. Programs like `unetbootin` are not supported.
