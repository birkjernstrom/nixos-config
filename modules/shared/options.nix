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

      browsers = {
        chrome = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable Google Chrome";
          };
          extensions = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = ''
              Chrome Web Store extension IDs to force-install through Chrome's
              managed policy. The ID is the last path segment of the
              extension's store URL. NixOS only - see
              modules/shared/apps/browsers.nix.
            '';
            example = [ "dbepggeogbaibhgnhhndojpepiihcmeb" ];
          };
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
