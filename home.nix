{ config, pkgs, lib, ... }:

{
  home = {
    username = "mpanic";
    homeDirectory = "/home/mpanic";
    stateVersion = "25.11";
  };

  programs.home-manager.enable = true;

  programs.git = {                       # add this
    enable = true;
    #  userName = "Milan Panic";
    # userEmail = "you@example.com";
  };

  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "Noto Sans" ];
    monospace = [ "Noto Sans Mono" ];
  };
                                                                                                              
  gtk = {         
    enable = true;
  };

  # GNOME settings via dconf
  dconf.settings = {
    "org/gnome/mutter" = {
      experimental-features = [
        "scale-monitor-framebuffer"
      ];
    };

    "org/gnome/desktop/interface" = {
      font-name = "Noto Sans 12";
      monospace-font-name = "Noto Sans Mono 12";
      document-font-name = "Noto Sans 12";
      font-antialiasing = "rgba";
      font-hinting = "slight";
      # text-scaling-factor = 1.14; # if using amdgpu.virtual_display no DPI info
    };

    "org/gnome/desktop/session" = {
      idle-delay = lib.hm.gvariant.mkUint32 0;
    };

    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
    };

    "org/gnome/desktop/screensaver" = {
      lock-enabled = false;
    };
  };


  home.packages = with pkgs; [ code-server ];

  systemd.user.startServices = "sd-switch";

  systemd.user.services.code-server = {
    Unit.Description = "code-server";
    Install.WantedBy = [ "default.target" ];
    Service = {
      ExecStartPre = "${pkgs.code-server}/bin/code-server --install-extension pkief.material-icon-theme";
      ExecStart = "${pkgs.code-server}/bin/code-server --bind-addr 0.0.0.0:8079 --auth password --user-data-dir /home/mpanic/.config/VSCodium";
      Restart = "on-failure";
      Environment = [
        "HELM_PLUGINS=${pkgs.kubernetes-helmPlugins.helm-diff}"
        "KUBECONFIG=/etc/rancher/k3s/k3s.yaml"
      ];
    };
  };

  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        charliermarsh.ruff
        jnoortheen.nix-ide
        redhat.vscode-yaml
        timonwong.shellcheck
        llvm-vs-code-extensions.vscode-clangd
        ms-python.python
        ms-pyright.pyright
        ms-python.debugpy
        ms-toolsai.jupyter
        ms-toolsai.jupyter-renderers
        ms-toolsai.jupyter-keymap
        ms-kubernetes-tools.vscode-kubernetes-tools
        tim-koehler.helm-intellisense
        zainchen.json
        pkief.material-icon-theme
      ];
      userSettings = {
        "telemetry.telemetryLevel"                   = "off";
        "editor.fontFamily"                          = "Noto Sans Mono";
        "editor.fontSize"                            = 16;
        "terminal.integrated.fontFamily"             = "Noto Sans Mono";
        "nix.enableLanguageServer"                   = true;
        "nix.serverPath"                             = "nil";
        "redhat.telemetry.enabled"                   = false;
        "gitlens.telemetry.enabled"                  = false;
        "workbench.colorTheme"                       = "Default Dark Modern";
        "workbench.iconTheme"                        = "material-icon-theme";
        "editor.overtype"                            = false;
        "python.analysis.typeCheckingMode"            = "basic";
        "python.analysis.diagnosticSeverityOverrides" = {
          "reportOptionalMemberAccess"                = "warning";
        };
        "python.languageServer"                      = "None";
        "python.analysis.autoImportCompletions"       = true;
        "python.analysis.diagnosticMode"              = "workspace";
        "python.analysis.autoSearchPaths"             = true;
        "python.analysis.useLibraryCodeForTypes"      = true;
        "editor.formatOnPaste"                       = true;
        "editor.formatOnType"                        = true;
        "editor.suggest.localityBonus"               = true;
        "editor.suggest.showStatusBar"               = true;
        "editor.suggest.preview"                     = true;
        "editor.suggestSelection"                    = "recentlyUsedByPrefix";
        "pyright.completeFunctionParens"              = true;
        "workbench.editor.wrapTabs"                  = true;
        "workbench.editor.tabSizing"                 = "fit";
        "workbench.editor.limit.enabled"             = true;
        "workbench.editor.limit.value"               = 10;
        "workbench.editor.limit.perEditorGroup"      = true;
        "workbench.editor.limit.excludeDirty"        = true;
        "yaml.schemas" = {
          "kubernetes"                               = "manifests/**/*.yaml";
        };
        "[yaml]" = {
          "editor.defaultFormatter"                  = "redhat.vscode-yaml";
        };
        "[python]" = {
          "editor.defaultFormatter"                  = "charliermarsh.ruff";
          "editor.codeActionsOnSave" = {
            "source.organizeImports.ruff"            = "explicit";
          };
        };
      };
    };
  };
}
