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
    home.packages = [ pkgs.impala pkgs.bluetuith ];

    programs.waybar = {
      enable = true;

      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 29;
          spacing = 0;

          modules-left = [
            "hyprland/workspaces"
          ];

          modules-center = [
            "clock"
          ];

          modules-right = [
            "hyprland/language"
            "cpu"
            "memory"
            "pulseaudio"
            "bluetooth"
            "network"
            "battery"
          ];

          "hyprland/language" = {
            format = "{}";
            format-en = "US";
            format-sv = "SE";
            on-click = "hyprctl switchxkblayout all next";
          };

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
            format = " {usage}%";
            tooltip = true;
            interval = 2;
            on-click = "ghostty -e btop";
          };

          memory = {
            format = "󰍛 {}%";
            interval = 2;
            on-click = "ghostty -e btop";
          };

          pulseaudio = {
            format = "{icon} {volume}%";
            format-muted = "󰝟 {volume}%";
            format-icons = {
              headphone = "󰋋";
              headset = "󰋎";
              default = ["󰕿" "󰖀" "󰕾"];
            };
            tooltip-format = "{volume}%";
            on-click = "pavucontrol";
          };

          bluetooth = {
            format = "󰂯";
            format-connected = "󰂱 {num_connections}";
            format-disabled = "󰂲";
            format-off = "󰂲";
            tooltip-format = "{controller_alias}\n{status}";
            tooltip-format-connected = "{controller_alias}\n{num_connections} connected\n\n{device_enumerate}";
            tooltip-format-enumerate-connected = "{device_alias}";
            tooltip-format-enumerate-connected-battery = "{device_alias} {device_battery_percentage}%";
            on-click = "ghostty -e bluetuith";
          };

          network = {
            format-icons = ["󰤯" "󰤟" "󰤢" "󰤥" "󰤨"];
            format = "{icon}";
            format-wifi = "{icon}";
            format-ethernet = "󰀂";
            format-disconnected = "󰤮";
            tooltip-format-wifi = "{essid} ({frequency} GHz)\n⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
            tooltip-format-ethernet = "⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
            tooltip-format-disconnected = "Disconnected";
            interval = 3;
            spacing = 1;
            on-click = "ghostty -e impala";
          };

          battery = {
            format = "{capacity}% {icon}";
            format-discharging = "{icon}";
            format-charging = "{icon}";
            format-plugged = "";
            format-icons = {
              charging = ["󰢜" "󰂆" "󰂇" "󰂈" "󰢝" "󰂉" "󰢞" "󰂊" "󰂋" "󰂅"];
              default = ["󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
            };
            format-full = "󰂅";
            tooltip-format-discharging = "{power:>1.0f}W↓ {capacity}%";
            tooltip-format-charging = "{power:>1.0f}W↑ {capacity}%";
            interval = 5;
            states = {
              warning = 20;
              critical = 10;
            };
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

        #language {
          padding: 0 12px;
          margin: 4px 2px;
          border-radius: 6px;
          background: @bg-selection;
          color: @fg;
          font-weight: bold;
        }

        #cpu,
        #memory,
        #pulseaudio,
        #network,
        #battery {
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

        #bluetooth {
          color: @blue;
        }

        #bluetooth.connected {
          color: @cyan;
        }

        #bluetooth.off,
        #bluetooth.disabled {
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
          margin-right: 8px;
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
      '';
    };
  };
}
