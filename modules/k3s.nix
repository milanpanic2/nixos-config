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
      "--tls-san 192.168.8.208"
    ];
    containerdConfigTemplate = ''
      {{ template "base" . }}
      [plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.nvidia]
        runtime_type = "io.containerd.runc.v2"
      [plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.nvidia.options]
        BinaryName = "${pkgs.nvidia-container-toolkit.tools}/bin/nvidia-container-runtime.cdi"
    '';
  };

  # ensure containerd config dir exists before tmpfiles creates the template symlink
  systemd.tmpfiles.rules = [
    "d /var/lib/rancher/k3s/agent/etc/containerd 0755 root root -"
  ];

  users.groups.k3s = {};

  environment.sessionVariables = {
    KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
  };

  networking.firewall.allowedTCPPorts = [ 53 6443 ];
  networking.firewall.allowedUDPPorts = [ 8472 ];
  networking.firewall.checkReversePath = "loose";
  networking.firewall.trustedInterfaces = [ "cni0" "flannel.1" ];
}
