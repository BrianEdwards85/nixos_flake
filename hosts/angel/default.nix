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

  # DHCP on every wired interface, done by the shared NetworkManager (it makes a
  # profile for each wired NIC by itself). This is set explicitly so the generated
  # hardware-configuration.nix, which says `networking.useDHCP = lib.mkDefault true`,
  # cannot start a second DHCP client next to it.
  # The address in the inventory (192.168.128.5) must be a DHCP reservation on the router.
  networking.useDHCP = false;

  # A scrub reads every block and checks it against its checksum, which is how Btrfs
  # finds a failing disk before the data is needed. Monthly, like the other maintenance.
  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ "/" ];
    interval = "monthly";
  };

  # Set once at install. Do NOT change it afterwards.
  system.stateVersion = "26.05";
}
