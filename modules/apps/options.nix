# App options for home-manager
# These options are defined here so userSettings.apps.* can be set in home.nix
{ lib, ... }:

with lib;
{
  options.userSettings.apps = {
    slack.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Slack";
    };
  };
}
