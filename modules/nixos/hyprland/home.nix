{ config, lib, pkgs, ... }:

with lib; let
  cfg = config.userSettings.hyprland;
in
{
  imports = [
    ./autostart.nix
    ./bindings.nix
    ./hypridle.nix
    ./hyprlock.nix
    ./hyprshot.nix
    ./workspaces.nix
  ];

  options.userSettings.hyprland.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Hyprland (NixOS)";
  };

  config = mkIf cfg.enable {
    # Automatically enable companion services
    # Quickshell owns the bar, the SUPER+space launcher and the SUPER+V
    # clipboard history that wofi and waybar used to provide between them.
    userSettings.quickshell.enable = true;
    userSettings.mako.enable = true;

    # Clipboard utilities for Wayland
    home.packages = with pkgs; [
      wl-clipboard  # Wayland clipboard utilities (wl-copy, wl-paste)
      cliphist      # Clipboard history manager
    ];

    wayland.windowManager.hyprland = {
      enable = true;

      # Generate ~/.config/hypr/hyprland.lua instead of hyprland.conf.
      # Every setting below is rendered as an hl.<name>(...) call.
      configType = "lua";

      settings = {
        # Lua locals, referenced from the keybindings in ./bindings.nix
        mainMod = { _var = "SUPER"; };
        terminal = { _var = "ghostty"; };
        fileManager = { _var = "nautilus"; };
        # Toggles the resident Pathway window rather than spawning a launcher.
        menu = { _var = "qs ipc call pathway toggle"; };

        monitor = [
          { output = ""; mode = "preferred"; position = "auto"; scale = "auto"; }
          { output = "eDP-1"; mode = "preferred"; position = "auto"; scale = 1.25; }
        ];

        config = {
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
            inactive_opacity = 0.90;
            # shadow = {
            #   enabled = true;
            #   range = 20;
            #   render_power = 1;
            # };
            # blur = {
            #   enabled = true;
            #   size = 6;
            #   passes = 3;
            #   new_optimizations = true;
            #   ignore_opacity = false;
            #   xray = false;
            # };
          };

          animations.enabled = true;

          # Dwindle layout
          dwindle = {
            # pseudotile removed as a config option in Hyprland 0.56; use the
            # `pseudo` dispatcher to toggle it per-window instead.
            preserve_split = true;
            force_split = 2;
          };

          # Misc settings
          misc = {
            disable_hyprland_logo = true;
            disable_splash_rendering = true;
            force_default_wallpaper = 0;
          };

          input = {
            # se(us) is a plain US layout with å/ö/ä added as direct keysyms
            # on AltGr+[ ; ' -- the same physical keys they occupy on a
            # Swedish keyboard, Shift for the capitals. Deliberately not a
            # dead-key scheme: Ghostty does not compose those, so anything
            # built on dead_diaeresis works in GTK apps but not the terminal.
            # Second group is the full Swedish layout (SUPER+SHIFT+space).
            kb_layout = "se,se";
            kb_variant = "us,";
            repeat_delay = 200;
            repeat_rate = 100;
            sensitivity = 0;
            follow_mouse = 1;
            touchpad = {
              natural_scroll = true;
              disable_while_typing = true;
              tap_to_click = true;
              scroll_factor = 0.4;
            };
          };
        };

        # Animation curves, rendered before the animations that reference them
        curve = [
          { _args = [ "easeOutQuint"   { type = "bezier"; points = [ [ 0.23 1 ] [ 0.32 1 ] ]; } ]; }
          { _args = [ "easeInOutCubic" { type = "bezier"; points = [ [ 0.65 0 ] [ 0.35 1 ] ]; } ]; }
          { _args = [ "linear"         { type = "bezier"; points = [ [ 0 0 ] [ 1 1 ] ]; } ]; }
          { _args = [ "almostLinear"   { type = "bezier"; points = [ [ 0.5 0.5 ] [ 0.75 1.0 ] ]; } ]; }
          { _args = [ "quick"          { type = "bezier"; points = [ [ 0.15 0 ] [ 0.1 1 ] ]; } ]; }
        ];

        animation = [
          { leaf = "global";        enabled = true; speed = 10;   bezier = "default"; }
          { leaf = "border";        enabled = true; speed = 5.39; bezier = "easeOutQuint"; }
          { leaf = "windows";       enabled = true; speed = 4.79; bezier = "easeOutQuint"; }
          { leaf = "windowsIn";     enabled = true; speed = 4.1;  bezier = "easeOutQuint"; style = "popin 87%"; }
          { leaf = "windowsOut";    enabled = true; speed = 1.49; bezier = "linear";       style = "popin 87%"; }
          { leaf = "fadeIn";        enabled = true; speed = 1.73; bezier = "almostLinear"; }
          { leaf = "fadeOut";       enabled = true; speed = 1.46; bezier = "almostLinear"; }
          { leaf = "fade";          enabled = true; speed = 3.03; bezier = "quick"; }
          { leaf = "layers";        enabled = true; speed = 3.81; bezier = "easeOutQuint"; }
          { leaf = "layersIn";      enabled = true; speed = 4;    bezier = "easeOutQuint"; style = "fade"; }
          { leaf = "layersOut";     enabled = true; speed = 1.5;  bezier = "linear";       style = "fade"; }
          { leaf = "fadeLayersIn";  enabled = true; speed = 1.79; bezier = "almostLinear"; }
          { leaf = "fadeLayersOut"; enabled = true; speed = 1.39; bezier = "almostLinear"; }
          { leaf = "workspaces";    enabled = true; speed = 1.94; bezier = "almostLinear"; style = "fade"; }
          { leaf = "workspacesIn";  enabled = true; speed = 1.21; bezier = "almostLinear"; style = "fade"; }
          { leaf = "workspacesOut"; enabled = true; speed = 1.94; bezier = "almostLinear"; style = "fade"; }
        ];

        window_rule = [
          {
            # The TUI panes the Quickshell bar opens - impala on the wifi icon,
            # bluetui on the bluetooth one. They are transient panes rather than
            # windows to tile against, and Quickshell owns their lifetime: a
            # second click on the icon closes the one it opened. Ghostty is told
            # its own size in rows and columns, so nothing here has to name a
            # pixel size that would be wrong on the next monitor.
            name = "float-bar-tui";
            match.class = "^sh\\.pathway\\.tui\\.";
            float = true;
            center = true;
          }
          {
            # Ignore maximize requests from all apps
            name = "suppress-maximize-events";
            match.class = ".*";
            suppress_event = "maximize";
          }
          {
            # Fix some dragging issues with XWayland
            name = "fix-xwayland-drags";
            match = {
              class = "^$";
              title = "^$";
              xwayland = true;
              float = true;
              fullscreen = false;
              pin = false;
            };
            no_focus = true;
          }
        ];
      };
    };
  };
}
