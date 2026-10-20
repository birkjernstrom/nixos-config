{ config, lib, ... }:

with lib; let
  cfg = config.userSettings.programming.ai;
  livePiSources = true;
  piSource = name:
    if livePiSources then
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.nixos-config/dotfiles/pi/${name}"
    else
      ../../../dotfiles/pi + "/${name}";
in
{
  config = mkIf cfg.enable {
    home.file.".pi/agent/AGENTS.md".source = ../../../dotfiles/agents/AGENTS.md;
    home.file.".pi/agent/extensions".source = piSource "extensions";
    home.file.".pi/agent/skills".source = piSource "skills";
    home.file.".pi/agent/permissions.json".source = piSource "permissions.json";
  };
}
