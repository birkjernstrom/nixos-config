{ config, pkgs, lib, inputs, ... }:

with lib; let
  cfg = config.userSettings.cli.workmux;
  workmux = inputs.workmux.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  options.userSettings.cli.workmux.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable workmux (git worktrees + tmux windows for parallel agents).";
  };

  config = mkIf cfg.enable {
    home.packages = [ workmux ];

    programs.zsh.shellAliases.wm = "workmux";

    xdg.configFile."workmux/config.yaml".text = ''
      nerdfont: true
      agent: claude
      status_format: false
    '';

    # status_format is off so workmux doesn't rewrite the formats per session.
    programs.tmux.extraConfig = ''
      set -g window-status-format '#I:#W#{?@workmux_status, #{@workmux_status},}#{?window_flags,#{window_flags}, }'
      set -g window-status-current-format '#I:#W#{?@workmux_status, #{@workmux_status},}#{?window_flags,#{window_flags}, }'

      bind a display-popup -h 30 -w 100 -E "workmux dashboard"
      bind W display-popup -h 30 -w 100 -E "workmux dashboard --tab worktrees"
      bind C-t run-shell "workmux sidebar"
      bind A run-shell "workmux last-done"
      bind Tab run-shell "workmux last-agent"
    '';

    # Status hooks come from upstream's Claude Code plugin. settings.json is
    # rewritten by Claude Code, so patch it rather than owning it.
    home.activation.claudeWorkmuxStatus = hm.dag.entryAfter [ "writeBoundary" ] ''
      settings="$HOME/.claude/settings.json"
      if [[ -f $settings && -z ''${DRY_RUN:-} ]]; then
        ${getExe pkgs.jq} '
          .extraKnownMarketplaces.workmux = { source: { source: "github", repo: "raine/workmux" } }
          | .enabledPlugins["workmux-status@workmux"] = true
        ' "$settings" > "$settings.tmp" && mv "$settings.tmp" "$settings"
      fi
    '';
  };
}
