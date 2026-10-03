#!/usr/bin/env bash
#
# Packaged by ./default.nix with writeShellApplication, which lints it with
# ShellCheck at build time, prepends `set -euo pipefail`, and puts the tools
# listed in its runtimeInputs on PATH.
#
# A device-wide registry of coding-agent sessions: one JSON file per session in
# $XDG_RUNTIME_DIR/agents, written by the agent's own hooks, read by the
# Quickshell bar and the SUPER+A picker. Nothing here is a daemon - the files
# are the state, and a session whose process has gone is pruned on read.
#
#   agent-status hook          Claude Code hook: event JSON on stdin
#   agent-status list          JSON array of live sessions, most urgent first
#   agent-status jump <id>     focus the session's terminal, window and pane
#
# States: "working" (the agent is busy), "waiting" (it needs you: a permission
# prompt or a question), "idle" (finished, or never started).

DIR="${XDG_RUNTIME_DIR:-/tmp/agent-status-$UID}/agents"

# Tell the bar to re-read now rather than on its next poll. Detached, so a
# slow or absent shell never holds up the agent.
poke_bar() {
  (qs ipc call agents refresh &>/dev/null &)
}

# The agent process itself. Hooks run as children of Claude Code, sometimes
# with a shell in between, so walk up until we reach it.
agent_pid() {
  local pid=$PPID comm
  for _ in 1 2 3 4 5 6; do
    [[ -r /proc/$pid/comm ]] || break
    comm="$(</proc/"$pid"/comm)"
    if [[ $comm == claude || $comm == .claude-wrapped ]]; then
      echo "$pid"
      return
    fi
    pid="$(awk '{print $4}' /proc/"$pid"/stat)"
    ((pid > 1)) || break
  done
  echo "$PPID"
}

# Where to jump back to: the tmux pane the agent runs in (if any) and the
# Hyprland window that was focused. Only captured on events the user causes by
# typing in that terminal - SessionStart and UserPromptSubmit - since those are
# the moments the focused window is known to be the agent's.
location_json() {
  local tmux='null' window=''
  if [[ -n ${TMUX_PANE:-} ]] && command -v tmux >/dev/null; then
    tmux="$(tmux display-message -p -t "$TMUX_PANE" \
      '#{session_name}	#{window_index}	#{window_name}	#{client_tty}' 2>/dev/null |
      jq -R --arg pane "$TMUX_PANE" 'split("\t") |
        {pane: $pane, session: .[0], window: .[1], windowName: .[2], client: .[3]}' || echo null)"
  fi
  if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
    window="$(timeout 1 hyprctl activewindow -j 2>/dev/null | jq -r '.address // empty' || true)"
  fi
  jq -n --argjson tmux "${tmux:-null}" --arg window "$window" \
    '{tmux: $tmux, window: (if $window == "" then null else $window end)}'
}

cmd_hook() {
  local input event id file state='' capture=false
  input="$(cat)"
  event="$(jq -r '.hook_event_name // empty' <<<"$input")"
  id="$(jq -r '.session_id // empty' <<<"$input")"
  [[ -n $event && -n $id ]] || return 0

  mkdir -p "$DIR"
  file="$DIR/claude-$id.json"

  case $event in
  SessionStart) state=idle capture=true ;;
  UserPromptSubmit) state=working capture=true ;;
  PreToolUse)
    # These two put a decision in front of the user immediately, rather than
    # after the ~6s a permission prompt's Notification takes to arrive.
    case "$(jq -r '.tool_name // empty' <<<"$input")" in
    AskUserQuestion | ExitPlanMode) state=waiting ;;
    *) state=working ;;
    esac
    ;;
  # Fires once an approved tool has run, which is what takes a session out of
  # "waiting" - there is no hook for the approval itself.
  PostToolUse | PostToolUseFailure | PermissionDenied) state=working ;;
  Notification)
    case "$(jq -r '.notification_type // empty' <<<"$input")" in
    permission_prompt | elicitation_dialog | elicitation_url_dialog) state=waiting ;;
    *) return 0 ;;
    esac
    ;;
  Stop | StopFailure) state=idle ;;
  SessionEnd)
    rm -f "$file"
    poke_bar
    return 0
    ;;
  *) return 0 ;;
  esac

  # Only the fields kept below: PostToolUse carries the tool's entire output,
  # which is far too large to pass around as an argument.
  local slim previous='{}' location='{}'
  slim="$(jq -c '{session_id, cwd, transcript_path, prompt}' <<<"$input")"
  [[ -f $file ]] && previous="$(cat "$file" 2>/dev/null || echo '{}')"
  $capture && location="$(location_json)"

  local tmp="$file.$$"
  jq -n \
    --argjson prev "$previous" --argjson in "$slim" --argjson loc "$location" \
    --arg state "$state" --argjson pid "$(agent_pid)" --argjson now "$(date +%s)" '
    $prev + {
      id: $in.session_id,
      agent: "claude",
      state: $state,
      # Only a change of state restarts the clock, so "working for 12m" means
      # twelve minutes of work rather than time since the last tool call.
      since: (if $prev.state == $state then ($prev.since // $now) else $now end),
      cwd: ($in.cwd // $prev.cwd),
      transcript: ($in.transcript_path // $prev.transcript),
      pid: $pid
    }
    + (if $in.prompt then {prompt: ($in.prompt | gsub("\\s+"; " ") | .[0:160])} else {} end)
    + ($loc | with_entries(select(.value != null)))
    ' >"$tmp" && mv "$tmp" "$file"

  poke_bar
}

# Esc fires no hook, so an interrupted session would read "working" forever.
# Claude Code does write the interruption into the transcript, though, as the
# last user message.
interrupted() {
  local transcript="$1"
  [[ -f $transcript ]] || return 1
  tail -n 20 "$transcript" | jq -rs '
    map(select(.type == "user" or .type == "assistant")) | last |
    select(.type == "user") | .message.content |
    if type == "array" then map(.text? // "") | join(" ") else . end' 2>/dev/null |
    grep -q '^\[Request interrupted by user'
}

cmd_list() {
  mkdir -p "$DIR"
  local file pid state transcript out=()
  for file in "$DIR"/*.json; do
    [[ -f $file ]] || continue
    pid="$(jq -r '.pid // 0' "$file" 2>/dev/null || echo 0)"
    if ((pid <= 0)) || [[ ! -d /proc/$pid ]]; then
      rm -f "$file"
      continue
    fi
    state="$(jq -r '.state' "$file")"
    transcript="$(jq -r '.transcript // empty' "$file")"
    if [[ $state != idle ]] && interrupted "$transcript"; then
      jq '.state = "idle" | .since = (now | floor)' "$file" >"$file.$$" && mv "$file.$$" "$file"
    fi
    out+=("$file")
  done

  if ((${#out[@]} == 0)); then
    echo '[]'
    return
  fi
  jq -s '
    sort_by(({waiting: 0, working: 1, idle: 2}[.state] // 3), -.since)' "${out[@]}"
}

focus_window() {
  [[ -n $1 ]] || return 1
  hyprctl clients -j | jq -e --arg a "$1" 'any(.[]; .address == $a)' >/dev/null || return 1
  hyprctl dispatch "hl.dsp.focus({ window = \"address:$1\" })" >/dev/null
}

cmd_jump() {
  local file="$DIR/claude-${1:?usage: agent-status jump <session-id>}.json"
  [[ -f $file ]] || file="$DIR/$1.json"
  [[ -f $file ]] || {
    echo "agent-status: no session $1" >&2
    return 1
  }

  local window pane session client
  window="$(jq -r '.window // empty' "$file")"
  pane="$(jq -r '.tmux.pane // empty' "$file")"
  session="$(jq -r '.tmux.session // empty' "$file")"
  client="$(jq -r '.tmux.client // empty' "$file")"

  if [[ -z $pane ]] || ! tmux display-message -p -t "$pane" '' &>/dev/null; then
    # Not in tmux (or the pane is gone): the window is all there is.
    focus_window "$window" || true
    return
  fi

  # Prefer a client already showing the session, then the one the prompt was
  # typed into, then any. Switching that client is what brings the pane up.
  local target
  target="$(tmux list-clients -t "$session" -F '#{client_tty}' 2>/dev/null | head -n1)"
  if [[ -z $target ]] && tmux list-clients -F '#{client_tty}' 2>/dev/null | grep -qxF "$client"; then
    target="$client"
  fi
  [[ -n $target ]] || target="$(tmux list-clients -F '#{client_tty}' 2>/dev/null | head -n1)"

  if [[ -z $target ]]; then
    # No terminal attached to tmux at all: open one on the session.
    tmux select-window -t "$pane" \; select-pane -t "$pane"
    (ghostty -e tmux attach-session -t "$session" &>/dev/null &)
    return
  fi

  tmux switch-client -c "$target" -t "$pane" \; select-window -t "$pane" \; select-pane -t "$pane"
  focus_window "$window" || true
}

case "${1:-}" in
# A hook must never get in the agent's way: whatever happens, exit 0 (exit 2
# would block the tool call).
# AGENT_STATUS_IGNORE opts a session out, e.g. Pathway's headless MCP chats.
hook) [[ -n ${AGENT_STATUS_IGNORE:-} ]] || cmd_hook 2>/dev/null || true ;;
list) cmd_list ;;
jump) cmd_jump "${2:-}" ;;
*)
  echo "usage: agent-status {hook|list|jump <session-id>}" >&2
  exit 2
  ;;
esac
