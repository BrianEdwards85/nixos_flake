# Placeholder. nixos-anywhere overwrites this with --generate-hardware-config.
# Filesystems come from disko.nix, not here.
{ lib, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
