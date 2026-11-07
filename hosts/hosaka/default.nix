# Settings for this server only. Shared settings live in ../../modules.
# Reached at hosaka.io (DNS only; the system's own hostname is just "hosaka").
{
  inputs,
  lib,
  ...
}:

{
  imports = [
    inputs.disko.nixosModules.disko
    ./disko.nix
    ./hardware-configuration.nix
  ];

  # Legacy BIOS VM: replace the shared systemd-boot (UEFI only) with GRUB.
  # disko points GRUB at the disk that holds the EF02 partition.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  boot.loader.grub.enable = true;

  # Pin the NIC's name to its MAC so the config below survives a kernel/udev
  # change in predictable interface names (it was enp3s0 on the old OS).
  services.udev.extraRules = ''
    SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="52:54:80:22:e6:a1", NAME="wan0"
  '';

  # The provider assigns a static address (no DHCP). NetworkManager stays
  # enabled (users.nix uses its group) but leaves this interface alone.
  networking.networkmanager.unmanaged = [ "mac:52:54:80:22:e6:a1" ];
  networking.useDHCP = false;
  networking.interfaces.wan0.ipv4.addresses = [
    {
      address = "198.105.178.188";
      prefixLength = 24;
    }
  ];
  networking.defaultGateway = "198.105.178.1";
  networking.nameservers = [
    "1.1.1.1"
    "9.9.9.9"
  ];

  # Set once at install. Do NOT change it afterwards.
  system.stateVersion = "26.05";
}
