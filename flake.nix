{
  description = "Apple Silicon support for NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-compat.url = "github:nix-community/flake-compat";
  };

  outputs =
    { self, ... }@inputs:
    let
      inherit (self) outputs;
      # build platforms supported for uboot in nixpkgs
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ]; # "i686-linux" omitted

      forAllSystems = inputs.nixpkgs.lib.genAttrs systems;
    in
    {
      formatter = forAllSystems (
        system:
        inputs.nixpkgs.legacyPackages.${system}.nixfmt-tree.override {
          runtimeInputs = [
            inputs.nixpkgs.legacyPackages.${system}.mdl
          ];

          settings = {
            formatter."markdownlint" = {
              command = "mdl";
              options = [
                "-r"
                # MD013: disable line length rule
                # MD014: allow not having output in shell commands
                "~MD013,~MD014"
              ];
              includes = [ "*.md" ];
            };
          };
        }
      );
      checks = forAllSystems (system: {
        formatting = outputs.formatter.${system};
      });

      devShells = forAllSystems (system: {
        default = inputs.nixpkgs.legacyPackages.${system}.mkShellNoCC {
          packages = [
            outputs.formatter.${system}
            inputs.nixpkgs.legacyPackages.${system}.mdbook
          ];
        };
      });

      overlays = {
        apple-silicon-overlay = import ./apple-silicon-support/packages/overlay.nix;
        default = outputs.overlays.apple-silicon-overlay;
      };

      nixosModules = {
        apple-silicon-support = ./apple-silicon-support;
        default = outputs.nixosModules.apple-silicon-support;
      };

      packages = forAllSystems (
        system:
        let
          pkgs = import inputs.nixpkgs {
            crossSystem.system = "aarch64-linux";
            localSystem.system = system;
            overlays = [
              outputs.overlays.default
            ];
          };
        in
        {
          inherit (pkgs)
            uboot-asahi
            asahi-fwextract
            ;
          inherit (pkgs) asahi-audio;

          linux-asahi = pkgs.linux-asahi.kernel;

          installer-bootstrap =
            let
              installer-system = inputs.nixpkgs.lib.nixosSystem {
                inherit system;

                specialArgs = {
                  modulesPath = inputs.nixpkgs + "/nixos/modules";
                };

                modules = [
                  ./iso-configuration
                  {
                    hardware.asahi.pkgsSystem = system;

                    # make sure this matches the post-install
                    # `hardware.asahi.pkgsSystem`
                    nixpkgs.hostPlatform.system = "aarch64-linux";
                    nixpkgs.buildPlatform.system = system;
                    nixpkgs.overlays = [ outputs.overlays.default ];
                  }
                ];
              };

              config = installer-system.config;
            in
            (config.system.build.isoImage.overrideAttrs (old: {
              # add ability to access the whole config from the command line
              passthru = (old.passthru or { }) // {
                inherit config;
              };
            }));
        }
      );
    };
}
