{
  description = "Shared NixOS configuration for multiple servers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Standalone home-manager: users own their configs in ~/.config/home-manager.
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      # A server is the shared modules plus everything in hosts/<name>/.
      mkHost = name: nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          { networking.hostName = name; }
          self.nixosModules.common
          ./hosts/${name}
        ];
      };
    in
    {
      # modules/default.nix imports one file per topic
      nixosModules.common = ./modules;

      # To add a server: create hosts/<name>/{default.nix,hardware-configuration.nix}
      # and add <name> to this list.
      nixosConfigurations = nixpkgs.lib.genAttrs [ "nixos" ] mkHost;
    };
}
