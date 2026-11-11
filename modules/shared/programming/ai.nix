{ config, pkgs, lib, ... }:

with lib; let
  cfg = config.userSettings.programming.ai;
  skillsDir = "${config.home.homeDirectory}/.nixos-config/dotfiles/agents/skills";
  skills = attrNames (filterAttrs (_: type: type == "directory") (builtins.readDir ../../../dotfiles/agents/skills));
in
{
  options.userSettings.programming.ai.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable AI tools (claude-code, codex, opencode, herdr, pi).";
  };

  config = mkIf cfg.enable (mkMerge [{
    # claude-cli:// deep links. Claude Code writes the handler's .desktop file
    # into ~/.local/share/applications itself; this only points the scheme at
    # it, since mimeapps.list is owned by home-manager (see apps/zathura.nix).
    xdg.mimeApps = mkIf pkgs.stdenv.hostPlatform.isLinux {
      enable = true;
      defaultApplications."x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
    };

    home.packages = with pkgs; [
      claude-code
      codex             # OpenAI Codex CLI
      opencode
      herdr             # Agent multiplexer for the terminal (herdr.dev)
      pi-coding-agent   # `pi` coding agent CLI (pi.dev)
    ];

    home.file.".claude/CLAUDE.md".source = ../../../dotfiles/agents/AGENTS.md;
    home.file.".codex/AGENTS.md".source = ../../../dotfiles/agents/AGENTS.md;
    home.file.".config/opencode/AGENTS.md".source = ../../../dotfiles/agents/AGENTS.md;

    # ~/.agents/skills is read by Codex, OpenCode and Pi. Claude Code only reads
    # ~/.claude/skills, which it also writes to, so link each skill separately.
    home.file.".agents/skills".source = config.lib.file.mkOutOfStoreSymlink skillsDir;

    # The commit skill forbids trailers. settings.json is rewritten by Claude
    # Code, so patch it rather than owning it.
    home.activation.claudeAttribution = hm.dag.entryAfter [ "writeBoundary" ] ''
      settings="$HOME/.claude/settings.json"
      if [[ -f $settings && -z ''${DRY_RUN:-} ]]; then
        ${getExe pkgs.jq} '.attribution = { commit: "", pr: "" }' "$settings" > "$settings.tmp" && mv "$settings.tmp" "$settings"
      fi
    '';

    home.file.".config/herdr/config.toml" = {
      source = ../../../dotfiles/herdr/config.toml;

      # A herdr server keeps the config it read at startup, so home-manager
      # swapping the store symlink underneath it changes nothing until the
      # server is restarted - a switch appears to do nothing, and the stale
      # config outlives several rebuilds. Reload it so the change lands in the
      # session you are already sitting in.
      #
      # Guarded on the socket because there is nothing to reload when no server
      # is running, and swallowed entirely because a multiplexer declining to
      # reload is not a reason to fail the activation.
      onChange = ''
        if [ -S "''${XDG_CONFIG_HOME:-$HOME/.config}/herdr/herdr.sock" ]; then
          ${pkgs.herdr}/bin/herdr server reload-config >/dev/null 2>&1 || true
        fi
      '';
    };
  }
  {
    home.file = listToAttrs (map (name: nameValuePair ".claude/skills/${name}" {
      source = config.lib.file.mkOutOfStoreSymlink "${skillsDir}/${name}";
    }) skills);
  }]);
}
