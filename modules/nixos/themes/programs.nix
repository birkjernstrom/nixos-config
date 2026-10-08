{ config, lib, pkgs, ... }:

# Each program's config is the same for every theme and includes its colours
# from the active theme's folder, so a switch is a symlink change and a reload.
# Stylix's colours are turned off for these; its fonts and the rest stay.
let
  current = "${config.xdg.stateHome}/theme/current";
  gtkCss = ''
    @import url("file://${current}/gtk.css");
  '';
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
    xdg.configFile."gtk-3.0/gtk.css".text = gtkCss;
    xdg.configFile."gtk-4.0/gtk.css".text = gtkCss;

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

    stylix.targets.zathura.colors.enable = false;
    programs.zathura.extraConfig = "include ${current}/zathurarc";

    # Nothing merges ~/.Xresources in a Hyprland session.
    stylix.targets.x11.colors.enable = false;
    stylix.targets.sxiv.colors.enable = false;

    # bat's built-in base16 theme uses the terminal's ANSI colours, so it
    # follows Ghostty.
    stylix.targets.bat.colors.enable = false;
    programs.bat.config.theme = "base16";

    # starship and mako are small enough to render whole per theme
    # (./colors.nix), from their usual settings.
    stylix.targets.starship.colors.enable = false;
    home.file.${config.programs.starship.configPath}.source =
      lib.mkForce (config.lib.file.mkOutOfStoreSymlink "${current}/starship.toml");

    stylix.targets.mako.colors.enable = false;
    xdg.configFile."mako/config".source =
      lib.mkForce (config.lib.file.mkOutOfStoreSymlink "${current}/mako");
  };
}
