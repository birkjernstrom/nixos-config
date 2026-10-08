{ config, lib, pkgs, ... }:

# Each program's config is the same for every theme and includes its colours
# from the active theme's folder, so a switch is a symlink change and a reload.
# Stylix's colours are turned off for these; its fonts and the rest stay.
let
  current = "${config.xdg.stateHome}/theme/current";
in
{
  config = lib.mkIf config.userSettings.themes.enable {
    stylix.targets.hyprland.colors.enable = false;
    wayland.windowManager.hyprland.extraConfig = ''
      do
        local ok, colors = pcall(dofile, "${current}/hyprland.lua")
        if not ok then
          colors = { general = { ["col.active_border"] = "rgb(625e5a)", ["col.inactive_border"] = "rgb(282727)" } }
        end
        hl.config(colors)
      end
    '';

    stylix.targets.ghostty.colors.enable = false;
    programs.ghostty.settings.theme = "${current}/ghostty";

    # Before tmux.nix's own lines, which paint over its backgrounds.
    stylix.targets.tmux.colors.enable = false;
    programs.tmux.extraConfig = lib.mkBefore ''
      source-file -q ${current}/tmux.conf
    '';

    # Stylix's colour block also chose the base theme; keep it.
    stylix.targets.gtk.colors.enable = false;
    gtk.theme = {
      package = pkgs.adw-gtk3;
      name = "adw-gtk3";
    };
    gtk.gtk4.theme = config.gtk.theme;
    xdg.configFile = lib.genAttrs [ "gtk-3.0/gtk.css" "gtk-4.0/gtk.css" ] (_: {
      text = ''
        @import url("file://${current}/gtk.css");
      '';
    });

    stylix.targets.hyprlock.colors.enable = false;
    programs.hyprlock.settings = {
      source = "${current}/hyprlock.conf";
      background.color = "$base00";
      input-field = {
        outer_color = "$base03";
        inner_color = "$base00";
        font_color = "$base05";
        fail_color = "$base08";
        check_color = "$base0A";
      };
    };
  };
}
