{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    kubectl
    kubernetes-helm
    k9s
    kubectx
  ];

  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = toString [
      "--disable traefik"
      "--disable servicelb"  # metallb
      "--write-kubeconfig-mode=644"
      "--write-kubeconfig-group=k3s"
      "--prefer-bundled-bin"
      "--data-dir /home/mpanic/cluster/k3s"
      "--tls-san 192.168.8.208"
    ];
  };

  users.groups.k3s = {};

  environment.sessionVariables = {
    KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
  };

  networking.firewall.allowedTCPPorts = [ 53 6443 ];
  networking.firewall.allowedUDPPorts = [ 8472 ];
  networking.firewall.checkReversePath = "loose";
  networking.firewall.trustedInterfaces = [ "cni0" "flannel.1" ];
}
