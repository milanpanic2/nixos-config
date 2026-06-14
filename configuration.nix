
{ config, pkgs, ... }:

{

 # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  imports = [
    ./hardware-configuration.nix                                                                                      
    ./modules/nvidia.nix                                                                                             
    ./modules/sunshine.nix
    ./modules/desktop.nix
    ./modules/k3s.nix                                                                                                
    ./modules/openssh.nix
    ./modules/pihole.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Kernel version
  boot.kernelPackages = pkgs.linuxPackages_6_18;
  system.stateVersion = "25.11"; # NixOS state version

  hardware.enableAllFirmware = true;
  hardware.firmware = with pkgs; [ linux-firmware ];
  
  nixpkgs.config.allowUnfree = true;

  users.users.mpanic = {
    isNormalUser = true;
    description = "Milan Panic";
    extraGroups = [ "networkmanager" "wheel" "input" "video" "render" "uinput" "k3s" ];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
  };

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [ 8079 ];

  environment.systemPackages = with pkgs; [
    wget
    btop

    ghostty

    claude-code

    # LSP / tooling (needed by VSCodium extensions)
    nil             # nix-ide LSP
    nixfmt          # nix formatter
    shellcheck      # shell linting
    clang-tools     # clangd LSP
    python3         # needed by ms-python extension to validate interpreters
    ruff            # Python linter/formatter (used by VSCodium extension)
    pyright         # Python type checker (used by VSCodium extension)
  ];

  programs.git = {
    enable = true;
    config = {
      user.name = "Milan Panic";
      user.email = "pax7748@gmail.com";
    };
  };

  time.timeZone = "Europe/Sofia";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "bg_BG.UTF-8";
    LC_IDENTIFICATION = "bg_BG.UTF-8";
    LC_MEASUREMENT = "bg_BG.UTF-8";
    LC_MONETARY = "bg_BG.UTF-8";
    LC_NAME = "bg_BG.UTF-8";
    LC_NUMERIC = "bg_BG.UTF-8";
    LC_PAPER = "bg_BG.UTF-8";
    LC_TELEPHONE = "bg_BG.UTF-8";
    LC_TIME = "bg_BG.UTF-8";
  };
}
