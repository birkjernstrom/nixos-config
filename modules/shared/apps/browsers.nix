# Browsers module (system-level)
# Installs browsers via homebrew on Darwin, via nixpkgs on NixOS
{ config, lib, pkgs, settings, isDarwin, ... }:

let
  cfg = settings.user.apps.browsers or {};
  chromeEnabled = cfg.chrome.enable or false;
  chromeExtensions = cfg.chrome.extensions or [];
  firefoxEnabled = cfg.firefox.enable or false;
  defaultBrowser = cfg.default or "chrome";
  username = settings.user.name;

  hypr = import ../../nixos/hyprland/lib.nix { inherit lib; };
  inherit (hypr) bind exec;

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
  } else lib.mkMerge [
    {
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
            (bind "SUPER + B" (exec browserCmd.${defaultBrowser}))
          ];
        })
      ];
    }

    # Chrome extensions. A managed-policy file is the only way to install an
    # extension declaratively on Linux - there is no per-profile equivalent,
    # the profile's extension list lives in Chrome's own sqlite/JSON state.
    # `programs.chromium` is misnamed: it writes the policy for Chromium,
    # Chrome (/etc/opt/chrome/policies/managed/default.json) and Brave alike.
    #
    # ExtensionInstallForcelist installs on next launch and pre-grants the
    # permissions, so the extension cannot be removed or disabled from
    # chrome://extensions - dropping the ID from settings.nix is the uninstall.
    # Chrome will show "Managed by your organization" while any policy is set.
    (lib.mkIf (chromeEnabled && chromeExtensions != []) {
      programs.chromium = {
        enable = true;
        extensions = chromeExtensions;
      };
    })
  ];
}
