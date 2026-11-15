# People and automation accounts.
{ pkgs, ... }:

let
  # Authorised to log in as either account below
  adminKeys = import ./admin-keys.nix;
in
{
  programs.fish.enable = true;

  users.users.bedwards = {
    isNormalUser = true;
    description = "Brian Edwards";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = adminKeys;
  };

  # Used by Ansible: key-only login.
  users.users.ansible = {
    isNormalUser = true;
    description = "Ansible automation";
    # POSIX login shell: SSH runs Ansible's commands through it, and fish parses them differently.
    # No docker group: passwordless sudo already grants root.
    shell = pkgs.bashInteractive;
    openssh.authorizedKeys.keys = adminKeys;
  };

  # bedwards is key-only (no password), so sudo needs NOPASSWD to be usable.
  security.sudo.extraRules = [
    {
      users = [
        "ansible"
        "bedwards"
      ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
