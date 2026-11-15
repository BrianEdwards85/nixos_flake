# A microVM for a terminal sandbox, on wintermute only (listed for it in flake.nix).
#
#   - the user's home-manager configuration (user-hm) provides the packages and dotfiles
#   - SSH on the host's port 2222, and zellij's web client on the proxy network's gateway, port 9999
#     (Traefik serves it as term.<domain> behind the login gate: roles/term in the Ansible repository)
#   - /home is a 20 GB volume; the host's /home/bedwards/workspace is shared in as ~/workspace
#   - the host's Nix store is shared read-only: nothing is installed inside the VM
{ inputs, lib, ... }:

let
  # The uid bedwards has on this host. The shared workspace keeps its host ownership inside the VM,
  # so the VM's bedwards must have the same uid and gid. Check with `id bedwards`; the term role
  # in the Ansible repository checks it too (term_user_uid).
  bedwardsUid = 1001;
  bedwardsGid = 100;

  adminKeys = import ./admin-keys.nix;
  # the packages and dotfiles of this home-manager configuration, as built for the VM's user
  hm = inputs.user-hm.homeConfigurations.wintermute;

  zellijPort = 8082;
  webPort = 9999;
in
{
  imports = [ inputs.microvm.nixosModules.host ];

  # each VM's files are in /srv/microvm/<name>/
  microvm.stateDir = "/srv/microvm";

  # The workspace is the user's directory on the host, bound under the VM's directory
  fileSystems."/srv/microvm/term/workspace" = {
    device = "/home/bedwards/workspace";
    fsType = "none";
    options = [
      "bind"
      "x-mount.mkdir"
    ];
  };
  system.activationScripts.termWorkspace = {
    deps = [ "users" ];
    text = ''
      install -d -o bedwards -g users -m 0755 /home/bedwards/workspace
    '';
  };

  # the VM's web port is published on the proxy network's gateway, which exists once Docker has made that network
  systemd.services."microvm@term" = {
    after = [ "docker.service" ];
    serviceConfig = {
      Restart = lib.mkForce "on-failure";
      RestartSec = 15;
    };
  };

  microvm.vms.term = {
    config =
      { pkgs, ... }:
      {
        imports = [ inputs.microvm.nixosModules.microvm ];

        networking.hostName = "term";
        # Set once. Do NOT change it afterwards.
        system.stateVersion = "26.05";

        microvm = {
          hypervisor = "qemu";
          vcpu = 4;
          mem = 4096;

          # QEMU's own network stack: the VM reaches the internet through the host, and only the
          # forwarded ports reach the VM. No bridge, NAT or firewall rules on the host.
          interfaces = [
            {
              type = "user";
              id = "term";
              mac = "02:00:00:00:00:02";
            }
          ];
          forwardPorts = [
            {
              from = "host";
              host.port = 2222;
              guest.port = 22;
            }
            {
              from = "host";
              host.address = "172.18.0.1";
              host.port = webPort;
              guest.port = webPort;
            }
          ];

          shares = [
            {
              proto = "virtiofs";
              tag = "ro-store";
              source = "/nix/store";
              mountPoint = "/nix/.ro-store";
            }
            {
              proto = "virtiofs";
              tag = "workspace";
              source = "/srv/microvm/term/workspace";
              mountPoint = "/workspace";
            }
          ];
          volumes = [
            {
              image = "home.img";
              mountPoint = "/home";
              size = 20 * 1024;
            }
          ];
        };

        networking.useNetworkd = true;
        systemd.network.networks."10-uplink" = {
          matchConfig.Type = "ether";
          networkConfig.DHCP = "yes";
        };
        networking.firewall.allowedTCPPorts = [
          22
          webPort
        ];

        programs.fish.enable = true;
        users.users.bedwards = {
          isNormalUser = true;
          uid = bedwardsUid;
          description = "Brian Edwards";
          shell = pkgs.fish;
          extraGroups = [ "wheel" ];
          openssh.authorizedKeys.keys = adminKeys;
          # the programs of the home-manager configuration
          packages = [ hm.config.home.path ];
        };
        users.groups.users.gid = bedwardsGid;
        # a throwaway sandbox: the key is the only way in, and root in it is one command away
        security.sudo.wheelNeedsPassword = false;

        services.openssh = {
          enable = true;
          # on the persistent volume, so the host key survives a rebuilt VM
          hostKeys = [
            {
              path = "/home/.ssh-host/ssh_host_ed25519_key";
              type = "ed25519";
            }
          ];
          settings = {
            PasswordAuthentication = false;
            KbdInteractiveAuthentication = false;
            PermitRootLogin = "no";
          };
        };

        # /home is a volume mounted after the system's own set-up, so its directories are made here
        systemd.tmpfiles.rules = [
          "d /home/.ssh-host 0700 root root -"
          "d /home/bedwards 0700 bedwards users -"
          "L /home/bedwards/workspace - - - - /workspace"
        ];

        # the dotfiles of the home-manager configuration, linked into the home directory at every boot
        # (activating it would need a writable Nix store, which the VM does not have)
        systemd.services.home-files = {
          description = "Link the home-manager dotfiles into the home directory";
          wantedBy = [ "multi-user.target" ];
          after = [ "systemd-tmpfiles-setup.service" ];
          before = [ "zellij-web.service" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            User = "bedwards";
          };
          script = ''
            ${pkgs.coreutils}/bin/cp -rsfT ${hm.activationPackage}/home-files /home/bedwards
          '';
        };

        # zellij serves its web client on loopback only (anywhere else it insists on TLS), so socat
        # republishes it on the VM's address. Zellij has its own login: zellij web --create-token
        systemd.services.zellij-web = {
          description = "Zellij web client";
          wantedBy = [ "multi-user.target" ];
          after = [ "home-files.service" ];
          serviceConfig = {
            User = "bedwards";
            Environment = [ "HOME=/home/bedwards" ];
            ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /home/bedwards/.config/zellij /home/bedwards/.local/share/zellij";
            ExecStart = "${pkgs.zellij}/bin/zellij web --start --ip 127.0.0.1 --port ${toString zellijPort}";
            Restart = "always";
          };
        };
        systemd.services.zellij-web-expose = {
          description = "Publish zellij's web client on the VM's address";
          wantedBy = [ "multi-user.target" ];
          after = [ "zellij-web.service" ];
          serviceConfig = {
            ExecStart = "${pkgs.socat}/bin/socat TCP4-LISTEN:${toString webPort},reuseaddr,fork,bind=0.0.0.0 TCP4:127.0.0.1:${toString zellijPort}";
            Restart = "always";
          };
        };
      };
  };
}
