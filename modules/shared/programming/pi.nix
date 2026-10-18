{ config, lib, ... }:

with lib; let
  cfg = config.userSettings.programming.ai;
in
{
  config = mkIf cfg.enable {
    home.file.".pi/agent/AGENTS.md".source = ../../../dotfiles/agents/AGENTS.md;
    home.file.".pi/agent/extensions/ask-user.ts".source = ../../../dotfiles/pi/extensions/ask-user.ts;
  };
}
