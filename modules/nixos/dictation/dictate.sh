dir="${XDG_RUNTIME_DIR:-/tmp}/dictate"
wav="$dir/recording.wav"
pidfile="$dir/pw-record.pid"
busy="$dir/transcribing"
mkdir -p "$dir"

bar() {
  qs ipc call dictation "$@" >/dev/null 2>&1 || true
}

fail() {
  bar error "$1"
  notify-send -a Dictation -u critical "Dictation failed" "$1" || true
  exit 1
}

recording() {
  [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null
}

stop_recorder() {
  local pid
  pid="$(cat "$pidfile")"
  rm -f "$pidfile"
  kill -INT "$pid" 2>/dev/null || true
  for _ in $(seq 50); do
    kill -0 "$pid" 2>/dev/null || return 0
    sleep 0.05
  done
  kill -KILL "$pid" 2>/dev/null || true
}

start() {
  recording && return 0
  [ -e "$busy" ] && return 0
  rm -f "$wav"
  pw-record --rate 16000 --channels 1 --format s16 "$wav" >/dev/null 2>&1 &
  echo $! >"$pidfile"
  bar set recording
}

cancel() {
  recording && stop_recorder
  rm -f "$wav"
  bar set idle
}

stop() {
  recording || return 0
  stop_recorder
  touch "$busy"
  trap 'rm -f "$busy" "$wav"' EXIT
  bar set transcribing

  [ -s "$wav" ] || fail "Nothing was recorded"

  local response text
  response="$(curl -sS --fail --max-time 120 \
    -F file=@"$wav" \
    -F temperature=0.0 \
    -F response_format=json \
    "http://127.0.0.1:${DICTATE_PORT}/inference" 2>&1)" \
    || fail "whisper-server: ${response:-no response}"

  text="$(jq -r '.text // empty' <<<"$response" \
    | sed -E 's/\[[A-Z_ ]+\]|\([a-z ]+\)//g' \
    | tr '\n' ' ' \
    | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//')"

  if [ -z "$text" ]; then
    bar set idle
    return 0
  fi

  printf '%s' "$text" | wl-copy
  bar set idle
  wtype -- "$text"
}

case "${1:-toggle}" in
  start) start ;;
  stop) stop ;;
  cancel) cancel ;;
  toggle) if recording; then stop; else start; fi ;;
  *) echo "usage: dictate start|stop|toggle|cancel" >&2; exit 2 ;;
esac
