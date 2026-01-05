{ config, lib, pkgs, theme, ... }:

with lib; let
  cfg = config.userSettings.mako;
  colors = theme.base16;
in
{
  options.userSettings.mako.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Mako notification daemon";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.libnotify ];

    services.mako = {
      enable = true;

      settings  = {
        # Colors from theme
        background-color = lib.mkForce "#${colors.base00}";
        text-color = "#${colors.base05}";
        border-color = lib.mkForce "#${colors.base0E}";
        progress-color = "over #${colors.base02}";

        # Layout
        width = 350;
        height = 150;
        margin = "10";
        padding = "15";
        border-size = 2;
        border-radius = 12;

        # Behavior
        default-timeout = 5000;
        ignore-timeout = false;
        max-visible = 5;
        layer = "overlay";
        anchor = "top-right";

        # Font
        font = lib.mkForce "BerkleyMono Nerd Font";

        # Icons
        icons = true;
        max-icon-size = 48;
      };

      # Extra config for urgency levels
      extraConfig = ''
        [urgency=low]
        border-color=#${colors.base0B}

        [urgency=normal]
        border-color=#${colors.base0E}

        [urgency=critical]
        border-color=#${colors.base08}
        default-timeout=0
      '';
    };
  };
}
