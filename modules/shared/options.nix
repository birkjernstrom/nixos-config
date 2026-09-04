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

      obsidian.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Obsidian";
      };

      todoist.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Todoist";
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
      description = "Enable Docker with lazydocker";
    };

    # Font and colours are configured centrally, in modules/shared/stylix.nix.
    terminal.ghostty.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Ghostty terminal";
    };
  };
}
