{
  description = "Shared NixOS configuration for multiple servers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      # Build a host from hosts/<name>/ plus the shared modules.
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
      nixosModules.common = ./modules/common.nix;

      # Add a new server: create hosts/<name>/{default.nix,hardware-configuration.nix}
      # and append <name> to this list.
      nixosConfigurations = nixpkgs.lib.genAttrs [ "nixos" ] mkHost;
    };
}
