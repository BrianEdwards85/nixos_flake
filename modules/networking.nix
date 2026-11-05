# Network setup. The hostname is set per host by flake.nix.
{ ... }:

{
  networking.networkmanager.enable = true;

  # IPv6 is not used
  networking.enableIPv6 = false;
}
