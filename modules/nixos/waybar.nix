{ config, lib, pkgs, ... }:

with lib; let
  cfg = config.userSettings.waybar;

  # Pango markup in the clock tooltip can't reference the GTK @colour names,
  # so read the palette back from Stylix instead of restating it.
  colors = config.lib.stylix.colors.withHashtag;
in
{
  options.userSettings.waybar.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable waybar status bar";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.impala pkgs.bluetuith ];

    # Stylix defines the @base00-@base0F colours and the font used below.
    # Its opinionated default stylesheet is skipped - the layout is ours.
    stylix.targets.waybar.addCss = false;

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
            "custom/system"
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
            all-outputs = false;
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
                months = "<span color='${colors.base06}'><b>{}</b></span>";
                days = "<span color='${colors.base05}'>{}</span>";
                weeks = "<span color='${colors.base0C}'><b>W{}</b></span>";
                weekdays = "<span color='${colors.base0A}'><b>{}</b></span>";
                today = "<span color='${colors.base08}'><b><u>{}</u></b></span>";
              };
            };
          };

          "custom/system" = {
            format = " 󰍛";
            tooltip = false;
            on-click = "ghostty -e btop";
          };

          pulseaudio = {
            format = "{icon}";
            format-muted = "󰝟";
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
            format-connected = "󰂱";
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
            format = "{icon}";
            format-discharging = "{icon}";
            format-charging = "{icon}";
            format-plugged = "";
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

      # Layout only - every colour below is a Stylix-defined GTK colour name.
      style = ''
        * {
          min-height: 0;
        }

        /* Without this the bar falls through to the GTK theme's window
           background instead of the Stylix palette. */
        window#waybar {
          background: @base00;
          color: @base05;
        }

        tooltip {
          background: @base00;
          border: 1px solid @base0E;
          border-radius: 8px;
        }

        tooltip label {
          color: @base05;
        }

        #workspaces {
          margin-left: 8px;
        }

        #workspaces button {
          padding: 0 8px;
          margin: 4px 2px;
          color: @base03;
          transition: all 0.2s ease;
        }

        #workspaces button:hover {
          background: @base02;
          color: @base05;
        }

        #workspaces button.active {
          background: @base0E;
          color: @base00;
        }

        #workspaces button.urgent {
          background: @base08;
          color: @base00;
        }

        #window {
          padding: 0 12px;
          color: @base03;
        }

        #clock {
          padding: 0 16px;
          color: @base03;
          font-weight: bold;
        }

        #language {
          padding: 0 12px;
          margin: 4px 2px;
          background: transparent;
          color: @base03;
          font-weight: bold;
        }

        #custom-system,
        #pulseaudio,
        #bluetooth,
        #network,
        #battery {
          padding: 0 10px;
          margin: 4px 2px;
          color: @base03;
        }

        #pulseaudio.muted {
          opacity: 0.5;
        }

        #bluetooth.off,
        #bluetooth.disabled {
          opacity: 0.5;
        }

        #network.disconnected {
          opacity: 0.5;
        }

        #battery {
          margin-right: 8px;
        }

        #battery.charging {
          animation: pulse 2s infinite;
        }

        #battery.warning:not(.charging) {
          color: @base0A;
        }

        #battery.critical:not(.charging) {
          color: @base08;
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
