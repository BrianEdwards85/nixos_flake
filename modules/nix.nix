# The Nix package manager itself.
{ ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Free old generations between the monthly rebuilds. 45 days keeps a rollback target
  # for at least a full monthly cycle.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 45d";
  };

  nixpkgs.config.allowUnfree = true;
}
