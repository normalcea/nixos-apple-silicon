# Recovering from Boot Failure with `idevicerestore`

In extremely extreme circumstances (i.e. something messed up the firmware partition, recovery partition, or partition table), your Mac may fail to boot. On the Mac mini (and presumably Mac Studio), this state is identifiable by a flashing orange power light indicating the Morse code for SOS. On a Mac laptop, this state is identifiable by an illustration of an exclamation point in a circle on the screen with a link to Apple's website.

To make the Mac bootable again, you can use [idevicerestore](https://github.com/libimobiledevice/idevicerestore) from another Mac or Linux x86_64 or aarch64 VM or computer that has an Internet connection. You will need a USB cable with at least one USB-C end. This procedure has been tested with Mac and Linux hosts restoring a Mac mini with macOS 12.4.

Please note that this procedure may require you to unrecoverably destroy all data on the Mac's internal drive. If erasing is necessary, you will be clearly warned and asked to confirm before it happens. The drive will end up zeroed and its encryption keys (probably) regenerated, so not even the NSA will be able to save you. If you haven't made backups, make peace with yourself now.

To start the procedure, hook up the appropriate port on your unbootable Mac to the second computer and invoke DFU mode. This process is covered by Steps 1 and 2 of [Apple's documentation](https://support.apple.com/guide/apple-configurator-mac/revive-or-restore-a-mac-with-apple-silicon-apdd5f3c75ad/mac). We will first try what Apple calls a "revive" where the disk is not erased, although both we and `idevicerestore` still call it a "restore".

If DFU mode was started correctly, the unbootable Mac will show up on your second computer as an `Apple, Inc. Mobile Device (DFU Mode)` in `lsusb` on Linux or System Information on macOS. If you see `Apple, Inc. Apple Mobile Device [Recovery Mode]` instead (or nothing), the procedure was not followed correctly and you need to try again.


Open a terminal on your second computer. You need `usbmuxd` (only if on Linux) and `idevicerestore`. nixpkgs (both unstable and stable) provide sufficiently updated package versions. If you're on NixOS, set `services.usbmuxd.enable = true;` to get udev rules, system services etc. configured. If you're on another Linux, you need to run `usbmuxd` as root in the background, without any arguments (or manually set up udev rules and system services).

Then, ask `idevicerestore` to restore the firmware by using the `--latest` flag. If you wish to erase the disk either because the revive didn't work or because you want to start with a clean slate, use the `--erase` flag also.

```
# sudo idevicerestore --latest
idevicerestore 1.0.0-unstable-2022-05-22
Found device in DFU mode
Identified device as j274ap, Macmini9,1
The following firmwares are currently being signed for Macmini9,1:
[...]
Select the firmware you want to restore:
```

Once `idevicerestore` detects the unbootable Mac, select the desired firmware (usually number `1`) and wait patiently while the firmware is downloaded; it's about 13GiB. If `idevicerestore` doesn't detect the unbootable Mac, make sure that your cables are hooked up correctly, that you used `sudo`, and that you are using a suitably recent version.

The restore process will automatically start once the firmware is downloaded and verified. If `idevicerestore` fails with the message `ERROR: Device did not disconnect. Possibly invalid iBEC. Reset device and try again.`, the unbootable Mac is likely not in DFU mode, or there is something wrong with your system's udev related to hotplug events. Check that you followed Apple's procedure correctly and that the appropriate USB device is detected.

After 30 or so seconds of messages and status updates, you should see the Apple logo on the unbootable Mac's screen with a progress bar and `idevicerestore` will tell you that it is `Waiting for device to enter restore mode...`. If the unbootable Mac resets after a couple minutes and you get the message `ERROR: Device failed to enter restore mode. Please make sure that usbmuxd is running.`, then `usbmuxd` is likely not running. Start it and try again.

Once the restore process starts, the progress bar will start moving and `idevicerestore` will spam lots of information about the process. If it fails with `ERROR: Unable to restore device`, your only choice may be to restart the process, but this time pass the `--erase` flag to `idevicerestore` and destroy all data on the unbootable Mac's internal drive.

Otherwise, wait patiently while the restore proceeds. Expect it to take 20 or 30 minutes. Eventually `idevicerestore` will say `DONE` and the formerly-unbootable Mac will reboot and start recovery mode (if erasing was not necessary) or the out-of-the-box wizard (if the disk was erased) and you can use it again.

Finally, shut down `usbmuxd` if on Linux and you started it manually. To clean up your second computer, remove the downloaded firmware, the `idevicerestore` and `usbmuxd` GC roots, and run the Nix garbage collector:
```
# sudo killall usbmuxd # if on Linux
# sudo rm -rf *.ipsw* UniversalMac*
# rm -f result* usbmuxd idevicerestore
# nix-collect-garbage
```
