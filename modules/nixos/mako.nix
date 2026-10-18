{ config, lib, pkgs, ... }:

with lib; let
  cfg = config.userSettings.mako;
in
{
  options.userSettings.mako.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Mako notification daemon";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.libnotify ];

    # Colours, font and the per-urgency borders come from Stylix. Only layout
    # and behaviour are configured here.
    services.mako = {
      enable = true;

      settings = {
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

        # Critical notifications stay until dismissed
        "urgency=critical".default-timeout = 0;

        # Toggled from the bar and Pathway (quickshell/Common/DoNotDisturb.qml).
        # Hidden notifications stay in history; critical ones still show.
        "mode=do-not-disturb".invisible = 1;
        "mode=do-not-disturb urgency=critical".invisible = 0;

        # Icons
        icons = true;
        max-icon-size = 48;
      };
    };
  };
}
