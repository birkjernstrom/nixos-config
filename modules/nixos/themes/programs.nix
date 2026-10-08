{ config, lib, ... }:

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
  };
}
