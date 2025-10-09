# NixOS Configuration

The subsequent steps in this section will help you install NixOS onto your new partitions. More information is available in the Installing section of the [NixOS manual](https://nixos.org/manual/nixos/stable/index.html#sec-installation-installing). Some changes to the configuration procedure as described in that manual are needed for NixOS on Apple Silicon to work properly.

Create a default configuration for the new system, then copy the Apple Silicon support module into it:

```nix
nixos# nixos-generate-config --root /mnt
nixos# cp -r /etc/nixos/apple-silicon-support /mnt/etc/nixos/
nixos# chmod -R +w /mnt/etc/nixos/
```

Use Nano to edit the configuration of the new system to include the Apple Silicon support module. Be aware that other editors and most documentation has been left out of the bootstrap installer to save space and time.

```shellsession
nixos# nano /mnt/etc/nixos/configuration.nix
```

Add the `./apple-silicon-support` directory to the imports list and switch off the `canTouchEfiVariables` option. That portion of the file should look like this:

```nix
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # Include the necessary packages and configuration for Apple Silicon support.
      ./apple-silicon-support
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;
```

The configuration above is the minimum required to produce a bootable system, but you can further edit the file as desired to perform additional configuration. Uncomment the relevant options and change their values as explained in the file. Note that some advertised features may not work properly at this time. Refer to the [NixOS installation manual](https://nixos.org/manual/nixos/stable/index.html#ch-configuration) for further guidance.

Various non-free non-redistributable peripheral firmware files are required to use system hardware like Wi-Fi. The Asahi Linux installer grabs these from macOS and stores them on the EFI system partition when it is created. The NixOS installer loads them from there while booting so that all hardware is available during installation. By default, the Apple Silicon support module will automatically reference the files in the EFI system partition and incorporate them into your configuration to be managed by the normal NixOS mechanisms.

Currently, the only supported way to update the peripheral firmware files is to destroy and re-create the EFI system partition, so they will not change unexpectedly. If you do not want the impurity of referencing them (or are using flakes where this is prohibited), copy them off the EFI system partition (e.g. on the installation ISO `mkdir -p /mnt/etc/nixos/firmware && cp /mnt/boot/asahi/{all_firmware.tar.gz,kernelcache*} /mnt/etc/nixos/firmware`) and specify this path in your configuration:

```nix
  # Specify path to peripheral firmware files.
  hardware.asahi.peripheralFirmwareDirectory = ./firmware;
  # Or disable extraction and management of them completely.
  # hardware.asahi.extractPeripheralFirmware = false;
```

Some keyboard layouts are not detected correctly. On some devices, the \` key is swapped with `<`, and `~` with `>`. The layout can be fixed by setting options in `boot.extraModprobeConfig`. Which option needs to be set depends on your hardware keyboard's layout (see: [Arch Wiki - Apple Keyboard](https://wiki.archlinux.org/title/Apple_Keyboard)).

 ```nix
 # For ` to < and ~ to > (for those with US keyboards)
 boot.extraModprobeConfig = ''
   options hid_apple iso_layout=0
 '';
 ```

Use iwd in the configuration instead of wpa_supplicant because the latter [does not support WPA3 on broadcom chips](https://www.reddit.com/r/AsahiLinux/comments/12igyoa/comment/jftvl3c)

```nix
networking.wireless.iwd = {
  enable = true;
  settings.General.EnableNetworkConfiguration = true;
};
```

## NixOS Installation

Once complete, reboot the system:

```shellsession
nixos# reboot
```

When the system reboots, the bootloader will come up and boot the default configuration after a short delay. Once NixOS boots, log in with the root password, and create your account, or set your user account password if you created your account in the configuration. To learn more about NixOS's configuration system, read the section in the manual on [changing the configuration](https://nixos.org/manual/nixos/stable/index.html#sec-changing-config).
