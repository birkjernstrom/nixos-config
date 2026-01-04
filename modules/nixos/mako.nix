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

      # Colors from theme
      backgroundColor = lib.mkForce "#${colors.base00}";
      textColor = "#${colors.base05}";
      borderColor = lib.mkForce "#${colors.base0E}";
      progressColor = "over #${colors.base02}";

      # Layout
      width = 350;
      height = 150;
      margin = "10";
      padding = "15";
      borderSize = 2;
      borderRadius = 12;

      # Behavior
      defaultTimeout = 5000;
      ignoreTimeout = false;
      maxVisible = 5;
      layer = "overlay";
      anchor = "top-right";

      # Font
      font = lib.mkForce "BerkleyMono Nerd Font";

      # Icons
      icons = true;
      maxIconSize = 48;

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
