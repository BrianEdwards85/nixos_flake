# Settings for this server only. Shared settings live in ../../modules.
# The home server. Its DNS names are under free-side.us; the system's own
# hostname is wintermute.
{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    inputs.disko.nixosModules.disko
    ./disko.nix
    ./hardware-configuration.nix
  ];

  # UEFI, so the shared systemd-boot (modules/boot.nix) is used as is.

  # Pin the NIC's name to its MAC so the config below does not depend on
  # predictable interface names.
  services.udev.extraRules = ''
    SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="f8:b1:56:ba:64:77", NAME="lan0"
  '';

  # Two static addresses, no DHCP, and no NetworkManager: nothing here needs
  # it, and it can rewrite the DNS settings. users.nix still names its group.
  networking.networkmanager.enable = lib.mkForce false;
  users.groups.networkmanager = { };
  networking.useDHCP = false;

  # lan0 carries the untagged LAN (192.168.128.0/23). VLAN 98 is tagged on the
  # same cable and appears as vlan98 (192.168.98.0/23).
  networking.vlans.vlan98 = {
    id = 98;
    interface = "lan0";
  };
  networking.interfaces.lan0.ipv4.addresses = [
    {
      address = "192.168.128.2";
      prefixLength = 23;
    }
  ];
  networking.interfaces.vlan98.ipv4.addresses = [
    {
      address = "192.168.98.2";
      prefixLength = 23;
    }
  ];

  # One default route only: the untagged LAN's gateway. The VLAN gets just its
  # own subnet's route.
  networking.defaultGateway = {
    address = "192.168.128.1";
    interface = "lan0";
  };
  networking.nameservers = [
    "192.168.128.1"
    "192.168.98.1"
  ];

  # Replies to traffic that arrived on vlan98 must leave by vlan98, or the
  # router (which tracks connections per interface) drops them. Anything sent
  # from 192.168.98.2 therefore uses its own routing table, whose default route
  # is the VLAN's gateway. Traffic from 192.168.128.2 is unaffected.
  # A service of its own, not networking.localCommands: that script also writes
  # the DNS servers, and stops at the first failing command.
  systemd.services.vlan98-policy-routing = {
    description = "Route replies from the VLAN 98 address out of vlan98";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-addresses-vlan98.service" ];
    wants = [ "network-addresses-vlan98.service" ];
    path = [ pkgs.iproute2 ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ip route replace default via 192.168.98.1 dev vlan98 onlink table 98
      ip rule del from 192.168.98.2 lookup 98 2>/dev/null || true
      ip rule add from 192.168.98.2 lookup 98
    '';
    preStop = ''
      ip rule del from 192.168.98.2 lookup 98 2>/dev/null || true
      ip route flush table 98 2>/dev/null || true
    '';
  };

  # Matter needs IPv6 (link-local multicast and neighbor discovery), so override
  # the shared module, which turns it off. Addresses come from router
  # advertisements. Do not enable IPv6 forwarding: it must stay off for Matter.
  networking.enableIPv6 = lib.mkForce true;

  # Linux forgets an idle UDP flow after 120 s. Battery-powered Matter devices
  # report every few minutes, and those reports would be dropped. The setting
  # exists only while the conntrack module is loaded, so load it explicitly.
  boot.kernelModules = [ "nf_conntrack" ];
  boot.kernel.sysctl."net.netfilter.nf_conntrack_udp_timeout_stream" = 3600;

  # The Matter server runs as uid/gid 1000 and pings devices to check they are
  # reachable; unprivileged ping is off by default.
  boot.kernel.sysctl."net.ipv4.ping_group_range" = "0 2147483647";

  # The host firewall is off for now, so Home Assistant and matter-server (host
  # network) are reachable on every port. TODO: turn it on again once the ports
  # are known, filtering Matter UDP by interface and never by port.
  networking.firewall.enable = false;

  # TEMPORARY: a console login for the first boot, in case the network does not
  # come up. Applies only when the user is first created. TODO: remove after
  # the first successful SSH login, then rebuild.
  users.users.bedwards.initialHashedPassword = "$y$j9T$.2t09nJNATU2KuGt8U7e4/$D.ERXCTf9nZnm4i9mEyWDbU70eC1K.RUwh3iUZL6L89";

  # Set once at install. Do NOT change it afterwards.
  system.stateVersion = "26.05";
}
