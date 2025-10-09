# Overview 

This guide was tested with the following software releases:
| Software                                                                                  | Release          |
|-------------------------------------------------------------------------------------------|------------------|
| [nix-community/nixos-apple-silicon](https://github.com/nix-community/nixos-apple-silicon) | 2025-08-23       |
| [AsahiLinux/linux](https://github.com/AsahiLinux/linux)                                   | asahi-6.14.8-1   |
| [AsahiLinux/m1n1](https://github.com/AsahiLinux/m1n1)                                     | v1.4.21          |
| [NixOS/nixpkgs](https://github.com/NixOS/nixpkgs)                                         | As of 2025-08-19 |
| MacOS                                                                                     | 13.5             |

NOTE: The latest version of this guide will always be [at its home](https://github.com/nix-community/nixos-apple-silicon/blob/main/docs/uefi-standalone.md). For more general information about Linux on Apple Silicon Macs, refer to the [Asahi Linux project](https://asahilinux.org/).

This guide will explain how to install NixOS on the internal NVMe drive of an Apple Silicon Mac using a customized version of the official NixOS install ISO, then boot it without the help of another computer. Aside from the Apple Silicon support module and AArch64 CPU, the resulting installation can be configured and operated like any other NixOS system. Your macOS install will still work normally, and you can easily switch between booting both macOS and NixOS.

Perusing this guide might also be useful to users of other distros. Most of the hard work, including the kernel and boot software, was done by the [Asahi Linux project](https://asahilinux.org/).

## Warning
Damage to the macOS recovery partitions or the partition table could result in the Mac becoming unbootable and loss of all data on the internal NVMe drive. In this circumstance, a suitable USB cable and another computer which can run [idevicerestore](https://github.com/libimobiledevice/idevicerestore) will be required to perform a DFU upgrade and restore normal operation. Backups are always wise.

While you will end up with a reasonably usable computer, the exact hardware features you want [may not be ready yet](https://github.com/AsahiLinux/docs/wiki/%22When-will-Asahi-Linux-be-done%3F%22). Please consult the [Asahi Linux Feature Support page](https://github.com/AsahiLinux/docs/wiki/Feature-Support) for information. Any features marked with a kernel version or `linux-asahi` should be supported by NixOS too.

## Prerequisites

The following items are required to get started:
* Apple Silicon Mac [supported by Asahi Linux](https://github.com/AsahiLinux/docs/wiki/Feature-Support#table-of-contents) with macOS 12.3 or later and an admin account
* For Mac mini users: tested and working HDMI monitor. Many do not work properly; if it shows the Asahi Linux logo and console when m1n1 is running, it's fine.
* USB flash drive which is at least 512MB and can be fully erased
* Familiarity with the command line and installers without GUIs
* Optional: an x86_64 or aarch64 Linux PC or VM (any distro is fine)
