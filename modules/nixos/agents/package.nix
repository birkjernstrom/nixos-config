{ pkgs }:

# `agent-status`, shared by ./system.nix (the Claude Code hooks call it by store
# path) and the Quickshell bar (which finds it on PATH).
pkgs.writeShellApplication {
  name = "agent-status";
  # hyprctl, tmux, ghostty and qs come from the user's session rather than
  # being pinned here, so they always match the running compositor, server and
  # shell.
  runtimeInputs = with pkgs; [ coreutils gawk gnugrep jq ];
  text = builtins.readFile ./agent-status.sh;
}
