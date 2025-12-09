{
  self ? import ./. { },
  sources ? import ./npins,
  nixpkgs ? sources.nixpkgs,
  system ? builtins.currentSystem,
  crossSystem ? "aarch64-linux",
  pkgs ? import nixpkgs {
    inherit system;
    config = { };
    overlays = [ ];
  },
  crossCompPkgs ? import nixpkgs {
    crossSystem.system = crossSystem;
    localSystem.system = system;
    config = { };
    overlays = [ ];
  },
}:
{
  inherit self sources;
  outPath = ./.;

  shell = pkgs.mkShellNoCC {
    packages = with pkgs; [
      npins
      nixfmt-tree
    ];
  };

  overlays = {
    apple-silicon-overlay = import ./apple-silicon-support/packages/overlay.nix;
  };

  nixosModules = {
    apple-silicon-support = ./apple-silicon-support;
  };

  packages = {
    nas-manual = pkgs.callPackage ./apple-silicon-support/packages/nas-manual { };
    linux-asahi = (crossCompPkgs.callPackage ./apple-silicon-support/packages/linux-asahi { }).kernel;
    uboot-asahi = crossCompPkgs.callPackage ./apple-silicon-support/packages/uboot-asahi { };
    # Experimental: hardware compatability and multi-os support is
    # degraded. Overlay this onto the `uboot-asahi` attribute in
    # consuming configurations. See
    # <https://github.com/NixOS/nixpkgs/pull/430267> for more details
    # regarding upstream uboot support.
    ubootAppleM1 = crossCompPkgs.buildUBoot {
      defconfig = "apple_m1_defconfig";
      extraConfig = ''
        CONFIG_VIDEO_FONT_4X6=n
        CONFIG_VIDEO_FONT_8X16=n
        CONFIG_VIDEO_FONT_SUN12X22=n
        CONFIG_VIDEO_FONT_16X32=y
      '';
      extraMeta.platforms = [ "aarch64-linux" ];
      filesToInstall = [ "u-boot-nodtb.bin.gz" ];
      preInstall = ''
        gzip -n u-boot-nodtb.bin
      '';
    };

    installer-iso =
      let
        installer-system = (
          crossCompPkgs.callPackage ./apple-silicon-support/packages/installer-iso {
            inherit self system;
          }
        );
      in
      installer-system.system.build.isoImage.overrideAttrs (oldAttrs: {
        passthru = (oldAttrs.passthru or { }) // {
          config = installer-system.config;
        };
      });
  };
}
