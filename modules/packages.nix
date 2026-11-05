# Programs installed for all users.
{ pkgs, inputs, ... }:

{
  environment.systemPackages = with pkgs; [
    git
    inputs.home-manager.packages.${pkgs.stdenv.hostPlatform.system}.default
    python3
    rsync
    vim
    wget
    fish
  ];
}
