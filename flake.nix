{
  # This project does not use flakes, this shim is provided for flake
  # users only. Make sure to add:

  # inputs.nixpkgs.follows = "nixpkgs";

  # to your n-a-s flake input to avoid the indirect usage of nixpkgs
  # here.
  description = "Apple Silicon support for NixOS; flake shim";

  outputs =
    {
      self,
      nixpkgs,
      ...
    }:
    let
      inherit (self) outputs;
      nasImported = import "${./.}" {
        system = "aarch64-linux";
        pkgs = nixpkgs.legacyPackages."aarch64-linux";
      };
    in
    {
      nixosModules = {
        apple-silicon-support = nasImported.nixosModules.apple-silicon-support;
        default = outputs.nixosModules.apple-silicon-support;
      };

      overlays = {
        apple-silicon-overlay = nasImported.overlays.apple-silicon-overlay;
        default = outputs.overlays.apple-silicon-overlay;
      };

      packages."aarch64-linux" = nasImported.packages;
    };
}
