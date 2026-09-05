# Obsidian.
#
# macOS gets it as a homebrew cask; Linux from nixpkgs, with a launcher
# binding in the Hyprland session. The binding lives in `desktop` rather than
# alongside the package because it only means anything where Hyprland runs.
{ lib, ... }:

let
  inherit (import ../desktop/_hypr.nix { inherit lib; }) bind exec;
in
{
  flake.modules.darwin.gui-apps = {
    homebrew.casks = [ "obsidian" ];
  };

  flake.modules.homeManager.desktop = { pkgs, ... }: {
    home.packages = [ pkgs.obsidian ];

    wayland.windowManager.hyprland.settings.bind = [
      (bind "SUPER + O" (exec "obsidian"))
    ];
  };
}
