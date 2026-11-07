# People and automation accounts.
{ pkgs, ... }:

let
  # Authorised to log in as either account below
  adminKeys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC+HMVk2PGXbQjq8TgC55QQtzFTgP/sy8SjtWMIrPfg8HLUHXNWh+7homZhQrtNq+f+SeNXfYCHitONrXh4yQOPtFEkmLkkn9RhU2yg52ilJV9hmvnGUg35gUReHabgHZEUjON8c6nm524H25wrIQ6uNoQQvptnB8K1w51C5/Z+CQiinx5IrGBAGgDBAvEXWKjfuRShUU9lcQZgA6fsJwRBu1Pox3dJAoFMsgV961QwgMVhJ9YJeBA92zGS1OifknpVnSNsmcQJNuxwKgEiLhietMPj+bjf/JT5W+P1uPHdZg+ZH/GEKhp6hFBgRcKGyGYkT9Q/oCGi7Skvq1sCOx/33RfEC1rMmPvsVoFSBl7TCo4E7B+IMl/9jnR/aNrOZ++otFzgNrFM0ZdzrXRyuU+C7TKk2Z8XRdE7HWdS+iiGWTG+BXLUzpdIb8Ue3eL7U/pJZT36mR90CMf1CB5o2M9bOdS1vZLE5RzflnejGalOicphSXFLyCfUL1A5sJxuF8q209Pu1ruqPM/8X4tFoyNLYhWztXC3onAsSx5b3CB3ZytaSR3MAM6lcqIniHW/nfi3zVrDvgXr/4K1bth72cHbXD3Fe8ZeZ9JKY67CmWpboVsOnBn/icZDGMbh6kTaChTMr9IvuF/6vCox4oOGgEMh83iiJDxC6NgomB41bGroTw=="
  ];
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
