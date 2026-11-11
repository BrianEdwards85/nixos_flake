{
  description = "Shared NixOS configuration for multiple servers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Standalone home-manager: users own their configs in ~/.config/home-manager.
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Disk partitioning for nixos-anywhere installs.
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      # Machines you might run `nix fmt` / `nix flake check` on (not the servers' own architecture)
      devSystems = [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      forDevSystems = f: nixpkgs.lib.genAttrs devSystems (system: f nixpkgs.legacyPackages.${system});

      # A server is the shared modules, everything in hosts/<name>/, and the
      # optional modules listed for it (a file from ./modules that not every
      # server gets).
      mkHost =
        name: extraModules:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            { networking.hostName = name; }
            self.nixosModules.common
            ./hosts/${name}
          ]
          ++ extraModules;
        };
    in
    {
      # modules/default.nix imports one file per topic
      nixosModules.common = ./modules;

      # To add a server: create hosts/<name>/{default.nix,hardware-configuration.nix}
      # and add <name> here with its optional modules (usually none).
      nixosConfigurations = builtins.mapAttrs mkHost {
        nixos = [ ];
        hosaka = [ ./modules/wireguard.nix ];
        free-side = [ ];
        angel = [ ];
      };

      # `nix fmt` formats every .nix file except the generated hardware config
      formatter = forDevSystems (
        pkgs:
        pkgs.nixfmt-tree.override {
          settings.global.excludes = [ "hosts/*/hardware-configuration.nix" ];
        }
      );

      # `nix flake check` evaluates every host's configuration (catching type errors and
      # missing options without building anything) and also runs this formatting check.
      checks = forDevSystems (pkgs: {
        formatting = pkgs.runCommand "check-formatting" { nativeBuildInputs = [ pkgs.nixfmt ]; } ''
          cd ${self}
          nixfmt --check flake.nix modules/*.nix hosts/*/default.nix
          touch $out
        '';
      });
    };
}
