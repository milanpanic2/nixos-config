{ config, pkgs, ... }:

{
  # X11  
  services.xserver.enable = true;

  # Wayland
  services.displayManager.gdm = {
    enable = true;
    wayland = true;
  };
  # environment.variables = {                                                                                               
  #   GDM_DEVICE = "/dev/dri/renderD129";  # AMD RX 9070                                                                    
  # };
  services.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = "mpanic";
  };

  environment.systemPackages = with pkgs; [
    adwaita-icon-theme # GNOME default cursos and icons
  ];

  fonts.fontconfig = {
    enable = true;
    antialias = true;
    hinting.enable = true;
    hinting.style = "slight";
    subpixel.rgba = "rgb";
    subpixel.lcdfilter = "default";
  };
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
    liberation_ttf
    jetbrains-mono
    inter
  ];

  systemd.sleep.settings.Sleep = {
    AllowSuspend = "no";
    AllowHibernation = "no";
    AllowSuspendThenHibernate = "no";
    AllowHybridSleep = "no";
  };

  environment.sessionVariables = {                                                                                   
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";                                                                        
    NIXOS_OZONE_WL = "1";                                                                                            
    QT_QPA_PLATFORM = "wayland";                                                                                     
  };

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;

    #media-session.enable = true;
  };

  programs.firefox.enable = true;

  services.printing.enable = true;
}
