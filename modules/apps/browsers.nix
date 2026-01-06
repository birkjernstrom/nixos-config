# Browsers module (system-level)
# Installs browsers via homebrew on Darwin, via nixpkgs on NixOS
{ config, lib, pkgs, settings, isDarwin, ... }:

let
  cfg = settings.user.apps.browsers or {};
  chromeEnabled = cfg.chrome.enable or false;
  firefoxEnabled = cfg.firefox.enable or false;
  defaultBrowser = cfg.default or "chrome";
  username = settings.user.name;

  # Browser commands for hyprland binding
  browserCmd = {
    chrome = "google-chrome-stable";
    firefox = "firefox";
  };
in
{
  config = if isDarwin then {
    # Darwin: install via homebrew casks
    homebrew.casks = lib.mkMerge [
      (lib.mkIf chromeEnabled [ "google-chrome" ])
      (lib.mkIf firefoxEnabled [ "firefox" ])
    ];
  } else {
    # NixOS/Linux: install via home-manager
    home-manager.users.${username} = lib.mkMerge [
      (lib.mkIf chromeEnabled {
        home.packages = [ pkgs.google-chrome ];
      })
      (lib.mkIf firefoxEnabled {
        home.packages = [ pkgs.firefox ];
      })
      # Add hyprland keybinding for default browser (Super+B)
      (lib.mkIf (chromeEnabled || firefoxEnabled) {
        wayland.windowManager.hyprland.settings.bind = [
          "SUPER, B, exec, ${browserCmd.${defaultBrowser}}"
        ];
      })
    ];
  };
}
