{ config, lib, ... }:

# The user half of ./system.nix: SUPER+A opens the agent picker - Pathway,
# scoped to the live agent sessions, where Enter jumps to one.

with lib; let
  cfg = config.userSettings.agents;
  hypr = import ../hyprland/lib.nix { inherit lib; };
  inherit (hypr) bind mod exec;
in
{
  options.userSettings.agents.enable = mkOption {
    type = types.bool;
    default = false;
    description = "SUPER+A agent picker (needs systemSettings.agents for the data)";
  };

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings.bind = [
      (bind (mod "A") (exec "qs ipc call pathway agents"))
    ];
  };
}
