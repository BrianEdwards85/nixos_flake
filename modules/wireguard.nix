# WireGuard server for the private network (10.9.1.0/24); the services' Docker
# network (10.9.0.0/24, bridge br-vpn) is reached through it.
{ lib, pkgs, ... }:

let
  port = 51820;

  # The interface that reaches the internet (named by MAC in hosts/hosaka).
  externalInterface = "wan0";

  # Public keys live in ../keys; the private keys never enter this directory.
  # To add a device: put <name>.pub in ../keys and list it here with its own address.
  # internet = true lets it use this server as its way out to the internet.
  publicKey = name: lib.removeSuffix "\n" (builtins.readFile ../keys/${name}.pub);

  devices = [
    {
      name = "udm";
      address = "10.9.1.2";
      internet = true;
    }
    {
      name = "laptop";
      address = "10.9.1.3";
      internet = false;
    }
  ];

  peers = map (device: {
    publicKey = publicKey device.name;
    allowedIPs = [ "${device.address}/32" ];
  }) devices;

  internetAddresses = map (device: device.address) (lib.filter (device: device.internet) devices);

  # Addresses that are never reached through the internet exit: this server's provider
  # network and anything else private. (The services on br-vpn are not affected.)
  privateRanges = [
    "10.0.0.0/8"
    "172.16.0.0/12"
    "192.168.0.0/16"
    "169.254.0.0/16"
    "100.64.0.0/10"
    "127.0.0.0/8"
  ];

  forEachInternetPeer = f: lib.concatMapStrings f internetAddresses;
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
  # hosts out of br-vpn. The internet exit rules below live here too. DOCKER-USER is the chain Docker never rewrites; it
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

      # The internet exit: only the devices marked internet, only to public addresses,
      # and the internet cannot start connections back to a peer.
      iptables -N VPN-EXIT 2>/dev/null || iptables -F VPN-EXIT
      ${
        forEachInternetPeer (
          peer:
          lib.concatMapStrings (range: ''
            iptables -A VPN-EXIT -s ${peer} -d ${range} -j DROP
          '') privateRanges
          + ''
            iptables -A VPN-EXIT -s ${peer} -j ACCEPT
          ''
        )
      }iptables -A VPN-EXIT -j DROP
      iptables -C DOCKER-USER -i wg0 -o ${externalInterface} -j VPN-EXIT 2>/dev/null \
        || iptables -I DOCKER-USER -i wg0 -o ${externalInterface} -j VPN-EXIT

      iptables -N VPN-EXIT-REPLY 2>/dev/null || iptables -F VPN-EXIT-REPLY
      iptables -A VPN-EXIT-REPLY -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
      iptables -A VPN-EXIT-REPLY -j DROP
      iptables -C DOCKER-USER -i ${externalInterface} -o wg0 -j VPN-EXIT-REPLY 2>/dev/null \
        || iptables -I DOCKER-USER -i ${externalInterface} -o wg0 -j VPN-EXIT-REPLY

      # peers going out to the internet appear as this server
      ${forEachInternetPeer (peer: ''
        iptables -t nat -C POSTROUTING -s ${peer}/32 -o ${externalInterface} -j MASQUERADE 2>/dev/null \
          || iptables -t nat -A POSTROUTING -s ${peer}/32 -o ${externalInterface} -j MASQUERADE
      '')}
    '';
    preStop = ''
      iptables -D DOCKER-USER -o br-vpn -j VPN-FORWARD 2>/dev/null || true
      iptables -t nat -D POSTROUTING -s 10.9.1.0/24 -o br-vpn -j MASQUERADE 2>/dev/null || true
      iptables -F VPN-FORWARD 2>/dev/null || true
      iptables -X VPN-FORWARD 2>/dev/null || true

      iptables -D DOCKER-USER -i wg0 -o ${externalInterface} -j VPN-EXIT 2>/dev/null || true
      iptables -D DOCKER-USER -i ${externalInterface} -o wg0 -j VPN-EXIT-REPLY 2>/dev/null || true
      ${
        forEachInternetPeer (peer: ''
          iptables -t nat -D POSTROUTING -s ${peer}/32 -o ${externalInterface} -j MASQUERADE 2>/dev/null || true
        '')
      }iptables -F VPN-EXIT 2>/dev/null || true
      iptables -X VPN-EXIT 2>/dev/null || true
      iptables -F VPN-EXIT-REPLY 2>/dev/null || true
      iptables -X VPN-EXIT-REPLY 2>/dev/null || true
    '';
  };
}
