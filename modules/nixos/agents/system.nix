{ config, lib, pkgs, ... }:

# Device-wide tracking of coding-agent sessions: which are working, which are
# waiting on you, which are idle - across every terminal and tmux session. See
# ./agent-status.sh for the registry, and quickshell/Common/Agents.qml for the
# bar and the SUPER+A picker that read it.

with lib; let
  cfg = config.systemSettings.agents;
  agentStatus = import ./package.nix { inherit pkgs; };
  hook = [{ type = "command"; command = "${getExe agentStatus} hook"; timeout = 5; }];
in
{
  options.systemSettings.agents.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Track coding-agent sessions (Claude Code) for the bar and SUPER+A picker";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ agentStatus ];

    # Claude Code merges hooks from every settings source, and this drop-in
    # directory is its system-wide one - so the hooks apply to every session
    # without touching ~/.claude/settings.json, which Claude Code rewrites
    # itself. Events without a matcher field fire for every tool/type.
    environment.etc."claude-code/managed-settings.d/50-agent-status.json".text = builtins.toJSON {
      hooks = genAttrs [
        "SessionStart"
        "UserPromptSubmit"
        "PreToolUse"
        "PostToolUse"
        "PostToolUseFailure"
        "PermissionDenied"
        "Notification"
        "Stop"
        "StopFailure"
        "SessionEnd"
      ] (_: [{ hooks = hook; }]);
    };
  };
}
