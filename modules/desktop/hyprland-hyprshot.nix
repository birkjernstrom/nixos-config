# hyprshot: screenshot bindings.
#
# The `hl.*` helpers come from modules/desktop/_hypr.nix, which is a plain
# function rather than a module - import-tree skips it because of the `_`.
{ lib, ... }:

let
  hypr = import ./_hypr.nix { inherit lib; };
  inherit (hypr) bind mod exec;
in
{
  flake.modules.homeManager.desktop = { config, pkgs, ... }: {
    home.packages = with pkgs; [
      hyprshot
    ];

    wayland.windowManager.hyprland.settings = {
      bind = [
        # Screenshots with hyprshot
        (bind "F11" (exec "hyprshot -m output"))                # Full screen
        (bind (mod "F11") (exec "hyprshot -m window"))          # Active window
        (bind (mod "SHIFT + S") (exec "hyprshot -m region"))    # Region selection
      ];
    };
  };
}
