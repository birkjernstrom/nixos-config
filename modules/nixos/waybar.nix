{ config, lib, pkgs, ... }:

with lib; let
  cfg = config.userSettings.waybar;
in
{
  options.userSettings.waybar.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable waybar status bar with Catppuccin styling";
  };

  config = mkIf cfg.enable {
    programs.waybar = {
      enable = true;

      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 36;
          spacing = 8;

          modules-left = [
            "hyprland/workspaces"
            "hyprland/window"
          ];

          modules-center = [
            "clock"
          ];

          modules-right = [
            "cpu"
            "memory"
            "pulseaudio"
            "network"
            "battery"
            "tray"
          ];

          "hyprland/workspaces" = {
            format = "{icon}";
            format-icons = {
              "1" = "1";
              "2" = "2";
              "3" = "3";
              "4" = "4";
              "5" = "5";
              "6" = "6";
              "7" = "7";
              "8" = "8";
              "9" = "9";
              "10" = "0";
            };
            persistent-workspaces = {
              "*" = 5;
            };
          };

          "hyprland/window" = {
            max-length = 50;
            separate-outputs = true;
          };

          clock = {
            format = "{:%H:%M}";
            format-alt = "{:%A, %B %d, %Y (%R)}";
            tooltip-format = "<tt><small>{calendar}</small></tt>";
            calendar = {
              mode = "year";
              mode-mon-col = 3;
              weeks-pos = "right";
              on-scroll = 1;
              format = {
                months = "<span color='#f5e0dc'><b>{}</b></span>";
                days = "<span color='#cdd6f4'>{}</span>";
                weeks = "<span color='#94e2d5'><b>W{}</b></span>";
                weekdays = "<span color='#f9e2af'><b>{}</b></span>";
                today = "<span color='#f38ba8'><b><u>{}</u></b></span>";
              };
            };
          };

          cpu = {
            format = " {usage}%";
            tooltip = true;
            interval = 2;
          };

          memory = {
            format = " {}%";
            interval = 2;
          };

          pulseaudio = {
            format = "{icon} {volume}%";
            format-muted = " muted";
            format-icons = {
              headphone = "";
              headset = "";
              default = ["" "" ""];
            };
            on-click = "pavucontrol";
          };

          network = {
            format-wifi = " {signalStrength}%";
            format-ethernet = " connected";
            format-disconnected = "󰤭 disconnected";
            tooltip-format = "{ifname}: {ipaddr}/{cidr}";
            on-click = "nm-connection-editor";
          };

          battery = {
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{icon} {capacity}%";
            format-charging = " {capacity}%";
            format-plugged = " {capacity}%";
            format-icons = ["" "" "" "" ""];
          };

          tray = {
            icon-size = 18;
            spacing = 10;
          };
        };
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
          font-size: 13px;
          min-height: 0;
        }

        window#waybar {
          background: alpha(@base, 0.9);
          border-bottom: 2px solid @surface0;
          color: @text;
        }

        tooltip {
          background: @base;
          border: 1px solid @mauve;
          border-radius: 8px;
        }

        tooltip label {
          color: @text;
        }

        #workspaces {
          margin-left: 8px;
        }

        #workspaces button {
          padding: 0 8px;
          margin: 4px 2px;
          border-radius: 6px;
          background: transparent;
          color: @overlay1;
          transition: all 0.2s ease;
        }

        #workspaces button:hover {
          background: @surface0;
          color: @text;
        }

        #workspaces button.active {
          background: @mauve;
          color: @base;
        }

        #workspaces button.urgent {
          background: @red;
          color: @base;
        }

        #window {
          padding: 0 12px;
          color: @subtext1;
        }

        #clock {
          padding: 0 16px;
          color: @mauve;
          font-weight: bold;
        }

        #cpu,
        #memory,
        #pulseaudio,
        #network,
        #battery,
        #tray {
          padding: 0 12px;
          margin: 4px 2px;
          border-radius: 6px;
          background: @surface0;
          color: @text;
        }

        #cpu {
          color: @blue;
        }

        #memory {
          color: @peach;
        }

        #pulseaudio {
          color: @mauve;
        }

        #pulseaudio.muted {
          background: @surface1;
          color: @overlay0;
        }

        #network {
          color: @teal;
        }

        #network.disconnected {
          background: @surface1;
          color: @overlay0;
        }

        #battery {
          color: @green;
        }

        #battery.charging {
          color: @green;
          animation: pulse 2s infinite;
        }

        #battery.warning:not(.charging) {
          background: @yellow;
          color: @base;
        }

        #battery.critical:not(.charging) {
          background: @red;
          color: @base;
          animation: pulse 1s infinite;
        }

        @keyframes pulse {
          0% { opacity: 1; }
          50% { opacity: 0.6; }
          100% { opacity: 1; }
        }

        #tray {
          margin-right: 8px;
        }

        #tray > .passive {
          -gtk-icon-effect: dim;
        }

        #tray > .needs-attention {
          -gtk-icon-effect: highlight;
          background: @red;
        }
      '';
    };
  };
}
