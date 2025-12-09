{
  self ? import ./. { },
  sources ? import ./npins,
  system ? builtins.currentSystem,
  crossSystem ? "aarch64-linux",
  pkgs ? import sources.nixpkgs {
    inherit system;
    config = { };
    overlays = [ ];
  },
  crossCompPkgs ? import sources.nixpkgs {
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
    linux-asahi = (crossCompPkgs.callPackage ./apple-silicon-support/packages/linux-asahi { }).kernel;
    uboot-asahi = crossCompPkgs.callPackage ./apple-silicon-support/packages/uboot-asahi { };
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
