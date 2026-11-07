# WireGuard server for the private network (10.9.1.0/24); the services' Docker
# network (10.9.0.0/24, bridge br-vpn) is reached through it.
{ lib, pkgs, ... }:

let
  port = 51820;

  # Public keys live in ../keys; the private keys never enter this directory.
  # To add a device: put <name>.pub in ../keys, give it its own address here, rebuild.
  publicKey = name: lib.removeSuffix "\n" (builtins.readFile ../keys/${name}.pub);

  peers = [
    {
      publicKey = publicKey "udm";
      allowedIPs = [ "10.9.1.2/32" ];
    }
    {
      publicKey = publicKey "laptop";
      allowedIPs = [ "10.9.1.3/32" ];
    }
  ];
in
{
  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.9.1.1/24" ];
    listenPort = port;
    # created on the server at first start, never in the repo.
    # Its public key: wg pubkey < /etc/wireguard/wg0.key
    privateKeyFile = "/etc/wireguard/wg0.key";
    generatePrivateKeyFile = true;
    inherit peers;
  };

  networking.firewall.allowedUDPPorts = [ port ];

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  # The Ansible `vpn` Docker network turns off Docker's own filtering
  # (gateway_mode_ipv4 nat-unprotected), so this is the only rule keeping other
  # hosts out of br-vpn. DOCKER-USER is the chain Docker never rewrites; it
  # exists only once Docker is up, so this runs after it.
  systemd.services.vpn-forward-rules = {
    description = "Let only wg0 reach the Docker vpn network";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.iptables ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      iptables -N VPN-FORWARD 2>/dev/null || iptables -F VPN-FORWARD
      iptables -A VPN-FORWARD -i wg0 -j ACCEPT
      iptables -A VPN-FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
      iptables -A VPN-FORWARD ! -i br-vpn -j DROP
      iptables -A VPN-FORWARD -j RETURN

      # traffic into br-vpn from br-vpn itself (container to container) is not judged
      iptables -C DOCKER-USER -o br-vpn -j VPN-FORWARD 2>/dev/null \
        || iptables -I DOCKER-USER -o br-vpn -j VPN-FORWARD

      # A container on two networks (Traefik) has its default route on the other one, so
      # without this its replies to a peer would leave by the wrong interface and be lost.
      # It makes peers appear as 10.9.0.1 to the containers.
      iptables -t nat -C POSTROUTING -s 10.9.1.0/24 -o br-vpn -j MASQUERADE 2>/dev/null \
        || iptables -t nat -A POSTROUTING -s 10.9.1.0/24 -o br-vpn -j MASQUERADE
    '';
    preStop = ''
      iptables -D DOCKER-USER -o br-vpn -j VPN-FORWARD 2>/dev/null || true
      iptables -t nat -D POSTROUTING -s 10.9.1.0/24 -o br-vpn -j MASQUERADE 2>/dev/null || true
      iptables -F VPN-FORWARD 2>/dev/null || true
      iptables -X VPN-FORWARD 2>/dev/null || true
    '';
  };
}
