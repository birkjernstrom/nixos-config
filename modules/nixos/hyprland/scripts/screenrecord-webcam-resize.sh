#!/usr/bin/env bash
#
# Packaged by ../screenrecord.nix with writeShellApplication (see
# screenrecord.sh). Ported from Omarchy's omarchy-capture-webcam-resize: steps
# the webcam overlay between the small/medium/large presets (8:9 portrait,
# scaled from the recorded area's height), anchored to its bottom-right corner.

# Usage: screenrecord-webcam-resize <smaller|larger|small|medium|large>
MARGIN=40
REGION_FILE="${XDG_RUNTIME_DIR:-/tmp}/screenrecord-region"
action="${1:-}"
case $action in
smaller | larger | small | medium | large) ;;
*) echo "Usage: screenrecord-webcam-resize <smaller|larger|small|medium|large>" >&2; exit 1 ;;
esac

client="$(hyprctl clients -j | jq -c 'first(.[] | select(.title == "WebcamOverlay")) // empty')"
[[ -n $client ]] || exit 0
read -r address cur_w cur_h monitor_id < <(jq -r '[.address, .size[0], .size[1], .monitor] | @tsv' <<<"$client")

read -r ax ay aw ah < <(hyprctl monitors -j | jq -r --argjson id "$monitor_id" '.[] | select(.id == $id) |
  (if (.transform % 2) == 1 then [.height, .width] else [.width, .height] end) as $size |
  [.x, .y, ($size[0] / .scale | floor), ($size[1] / .scale | floor)] | @tsv')
if [[ -f $REGION_FILE ]] && [[ "$(<"$REGION_FILE")" =~ ^([0-9]+)x([0-9]+)\+(-?[0-9]+)\+(-?[0-9]+)$ ]]; then
  aw="${BASH_REMATCH[1]}" ah="${BASH_REMATCH[2]}" ax="${BASH_REMATCH[3]}" ay="${BASH_REMATCH[4]}"
fi

# A tall, narrow region can't fit presets scaled from its own height.
scale_h=$ah
avail_w=$((aw - 2 * MARGIN))
((avail_w > 0 && scale_h * 3 / 10 > avail_w)) && scale_h=$((avail_w * 10 / 3))

small_h=$(((scale_h * 9 + 25) / 50));  small_w=$(((small_h * 8 + 4) / 9))
medium_h=$(((scale_h + 2) / 4));       medium_w=$(((medium_h * 8 + 4) / 9))
large_h=$(((scale_h * 27 + 40) / 80)); large_w=$(((large_h * 8 + 4) / 9))

w=$cur_w h=$cur_h
case $action in
small) w=$small_w h=$small_h ;;
medium) w=$medium_w h=$medium_h ;;
large) w=$large_w h=$large_h ;;
smaller)
  if ((large_w < cur_w)); then w=$large_w h=$large_h
  elif ((medium_w < cur_w)); then w=$medium_w h=$medium_h
  elif ((small_w < cur_w)); then w=$small_w h=$small_h
  fi ;;
larger)
  if ((small_w > cur_w)); then w=$small_w h=$small_h
  elif ((medium_w > cur_w)); then w=$medium_w h=$medium_h
  elif ((large_w > cur_w)); then w=$large_w h=$large_h
  fi ;;
esac

x=$((ax + aw - w - MARGIN)) y=$((ay + ah - h - MARGIN))
((x < ax + MARGIN)) && x=$((ax + MARGIN))
((y < ay + MARGIN)) && y=$((ay + MARGIN))

win="address:$address"
hyprctl dispatch "hl.dsp.window.resize({ window = \"$win\", x = $w, y = $h })" >/dev/null
hyprctl dispatch "hl.dsp.window.move({ window = \"$win\", x = $x, y = $y })" >/dev/null
