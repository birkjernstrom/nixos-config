{ config, lib, pkgs, ... }:

with lib; let
  feat = config.features.wofi;
in
{
  options.features.wofi.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable wofi application launcher with Catppuccin styling";
  };

  config = mkIf feat.enable {
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

      # Catppuccin Mocha styling
      style = ''
        /* Catppuccin Mocha Colors */
        @define-color base #1e1e2e;
        @define-color mantle #181825;
        @define-color crust #11111b;
        @define-color surface0 #313244;
        @define-color surface1 #45475a;
        @define-color surface2 #585b70;
        @define-color overlay0 #6c7086;
        @define-color overlay1 #7f849c;
        @define-color overlay2 #9399b2;
        @define-color subtext0 #a6adc8;
        @define-color subtext1 #bac2de;
        @define-color text #cdd6f4;
        @define-color lavender #b4befe;
        @define-color blue #89b4fa;
        @define-color sapphire #74c7ec;
        @define-color sky #89dceb;
        @define-color teal #94e2d5;
        @define-color green #a6e3a1;
        @define-color yellow #f9e2af;
        @define-color peach #fab387;
        @define-color maroon #eba0ac;
        @define-color red #f38ba8;
        @define-color mauve #cba6f7;
        @define-color pink #f5c2e7;
        @define-color flamingo #f2cdcd;
        @define-color rosewater #f5e0dc;

        * {
          font-family: "JetBrainsMono Nerd Font Mono", monospace;
          font-size: 14px;
        }

        window {
          background-color: @base;
          border: 2px solid @mauve;
          border-radius: 12px;
        }

        #input {
          margin: 12px;
          padding: 12px 16px;
          border: none;
          border-radius: 8px;
          background-color: @surface0;
          color: @text;
        }

        #input:focus {
          border: 2px solid @mauve;
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
          color: @text;
        }

        #entry {
          padding: 10px 16px;
          margin: 4px 0;
          border-radius: 8px;
          background-color: transparent;
        }

        #entry:selected {
          background-color: @surface0;
          border: none;
        }

        #entry:selected #text {
          color: @mauve;
        }

        #entry:hover {
          background-color: @surface1;
        }

        #text:selected {
          color: @mauve;
        }
      '';
    };
  };
}
