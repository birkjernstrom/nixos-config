# Home-manager options for system-level modules
# These options allow userSettings.* to be set in home.nix
{ lib, ... }:

with lib;
{
  options.userSettings = {
    apps = {
      slack.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Slack";
      };

      browsers = {
        chrome.enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable Google Chrome";
        };
        firefox.enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable Firefox";
        };
        default = mkOption {
          type = types.enum [ "chrome" "firefox" ];
          default = "chrome";
          description = "Default browser for keybindings";
        };
      };
    };

    docker.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Docker with lazydocker and waybar integration";
    };

    terminal.ghostty = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Ghostty terminal";
      };
      font = {
        family = mkOption {
          type = types.str;
          default = "BerkeleyMono Nerd Font Mono";
          description = "Font family for Ghostty";
        };
        size = mkOption {
          type = types.int;
          default = 12;
          description = "Font size for Ghostty";
        };
      };
    };
  };
}
