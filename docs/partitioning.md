# Installing

## Booting the Installer

Shut down the machine fully. Connect the flash drive with the installer ISO to a USB port. If not using WiFi, connect the Ethernet cable to the network port or adapter as well. If you are using WiFi, use `iwd` to connect to it.

```shellsession
nixos# iwctl
NetworkConfigurationEnabled: enabled
StateDirectory: /var/lib/iwd
Version: 2.4
[iwd]# station wlan0 scan
[iwd]# station wlan0 connect <SSID>
Type the network passphrase for <SSID> psk.
Passphrase: <your passphrase>
[iwd]# station wlan0 show
[...]
[iwd] exit
```

Once the network is set up, ensure the time is set correctly:

```shellsession
nixos# systemctl restart systemd-timesyncd
```

Start the Mac, and U-Boot should start booting from the USB drive automatically. If you've already installed something to the internal NVMe drive, U-Boot will try to boot it first. To instead boot from USB, hit a key to stop autoboot when prompted, then run the command `bootmenu` and select the `usb 0` entry. If no entries are available, exit and use `bootmenu -e` instead. If this command is not available, instead use `env set boot_efi_bootmgr ; run bootcmd_usb0`. GRUB will start, then the NixOS installer after a short delay (the default GRUB option is fine).

<details>
  <summary>If "mounting `/dev/root` on `/mnt-root/iso` failed: No such file or directory" during boot…</summary>
  
  1. Was the ISO transferred to your flash drive correctly as described above? `dd` is the only correct way to do this. The ISO must be transferred to the drive block device itself, not a partition on the drive.
  2. There is sometimes a [race condition](https://github.com/nix-community/nixos-apple-silicon/issues/60) which causes booting to fail. Reboot the machine and try again.
  3. Some flash drives have quirks. Try a different drive, or use the following steps:

      1. Attempt to start the installer normally
      1. When the boot fails and you are prompted, hit i to start a shell
      1. Unplug your flash drive, plug it into a different port, then wait 30 seconds
      1. Run the command `mount -t iso9660 /dev/root /mnt-root/iso`
      1. Exit the shell by running `exit` to continue the boot process
</details>

You will get a console prompt once booting completes. Run the command `sudo su` to get a root prompt in the installer. If the console font is too small, run the command `setfont ter-v32n` to increase the size.

## Partitioning and Formatting

**DANGER: Damage to the GPT partition table, first partition (`iBootSystemContainer`), or the last partition (`RecoveryOSContainer`) could result in the loss of all data and render the Mac unbootable and unrecoverable without assistance from another computer! Do not use your distro's automated partitioner or partitioning instructions!**

We will add a root partition to the remaining free space and format it as ext4. Alternative partition layouts and filesystems, including LUKS encryption, are possible, but not covered by this guide.

Create the root partition to fill up the free space:
```
nixos# sgdisk /dev/nvme0n1 -n 0:0 -s
[...]
The operation has completed successfully.
```

Identify the number of the new root partition (type code 8300, typically second to last):
```
nixos# sgdisk /dev/nvme0n1 -p
Disk /dev/nvme0n1: 244276265 sectors, 931.8 GiB
Model: APPLE SSD AP1024Q                       
Sector size (logical/physical): 4096/4096 bytes
Disk identifier (GUID): 27054D2E-307A-41AA-9A8C-3864D56FAF6B
Partition table holds up to 128 entries
Main partition table begins at sector 2 and ends at sector 5
First usable sector is 6, last usable sector is 244276259
Partitions will be aligned on 1-sector boundaries
Total free space is 0 sectors (0 bytes)

Number  Start (sector)    End (sector)  Size       Code  Name
   1               6          128005   500.0 MiB   FFFF  iBootSystemContainer
   2          128006       219854567   838.2 GiB   AF0A  Container
   3       219854568       220465127   2.3 GiB     AF0A  
   4       220465128       220590311   489.0 MiB   EF00  
   5       220590312       242965550   85.4 GiB    8300  
   6       242965551       244276259   5.0 GiB     FFFF  RecoveryOSContainer
```

Format the new root partition:
```
nixos# mkfs.ext4 -L nixos /dev/nvme0n1p5
```

Mount the root partition, then the EFI system partition that was created by the Asahi Linux installer specifically for NixOS:
```nix
nixos# mount /dev/disk/by-label/nixos /mnt
nixos# mkdir -p /mnt/boot
nixos# mount /dev/disk/by-partuuid/`cat /proc/device-tree/chosen/asahi,efi-system-partition` /mnt/boot
```
