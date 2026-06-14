{ config, pkgs, ... }:

{
  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman";

  systemd.tmpfiles.rules = [
    "d /var/lib/pihole 0755 root root -"
  ];

  virtualisation.oci-containers.containers.pihole = {
    image = "pihole/pihole:latest";
    ports = [
      "53:53/tcp"   # DNS over TCP (used for large responses)
      "53:53/udp"   # DNS over UDP (standard DNS queries)
      "8053:80/tcp" # Pi-hole web UI (format: localPort:containerPort)
    ];
    environment = {
      TZ = "Europe/Sofia";
      FTLCONF_webserver_api_password = "admin";
      PIHOLE_DNS_1 = "1.1.1.1";  # Cloudflare
      PIHOLE_DNS_2 = "1.0.0.1";  # Cloudflare secondary fallback
      FTLCONF_dns_listeningMode = "all"; # Accept queries from non-local networks (e.g. router)
      # Wildcard DNS: resolve *.homelab.com to Kong's MetalLB IP
      FTLCONF_misc_dnsmasq_lines = "address=/homelab.com/192.168.8.10";
    };
    volumes = [
      "/var/lib/pihole:/etc/pihole"
    ];
    extraOptions = [
      "--cap-add=SYS_TIME"  # Allow container to sync system clock
      "--cap-add=SYS_NICE"  # Allow container to set process priority
    ];
  };

  networking.firewall.allowedTCPPorts = [ 53 8053 ];
  networking.firewall.allowedUDPPorts = [ 53 ];

  networking.nameservers = [ "127.0.0.1" ]; # so this machine uses pihole for dns
}
