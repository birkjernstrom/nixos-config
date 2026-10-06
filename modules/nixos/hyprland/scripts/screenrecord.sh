#!/usr/bin/env bash
#
# Packaged by ../screenrecord.nix with writeShellApplication, which lints it
# with ShellCheck at build time, prepends `set -euo pipefail`, and puts the tools
# listed in its runtimeInputs on PATH.
#
# Keep REGION_FILE in sync with screenrecord-webcam-resize.sh: it tells the
# overlay which region is being recorded, so it anchors to that corner.

# Usage: screenrecord [--with-webcam] [--webcam-size=small|medium|large]
# Starts a recording (mic audio, region/window/monitor picked with slurp),
# or stops the one already running. With several cameras connected, Pathway
# asks which one to overlay once the region is picked.

WEBCAM=false
WEBCAM_SIZE=medium
for arg in "$@"; do
  case "$arg" in
  --with-webcam) WEBCAM=true ;;
  --webcam-size=*) WEBCAM_SIZE="${arg#*=}" ;;
  esac
done

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
RECORDING_FILE="$RUNTIME_DIR/screenrecord-filename"
REGION_FILE="${XDG_RUNTIME_DIR:-/tmp}/screenrecord-region"
WEBCAM_CHOICE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/screenrecord/webcam"
OUTPUT_DIR="$(xdg-user-dir VIDEOS 2>/dev/null || echo "$HOME/Videos")"
[[ $OUTPUT_DIR == "$HOME" ]] && OUTPUT_DIR="$HOME/Videos"

notify() { notify-send -a "Screen recording" "$@"; }

# Matches the recorder whether it was started by bare name or, as on NixOS, as
# /nix/store/.../bin/.wrapped/gpu-screen-recorder - Omarchy's "^gpu-screen-recorder"
# only matches the former, so every press here used to start another recording.
RECORDER='(^|/)gpu-screen-recorder '

recording_active() { pgrep -f "$RECORDER" >/dev/null; }

# Echoes "DEVICE<TAB>NAME" per usable camera, the IPU7 relay's loopback camera
# first. The raw IPU capture nodes are skipped (they're capture-capable but carry
# unprocessed Bayer data), as are metadata-only nodes like a UVC camera's second.
list_webcams() {
  local node name dev preferred="" others=""
  for node in /sys/class/video4linux/video*; do
    [[ -e $node/name ]] || continue
    name="$(<"$node/name")"
    name="${name%"${name##*[![:space:]]}"}"
    dev="/dev/${node##*/}"
    [[ $name == "Intel IPU"* ]] && continue
    if [[ $name == "Intel MIPI Camera" ]]; then
      preferred+="$dev"$'\t'"$name"$'\n'
    elif v4l2-ctl -d "$dev" --info 2>/dev/null |
      awk '/Device Caps/ { inspect = 1; next } inspect && /Video Capture/ { found = 1 } END { exit !found }'; then
      others+="$dev"$'\t'"$name"$'\n'
    fi
  done
  printf '%s%s' "$preferred" "$others"
}

# Echoes the camera device to overlay. The last pick is listed first, so
# Enter repeats it; Escape in the picker cancels the recording.
choose_webcam() {
  local cameras last dev name ordered="" rest="" fifo reply
  cameras="$(list_webcams)"
  if [[ -z $cameras ]]; then
    notify -u critical -t 3000 "No webcam found"
    return 1
  fi
  if (($(wc -l <<<"$cameras") == 1)); then
    cut -f1 <<<"$cameras"
    return
  fi

  last="$(cat "$WEBCAM_CHOICE_FILE" 2>/dev/null || true)"
  while IFS=$'\t' read -r dev name; do
    if [[ -z $ordered && $name == "$last" ]]; then
      ordered="$dev"$'\t'"$name"$'\t'"Last used"$'\n'
    else
      rest+="$dev"$'\t'"$name"$'\t'"${dev#/dev/}"$'\n'
    fi
  done <<<"$cameras"

  fifo="$RUNTIME_DIR/screenrecord-webcam-pick"
  rm -f "$fifo"
  mkfifo "$fifo"
  if ! qs ipc call pathway webcam "$ordered$rest" "$fifo" >/dev/null; then
    rm -f "$fifo"
    notify -u critical -t 3000 "Couldn't open the webcam picker"
    return 1
  fi
  reply="$(timeout 120 head -n1 "$fifo" || true)"
  rm -f "$fifo"
  [[ $reply == =/dev/* ]] || return 1
  dev="${reply#=}"

  name="$(awk -F'\t' -v dev="$dev" '$1 == dev { print $2; exit }' <<<"$cameras")"
  mkdir -p "${WEBCAM_CHOICE_FILE%/*}"
  echo "$name" >"$WEBCAM_CHOICE_FILE"
  echo "$dev"
}

# Echoes "monitor:NAME" when the selection is a whole monitor (captured
# natively), otherwise "region:WxH+X+Y" in logical coordinates. Clicking
# a window selects it, clicking the desktop selects the monitor, dragging
# selects a region.
select_target() {
  local monitors boxes selection
  monitors="$(hyprctl monitors -j | jq -r '.[] |
    (if (.transform % 2) == 1 then [.height, .width] else [.width, .height] end) as $size |
    "\(.x),\(.y) \($size[0] / .scale | floor)x\($size[1] / .scale | floor) \(.name)"')"
  boxes="$(hyprctl clients -j | jq -r --argjson ws "$(hyprctl monitors -j | jq '[.[].activeWorkspace.id]')" \
    '.[] | select(.mapped and (.hidden | not) and (.workspace.id as $id | $ws | index($id))) |
    "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')"
  selection="$(printf '%s\n%s\n' "$boxes" "$(cut -d' ' -f1,2 <<<"$monitors")" | slurp -f '%x,%y %wx%h')" || return 1

  local x y w h name
  while read -r geometry size name; do
    if [[ "$geometry $size" == "$selection" ]]; then
      echo "monitor:$name"
      return
    fi
  done <<<"$monitors"

  [[ $selection =~ ^(-?[0-9]+),(-?[0-9]+)\ ([0-9]+)x([0-9]+)$ ]] || return 1
  x="${BASH_REMATCH[1]}" y="${BASH_REMATCH[2]}" w="${BASH_REMATCH[3]}" h="${BASH_REMATCH[4]}"
  echo "region:${w}x${h}+${x}+${y}"
}

cleanup_webcam() {
  pkill -f -- "--wayland-app-id=WebcamOverlay" 2>/dev/null || true
  rm -f "$REGION_FILE"
}

start_webcam() {
  local device="$2"
  mpv "av://v4l2:$device" \
    --profile=low-latency --untimed --no-cache \
    --demuxer-lavf-o=framerate=30 \
    '--vf=lavfi=[crop=ih*8/9:ih]' \
    --title=WebcamOverlay --wayland-app-id="WebcamOverlay-$WEBCAM_SIZE" \
    --no-border --no-audio --no-osc --osd-level=0 \
    --really-quiet &>/dev/null &

  # Let the window map and settle in its corner before recording starts,
  # or the camera is recorded sliding into place.
  local waited=0
  while ((waited < 40)) && ! hyprctl clients -j | jq -e 'any(.[]; .title == "WebcamOverlay")' >/dev/null 2>&1; do
    sleep 0.05
    waited=$((waited + 1))
  done
  [[ $1 == region:* ]] && echo "${1#region:}" >"$REGION_FILE"
  screenrecord-webcam-resize "$WEBCAM_SIZE"
  sleep 0.6
}

start_recording() {
  mkdir -p "$OUTPUT_DIR"
  local target
  target="$(select_target)" || return 1

  local capture_args
  case $target in
  monitor:*) capture_args=(-w "${target#monitor:}") ;;
  region:*) capture_args=(-w "${target#region:}") ;;
  esac

  if [[ $WEBCAM == true ]]; then
    local device
    device="$(choose_webcam)" || return 1
    start_webcam "$target" "$device" || return 1
  fi

  local filename
  filename="$OUTPUT_DIR/screenrecording-$(date +'%Y-%m-%d_%H-%M-%S').mp4"
  gpu-screen-recorder "${capture_args[@]}" -k auto -f 60 -fm cfr -fallback-cpu-encoding yes \
    -a default_input -ac aac -o "$filename" &>/dev/null &
  local pid=$!

  while kill -0 "$pid" 2>/dev/null && [[ ! -f $filename ]]; do
    sleep 0.2
  done
  if kill -0 "$pid" 2>/dev/null; then
    echo "$filename" >"$RECORDING_FILE"
  else
    notify -u critical -t 5000 "Screen recording failed to start"
    return 1
  fi
}

# Trim the first frame, and normalize the mic to -14 LUFS with the
# PipeWire capture-open pop in the first 400ms muted.
finalize_recording() {
  local file="$1" video_codec=(-c:v copy)
  # Stream copy can't drop discardable warmup packets in the first GOP.
  if ffprobe -v error -select_streams v:0 -read_intervals %+0.2 -show_entries packet=flags -of csv=p=0 "$file" 2>/dev/null | grep -q D; then
    video_codec=(-c:v libx264 -preset veryfast -crf 20)
  fi
  local args=(-y -ss 0.1 -i "$file" "${video_codec[@]}")
  if ffprobe -v error -select_streams a -show_entries stream=codec_type -of csv=p=0 "$file" 2>/dev/null | grep -q audio; then
    args+=(-af "volume=enable='lt(t,0.4)':volume=0,afade=t=in:st=0.4:d=0.05,loudnorm=I=-14:TP=-1.5:LRA=11")
  fi
  local processed="${file%.mp4}-processed.mp4"
  if ffmpeg "${args[@]}" "$processed" -loglevel quiet; then
    mv "$processed" "$file"
  else
    rm -f "$processed"
  fi
}

stop_recording() {
  # SIGINT, so the MP4 is finalized properly.
  pkill -SIGINT -f "$RECORDER" || true
  local count=0
  while recording_active && ((count < 50)); do
    sleep 0.1
    count=$((count + 1))
  done
  cleanup_webcam

  local file
  file="$(cat "$RECORDING_FILE" 2>/dev/null || true)"
  rm -f "$RECORDING_FILE"

  if recording_active; then
    pkill -9 -f "$RECORDER" || true
    notify -u critical -t 5000 "Screen recording error" "Recording had to be force-killed. Video may be corrupted."
    return 1
  fi
  [[ -f $file ]] || return 0

  finalize_recording "$file"
  local preview="${file%.mp4}-preview.png"
  ffmpeg -y -i "$file" -ss 00:00:00.1 -vframes 1 -q:v 2 "$preview" -loglevel quiet || true

  # Clicking the notification plays the recording.
  (
    action="$(notify -t 10000 -i "$preview" -A default=Play "Screen recording saved" "${file##*/}")"
    rm -f "$preview"
    [[ $action == default ]] && mpv "$file"
  ) &>/dev/null &
}

if recording_active; then
  stop_recording
else
  start_recording || cleanup_webcam
fi
