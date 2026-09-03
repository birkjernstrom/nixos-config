{ config, lib, pkgs, ... }:

with lib; let
  cfg = config.userSettings.wofi;

  # Wofi's stylesheet has no colour variables, so the few accents the layout
  # needs are read back from Stylix rather than restated.
  colors = config.lib.stylix.colors.withHashtag;
in
{
  options.userSettings.wofi.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable wofi application launcher";
  };

  config = mkIf cfg.enable {
    programs.wofi = {
      enable = true;

      settings = {
        width = 600;
        height = 400;
        location = "center";
        show = "drun";
        prompt = "";
        filter_rate = 100;
        allow_markup = true;
        no_actions = true;
        halign = "fill";
        show_all = false;
        hide_scroll = true;
        orientation = "vertical";
        term = "ghostty";
        content_halign = "fill";
        insensitive = true;
        allow_images = false;
        gtk_dark = true;
        dynamic_lines = false;
      };

      # Layout only - background, foreground, input and entry colours all
      # come from Stylix's wofi target.
      style = ''
        window {
          border: 1px solid ${colors.base0E};
          border-radius: 4px;
        }

        #input {
          margin: 12px;
          padding: 12px 16px;
          border-radius: 8px;
        }

        #inner-box {
          margin: 0 12px 12px 12px;
          background-color: transparent;
        }

        #outer-box {
          margin: 0;
          padding: 0;
          background-color: transparent;
        }

        #scroll {
          margin: 0;
          padding: 0;
        }

        #entry {
          padding: 10px 16px;
          margin: 4px 0;
          border-radius: 8px;
        }
      '';
    };
  };
}
