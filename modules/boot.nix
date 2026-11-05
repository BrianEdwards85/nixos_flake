# Bootloader.
{ ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Keep the boot partition from filling up with old generations
  boot.loader.systemd-boot.configurationLimit = 10;
}
