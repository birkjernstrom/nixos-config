{ config, lib, pkgs, ... }:

with lib; let
  cfg = config.userSettings.mako;
in
{
  options.userSettings.mako.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Mako notification daemon with Catppuccin styling";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.libnotify ];

    services.mako = {
      enable = true;

      # Catppuccin Mocha colors
      backgroundColor = lib.mkForce "#1e1e2e";
      textColor = "#cdd6f4";
      borderColor = lib.mkForce "#cba6f7";
      progressColor = "over #313244";

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
        border-color=#a6e3a1

        [urgency=normal]
        border-color=#cba6f7

        [urgency=critical]
        border-color=#f38ba8
        default-timeout=0
      '';
    };
  };
}
