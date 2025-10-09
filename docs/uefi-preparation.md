# UEFI Preparation

This setup uses the alpha Asahi Linux installer to install a stub macOS and standard UEFI boot environment from which the NixOS installer and installed OS will run. These steps must be run from Terminal.app in macOS. You must also be logged into an administrator account.

Download and run the installer using the following command (also available on the [Asahi homepage](https://asahilinux.org/))

```shellsession
curl https://alx.sh | sh
```

Choose the following options to get started:

* Enter your administrator password
* Do not enable expert mode

Resize your existing macOS install:

* Resize an existing partition to make space for a new OS (`r`)
* Enter the new size of the macOS install. It should be at least 20GB less than its current size to make room for NixOS with a GUI (note that here 1GB = 1,000,000,000 bytes)
* Confirm the resize operation
* Wait patiently while the partition is resized; it will take several minutes. Do not attempt to use the machine while this is in progress.
* Press enter when finished

Install UEFI environment:

* Install an OS into free space (`f`)
* UEFI environment only
* Name it NixOS (this is what shows up in the firmware boot picker)
* Wait while the installation proceeds and enter your password when prompted
* Wait for the default boot volume to be set (this may take several seconds)
* Read the final advice, then press enter to shut down the machine

Boot into recovery mode by holding the power button down as directed and select the new NixOS option in the boot picker. Follow the prompts and enter your administrator password. The local policy update will take several seconds to complete. Once complete, select that you want to set a custom boot object and put your system to permissive security mode, enter your administrator username (the same one you put in the password for earlier) and password, then reboot when prompted.

If everything went well, you will restart into U-Boot with the Asahi Linux and U-Boot logos on-screen. Shut the system down by holding the power button, then proceed to the next step.
