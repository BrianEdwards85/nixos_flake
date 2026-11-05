# Everything every server gets. Each file below covers one topic;
# read the one you want to change.
{ ... }:

{
  imports = [
    ./boot.nix
    ./nix.nix
    ./locale.nix
    ./networking.nix
    ./ssh.nix
    ./users.nix
    ./packages.nix
    ./docker.nix
  ];
}
