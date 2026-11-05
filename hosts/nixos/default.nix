{ ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Host-specific settings go here. Do NOT change stateVersion after install.
  system.stateVersion = "26.05";
}
