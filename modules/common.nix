# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, inputs, ... }:

{
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # networking.hostName is set per host by flake.nix
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."bedwards" = {
    isNormalUser = true;
    description = "Brian Edwards";
    extraGroups = [ "networkmanager" "wheel" "docker"];
    shell = pkgs.fish;
    packages = with pkgs; [];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC+HMVk2PGXbQjq8TgC55QQtzFTgP/sy8SjtWMIrPfg8HLUHXNWh+7homZhQrtNq+f+SeNXfYCHitONrXh4yQOPtFEkmLkkn9RhU2yg52ilJV9hmvnGUg35gUReHabgHZEUjON8c6nm524H25wrIQ6uNoQQvptnB8K1w51C5/Z+CQiinx5IrGBAGgDBAvEXWKjfuRShUU9lcQZgA6fsJwRBu1Pox3dJAoFMsgV961QwgMVhJ9YJeBA92zGS1OifknpVnSNsmcQJNuxwKgEiLhietMPj+bjf/JT5W+P1uPHdZg+ZH/GEKhp6hFBgRcKGyGYkT9Q/oCGi7Skvq1sCOx/33RfEC1rMmPvsVoFSBl7TCo4E7B+IMl/9jnR/aNrOZ++otFzgNrFM0ZdzrXRyuU+C7TKk2Z8XRdE7HWdS+iiGWTG+BXLUzpdIb8Ue3eL7U/pJZT36mR90CMf1CB5o2M9bOdS1vZLE5RzflnejGalOicphSXFLyCfUL1A5sJxuF8q209Pu1ruqPM/8X4tFoyNLYhWztXC3onAsSx5b3CB3ZytaSR3MAM6lcqIniHW/nfi3zVrDvgXr/4K1bth72cHbXD3Fe8ZeZ9JKY67CmWpboVsOnBn/icZDGMbh6kTaChTMr9IvuF/6vCox4oOGgEMh83iiJDxC6NgomB41bGroTw=="
    ];
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Automation user for Ansible: key-only SSH login, passwordless sudo.
  users.users.ansible = {
    isNormalUser = true;
    description = "Ansible automation";
    extraGroups = [ "docker"];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC+HMVk2PGXbQjq8TgC55QQtzFTgP/sy8SjtWMIrPfg8HLUHXNWh+7homZhQrtNq+f+SeNXfYCHitONrXh4yQOPtFEkmLkkn9RhU2yg52ilJV9hmvnGUg35gUReHabgHZEUjON8c6nm524H25wrIQ6uNoQQvptnB8K1w51C5/Z+CQiinx5IrGBAGgDBAvEXWKjfuRShUU9lcQZgA6fsJwRBu1Pox3dJAoFMsgV961QwgMVhJ9YJeBA92zGS1OifknpVnSNsmcQJNuxwKgEiLhietMPj+bjf/JT5W+P1uPHdZg+ZH/GEKhp6hFBgRcKGyGYkT9Q/oCGi7Skvq1sCOx/33RfEC1rMmPvsVoFSBl7TCo4E7B+IMl/9jnR/aNrOZ++otFzgNrFM0ZdzrXRyuU+C7TKk2Z8XRdE7HWdS+iiGWTG+BXLUzpdIb8Ue3eL7U/pJZT36mR90CMf1CB5o2M9bOdS1vZLE5RzflnejGalOicphSXFLyCfUL1A5sJxuF8q209Pu1ruqPM/8X4tFoyNLYhWztXC3onAsSx5b3CB3ZytaSR3MAM6lcqIniHW/nfi3zVrDvgXr/4K1bth72cHbXD3Fe8ZeZ9JKY67CmWpboVsOnBn/icZDGMbh6kTaChTMr9IvuF/6vCox4oOGgEMh83iiJDxC6NgomB41bGroTw=="
    ];
  };
  security.sudo.extraRules = [{
    users = [ "ansible" ];
    commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }];
  }];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    git
    inputs.home-manager.packages.${pkgs.stdenv.hostPlatform.system}.default
    python3
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    fish
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
   enable = true;
   openFirewall = true;
      settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  virtualisation.docker.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # system.stateVersion is set per host in hosts/<name>/default.nix

}
