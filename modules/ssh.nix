# Remote login: key-only SSH.
{ ... }:

{
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      # With PAM on, keyboard-interactive can still accept a password
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
}
