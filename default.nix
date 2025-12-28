{
  self ? import ./. { },
  sources ? builtins.fromJSON (builtins.readFile ./npins.json),
  system ? builtins.currentSystem,
  nixos-release ? "nixos-unstable",
  nixpkgs ? fetchTarball {
    url = sources.pins.${nixos-release}.url;
    sha256 = sources.pins.${nixos-release}.hash;
  },
  pkgs ? import nixpkgs {
    inherit system;
    config = { };
    overlays = [ ];
  },
  crossCompPkgs ? import nixpkgs {
    crossSystem.system = "aarch64-linux";
    localSystem.system = system;
    config = { };
    overlays = [ ];
  },
}:
{
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

  installer-bootstrap =
    let
      installer-system = crossCompPkgs.callPackage ./iso-configuration {
        inherit self system;
      };
    in
    installer-system.config.system.build.isoImage.overrideAttrs (oldAttrs: {
      passthru = (oldAttrs.passthru or { }) // {
        config = installer-system.config;
      };
    });

  packages = {
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
  };
}
