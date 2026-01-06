# Options for home-manager
# These options are defined here so userSettings.* can be set in home.nix
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
