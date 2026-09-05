# Web browsers.
#
# Both are installed; `SUPER + B` opens Chrome, which is the default on both
# hosts today. Change the binding here rather than through a setting - there is
# one user and one preference.
{ lib, ... }:

let
  inherit (import ../desktop/_hypr.nix { inherit lib; }) bind exec;
in
{
  flake.modules.darwin.gui-apps = {
    homebrew.casks = [ "google-chrome" "firefox" ];
  };

  flake.modules.homeManager.desktop = { pkgs, ... }: {
    home.packages = with pkgs; [
      google-chrome
      firefox
    ];

    wayland.windowManager.hyprland.settings.bind = [
      (bind "SUPER + B" (exec "google-chrome-stable"))
    ];
  };
}
