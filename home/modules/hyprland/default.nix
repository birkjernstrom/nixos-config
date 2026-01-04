{ config, lib, ... }:

with lib; let
  feat = config.features.hyprland;
in
{
  imports = [
    ./autostart.nix
    ./bindings.nix
  ];

  options.features.hyprland.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Hyperland (NixOS)";
  };

  config = mkIf feat.enable {
    # Automatically enable companion services
    features.wofi.enable = true;
    features.waybar.enable = true;

    wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        monitor = ",preferred,auto,auto";
        "$terminal" = "ghostty";
        "$fileManager" = "dolphin";
        "$menu" = "wofi --show drun";

        "env" = [
          "XCURSOR_SIZE,24"
          "HYPERCURSOR_SIZE,24"
        ];

        # General settings (border colors handled by Stylix)
        general = {
          gaps_in = 5;
          gaps_out = 5;
          border_size = 1;
          resize_on_border = true;
          layout = "dwindle";
        };

        # Decoration settings (colors handled by Stylix)
        decoration = {
          active_opacity = 1.0;
          inactive_opacity = 0.95;
          shadow = {
            enabled = true;
            range = 20;
            render_power = 3;
          };
          blur = {
            enabled = true;
            size = 6;
            passes = 3;
            new_optimizations = true;
            ignore_opacity = true;
            xray = false;
          };
        };

        # Animations
        animations = {
          enabled = true;
          bezier = [
            "easeOutQuint, 0.23, 1, 0.32, 1"
            "easeInOutCubic, 0.65, 0, 0.35, 1"
            "linear, 0, 0, 1, 1"
            "almostLinear, 0.5, 0.5, 0.75, 1.0"
            "quick, 0.15, 0, 0.1, 1"
          ];
          animation = [
            "global, 1, 10, default"
            "border, 1, 5.39, easeOutQuint"
            "windows, 1, 4.79, easeOutQuint"
            "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
            "windowsOut, 1, 1.49, linear, popin 87%"
            "fadeIn, 1, 1.73, almostLinear"
            "fadeOut, 1, 1.46, almostLinear"
            "fade, 1, 3.03, quick"
            "layers, 1, 3.81, easeOutQuint"
            "layersIn, 1, 4, easeOutQuint, fade"
            "layersOut, 1, 1.5, linear, fade"
            "fadeLayersIn, 1, 1.79, almostLinear"
            "fadeLayersOut, 1, 1.39, almostLinear"
            "workspaces, 1, 1.94, almostLinear, fade"
            "workspacesIn, 1, 1.21, almostLinear, fade"
            "workspacesOut, 1, 1.94, almostLinear, fade"
          ];
        };

        # Dwindle layout
        dwindle = {
          pseudotile = true;
          preserve_split = true;
          force_split = 2;
        };

        # Misc settings
        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          force_default_wallpaper = 0;
        };

        "windowrule" = [
          "suppressevent maximize, class:.*"
          "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
        ];

        input = {
          repeat_delay = 200;
          repeat_rate = 100;
          sensitivity = 0;
          follow_mouse = 1;
          touchpad = {
            natural_scroll = true;
            disable_while_typing = true;
            tap-to-click = true;
          };
        };
      };
    };
  };
}
