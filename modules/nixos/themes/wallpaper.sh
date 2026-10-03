#!/usr/bin/env bash
#
# Packaged by ./default.nix with writeShellApplication.
#
# Picks the desktop wallpaper from wallpapers/{dark,light}/, remembering one
# choice per polarity so switching theme brings back the matching wallpaper.
#
#   wallpaper set <path>       remember <path> for its polarity, show it if current
#   wallpaper --restore        show the remembered wallpaper for the current polarity
#   wallpaper --list [pol]     list the images for a polarity
#   wallpaper --current [pol]  print the remembered wallpaper for a polarity

DIR="${XDG_DATA_HOME:-$HOME/.local/share}/wallpapers"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper"
POLARITY_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/wallpaper/polarity"

polarity() {
  local p=""
  [[ -f $POLARITY_FILE ]] && p="$(<"$POLARITY_FILE")"
  echo "${p:-dark}"
}

list() {
  [[ -d $DIR/$1 ]] || return 0
  find -L "$DIR/$1" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort
}

current() {
  local path=""
  [[ -f $STATE_DIR/$1 ]] && path="$(<"$STATE_DIR/$1")"
  if [[ -z $path || ! -f $path ]]; then
    path="$(list "$1" | head -n1)"
  fi
  echo "$path"
}

apply() {
  export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$UID}"
  if [[ -z ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
    local instance
    for instance in "$XDG_RUNTIME_DIR"/hypr/*/; do
      [[ -S $instance.socket.sock ]] && HYPRLAND_INSTANCE_SIGNATURE="$(basename "$instance")"
    done
    export HYPRLAND_INSTANCE_SIGNATURE
  fi

  # Called as hyprpaper's ExecStartPost, before its socket is necessarily up.
  local _
  for _ in $(seq 20); do
    hyprctl hyprpaper wallpaper ",$1" >/dev/null 2>&1 && return 0
    sleep 0.25
  done
  echo "wallpaper: could not reach hyprpaper" >&2
  return 1
}

case "${1:-}" in
set)
  path="$(realpath -s "${2:?usage: wallpaper set <path>}")"
  [[ -f $path ]] || {
    echo "wallpaper: no such file '$path'" >&2
    exit 1
  }
  pol="$(basename "$(dirname "$path")")"
  [[ $pol == dark || $pol == light ]] || pol="$(polarity)"
  mkdir -p "$STATE_DIR"
  echo "$path" >"$STATE_DIR/$pol.tmp" && mv "$STATE_DIR/$pol.tmp" "$STATE_DIR/$pol"
  if [[ $pol == "$(polarity)" ]]; then
    apply "$path"
  fi
  ;;
--restore)
  path="$(current "$(polarity)")"
  if [[ -n $path ]]; then
    apply "$path"
  fi
  ;;
--list)
  list "${2:-$(polarity)}"
  ;;
--current)
  current "${2:-$(polarity)}"
  ;;
*)
  echo "usage: wallpaper set <path> | --restore | --list [dark|light] | --current [dark|light]" >&2
  exit 2
  ;;
esac
