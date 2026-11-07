# Settings for this server only. Shared settings live in ../../modules.
{ inputs, ... }:

{
  imports = [
    inputs.disko.nixosModules.disko
    ./disko.nix
    ./hardware-configuration.nix
  ];

  # Boot: UEFI with the shared systemd-boot (modules/boot.nix), assumed.
  # TODO: confirm with `ls /sys/firmware/efi` on the target. If it is missing,
  # the machine is legacy BIOS and this host needs GRUB (see hosts/hosaka).

  # Pin the NIC's name to its MAC so the config below does not depend on
  # predictable interface names.
  # TODO: replace the placeholder MAC (see `ip link` on the target).
  services.udev.extraRules = ''
    SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="00:00:00:00:00:00", NAME="lan0"
  '';

  # Static address on the LAN. NetworkManager stays enabled (users.nix uses its
  # group) but leaves this interface alone.
  networking.networkmanager.unmanaged = [ "mac:00:00:00:00:00:00" ];
  networking.useDHCP = false;
  networking.interfaces.lan0.ipv4.addresses = [
    {
      address = "192.168.128.2";
      # TODO: confirm the prefix length (assumed /24).
      prefixLength = 24;
    }
  ];
  networking.defaultGateway = "192.168.128.1";
  networking.nameservers = [ "192.168.128.1" ];

  # Set once at install. Do NOT change it afterwards.
  system.stateVersion = "26.05";
}
