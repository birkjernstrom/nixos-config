{ config, lib, pkgs, theme, ... }:

with lib; let
  cfg = config.userSettings.wofi;
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
        prompt = "Search...";
        filter_rate = 100;
        allow_markup = true;
        no_actions = true;
        halign = "fill";
        orientation = "vertical";
        content_halign = "fill";
        insensitive = true;
        allow_images = true;
        image_size = 32;
        gtk_dark = true;
        dynamic_lines = true;
      };

      # Styling with theme colors
      style = ''
        /* Theme colors from base16 */
        ${theme.css}

        * {
          font-family: "JetBrainsMono Nerd Font Mono", monospace;
          font-size: 14px;
        }

        window {
          background-color: @bg;
          border: 2px solid @purple;
          border-radius: 12px;
        }

        #input {
          margin: 12px;
          padding: 12px 16px;
          border: none;
          border-radius: 8px;
          background-color: @bg-selection;
          color: @fg;
        }

        #input:focus {
          border: 2px solid @purple;
          outline: none;
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

        #text {
          color: @fg;
        }

        #entry {
          padding: 10px 16px;
          margin: 4px 0;
          border-radius: 8px;
          background-color: transparent;
        }

        #entry:selected {
          background-color: @bg-selection;
          border: none;
        }

        #entry:selected #text {
          color: @purple;
        }

        #entry:hover {
          background-color: @bg-subtle;
        }

        #text:selected {
          color: @purple;
        }
      '';
    };
  };
}
