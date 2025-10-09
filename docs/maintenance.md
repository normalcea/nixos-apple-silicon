# Maintenance

## Rescue

If something goes wrong and NixOS doesn't boot or is otherwise unusable, you can first try rolling back to a previous generation. Instead of selecting the default bootloader option, choose another configuration that worked previously.

If something is seriously wrong and the bootloader does not work (or you don't have any other generations), you will want to get back into the installer. To start the installer with a system installed on the internal disk, shut down the computer, re-insert the USB drive with the installer, start it up again, hit a key in U-Boot when prompted to stop autoboot, then run the command `bootmenu` and select the `usb 0` entry. If no entries are available, exit and use `bootmenu -e` instead. If this command is not available, instead use `env set boot_efi_bootmgr ; run bootcmd_usb0`.

Once in the installer, you can re-mount your root partition and EFI system partition without reformatting them. Depending on what exactly went wrong, you might need to edit your configuration, copy over the latest Apple Silicon support module, or update U-Boot using the latest installer.

Rerunning the installer will create a new generation but not touch any user data. This means you can "undo" the installation by selecting a previous generation in the bootloader. To redo the installation without changing your root password or changing the version of Nixpkgs, run:

```shellsession
# nixos-install --no-root-password --no-channel-copy
```

In extreme circumstances, you can delete the EFI system partition and stub macOS install and rerun the Asahi Linux installer, then follow the steps above to reinstall NixOS's bootloader menu. You will need to regenerate the hardware configuration using `nixos-generate-config --root /mnt` because the EFI system partition's ID will change. This shouldn't modify your root partition or other NixOS configuration, but of course it's always smart to have a backup. You might also wish to re-copy the peripheral firmware files.

## NixOS Updates

When using NixOS channels (the default when installing from the ISO), you can update the installed system by updating the channel and rebuilding like so:

```shellsession
$ sudo nix-channel --update
$ sudo nixos-rebuild switch
```

You may have to reboot after updating in some cases. If something goes wrong, you can boot a previous generation and roll back the channel update. For more details, consult the [Upgrading section](https://nixos.org/manual/nixos/stable/index.html#sec-upgrading) of the NixOS manual.

## Apple Silicon Support Updates

To update the Apple Silicon support module, including the Asahi kernel and U-Boot, you can simply download newer files from this repo under `apple-silicon-support` and place them under `/etc/nixos/apple-silicon-support`.

U-Boot and m1n1 are automatically managed by NixOS' bootloader system. If you roll back to a previous generation and things do not work properly due to a device tree incompatibility, you can run `/run/current-system/bin/switch-to-configuration switch` then reboot to force the bootloader and the correct version of U-Boot/m1n1 to be reinstalled and loaded.

If you want the Apple Silicon support module to be upgraded in tandem with NixOS instead of manually downloading new files, you can add it as a channel with the following command:

```shellsession
$ sudo nix-channel --add https://github.com/nix-community/nixos-apple-silicon/archive/main.tar.gz apple-silicon-support
```

Modify your `/etc/nixos/configuration.nix` to reference the channel instead of the local files:

```nix
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # Include the necessary packages and configuration for Apple Silicon support.
      <apple-silicon-support/apple-silicon-support>
    ];
```

You can now update and reboot into your new NixOS after updating your channels and switching to the new configuration. Note that this will track the latest development branch, so breaking changes may occur between channel updates.
