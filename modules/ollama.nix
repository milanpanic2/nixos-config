{ config, pkgs, ... }:

{
  services.ollama = {
    enable = true;
    host = "0.0.0.0";
    acceleration = "cuda";
  };

  networking.firewall.allowedTCPPorts = [ 11434 ];
}
