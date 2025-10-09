# Uninstallation

## Host PC Cleanup

To recover the space on the host PC, change directories into the repo, remove the built symlinks (removing just the installer will recover almost all the space), then run the garbage collector:

```
nixos-apple-silicon$ rm m1n1 u-boot installer result
nixos-apple-silicon$ nix-collect-garbage
```

## NixOS Uninstallation

NixOS can be completely uninstalled by deleting the stub partition, EFI system partition, and root partition off the disk.

Boot back into macOS by shutting down the machine fully, then pressing and holding the power button until the boot picker comes up. Select the macOS installation, then click Continue to boot it. Log into an administrator account and open Terminal.app.

Identify the partitions to remove. In this example, `disk0s3` is the stub because of its small size. `disk0s4` is the EFI system partition and `disk0s5` is the root partition:
```
% diskutil list disk0
/dev/disk0 (internal):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:      GUID_partition_scheme                         1.0 TB     disk0
   1:             Apple_APFS_ISC                         524.3 MB   disk0s1
   2:                 Apple_APFS Container disk4         900.0 GB   disk0s2
   3:                 Apple_APFS Container disk3         2.5 GB     disk0s3
   4:                        EFI EFI - NIXOS             512.8 MB   disk0s4
   5:           Linux Filesystem                         91.6 GB    disk0s5
   6:        Apple_APFS_Recovery                         5.4 GB     disk0s6
```

WARNING: Unlike Linux, on macOS each partition's identifier does not necessarily equal its partition index. Double check the identifiers of your own system!

Remove the EFI system partition and root partition:
```
% diskutil eraseVolume free free disk0s4
Started erase on disk0s4 (EFI - NIXOS)
Unmounting disk
Finished erase on disk0
% diskutil eraseVolume free free disk0s5
Started erase on disk0s5
Unmounting disk
Finished erase on disk0
```

Remove the stub partition:
```
% diskutil apfs deleteContainer disk0s3
Started APFS operation on disk3
Deleting APFS Container with all of its APFS Volumes
[...]
Removing disk0s3 from partition map
```

Expand the main macOS partition to use the resulting free space. This command will take a few minutes to run; do not attempt to use the machine while it is in progress:
```
% diskutil apfs resizeContainer disk0s2 0
Started APFS operation
Aligning grow delta to 94,662,586,368 bytes and targeting a new physical store size of 994,662,584,320 bytes
[...]
Finished APFS operation
```

To complete the uninstallation, open the Startup Disk pane of System Preferences and select your macOS installation as the startup disk. If this is not done, the next boot will fail, and you will be asked to select another OS to boot from.
