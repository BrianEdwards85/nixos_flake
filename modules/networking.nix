# Network setup. The hostname is set per host by flake.nix.
{ ... }:

{
  networking.networkmanager.enable = true;

  # IPv6 is not used
  networking.enableIPv6 = false;

  # HTTP and HTTPS, for Traefik. (SSH's port 22 is opened by ssh.nix.)
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
