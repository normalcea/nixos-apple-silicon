{
  description = "Apple Silicon support for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, ... }@inputs:
    let
      inherit (self) outputs;
      # build platforms supported for uboot in nixpkgs
      nasImported = import ./. {
        system = "aarch64-linux";
        pkgs = inputs.nixpkgs.legacyPackages."aarch64-linux";
      };
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ]; # "i686-linux" omitted

      forAllSystems = inputs.nixpkgs.lib.genAttrs systems;
    in
    {
      formatter = forAllSystems (system: nasImported.formatter);
      checks = forAllSystems (system: {
        formatting = outputs.formatter.${system};
      });

      devShells = forAllSystems (system: {
        default = nasImported.shell;
      });

      overlays = {
        apple-silicon-overlay = nasImported.overlays.apple-silicon-overlay;
        default = outputs.overlays.apple-silicon-overlay;
      };

      nixosModules = {
        apple-silicon-support = nasImported.nixosModules.apple-silicon-support;
        default = outputs.nixosModules.apple-silicon-support;
      };

      packages."aarch64-linux" = {
        inherit (nasImported.packages) linux-asahi uboot-asahi;
        inherit (nasImported) installer-bootstrap;
      };
    };
}
