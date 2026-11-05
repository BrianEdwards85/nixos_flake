# Settings for this server only. Shared settings live in ../../modules.
{ ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Set once at install. Do NOT change it afterwards.
  system.stateVersion = "26.05";
}
