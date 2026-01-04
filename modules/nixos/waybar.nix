{ config, lib, pkgs, theme, ... }:

with lib; let
  cfg = config.userSettings.waybar;
  colors = theme.base16;
in
{
  options.userSettings.waybar.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable waybar status bar";
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
                months = "<span color='#${colors.base06}'><b>{}</b></span>";
                days = "<span color='#${colors.base05}'>{}</span>";
                weeks = "<span color='#${colors.base0C}'><b>W{}</b></span>";
                weekdays = "<span color='#${colors.base0A}'><b>{}</b></span>";
                today = "<span color='#${colors.base08}'><b><u>{}</u></b></span>";
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

      # Styling with theme colors
      style = ''
        /* Theme colors from base16 */
        ${theme.css}

        * {
          font-family: "JetBrainsMono Nerd Font Mono", monospace;
          font-size: 13px;
          min-height: 0;
        }

        window#waybar {
          background: alpha(@bg, 0.9);
          border-bottom: 2px solid @bg-selection;
          color: @fg;
        }

        tooltip {
          background: @bg;
          border: 1px solid @purple;
          border-radius: 8px;
        }

        tooltip label {
          color: @fg;
        }

        #workspaces {
          margin-left: 8px;
        }

        #workspaces button {
          padding: 0 8px;
          margin: 4px 2px;
          border-radius: 6px;
          background: transparent;
          color: @fg-dim;
          transition: all 0.2s ease;
        }

        #workspaces button:hover {
          background: @bg-selection;
          color: @fg;
        }

        #workspaces button.active {
          background: @purple;
          color: @bg;
        }

        #workspaces button.urgent {
          background: @red;
          color: @bg;
        }

        #window {
          padding: 0 12px;
          color: @fg-dim;
        }

        #clock {
          padding: 0 16px;
          color: @purple;
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
          background: @bg-selection;
          color: @fg;
        }

        #cpu {
          color: @blue;
        }

        #memory {
          color: @orange;
        }

        #pulseaudio {
          color: @purple;
        }

        #pulseaudio.muted {
          background: @bg-subtle;
          color: @fg-dim;
        }

        #network {
          color: @cyan;
        }

        #network.disconnected {
          background: @bg-subtle;
          color: @fg-dim;
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
          color: @bg;
        }

        #battery.critical:not(.charging) {
          background: @red;
          color: @bg;
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
