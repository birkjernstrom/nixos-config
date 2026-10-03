#!/usr/bin/env bash
#
# Packaged by ./default.nix with writeShellApplication, which lints it with
# ShellCheck at build time, prepends `set -euo pipefail`, and puts the tools
# listed in its runtimeInputs on PATH.
#
# Switches the whole desktop to another theme at runtime, no rebuild or sudo.
#
# Every theme is a complete home-manager build made ahead of time: the default
# is the base generation, the others are its specialisations (see
# ./default.nix), each with Stylix pointed at a different scheme. Switching is
# activating one of those, which rewrites every Stylix-generated file at once
# - GTK, Ghostty, Hyprland, tmux, mako, hyprlock, bat, btop, zathura and the
# rest - and then nudging the programs already running to re-read them.
#
#   theme-switch <id>        activate a theme and remember it
#   theme-switch --restore   re-apply the remembered theme (base activation)
#   theme-switch --current   print the remembered theme's id

DEFAULT="@default@"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/theme-switch"
STATE="$STATE_DIR/current"

# The base generation is what the NixOS-managed home-manager service activates,
# so it is always the current system's - unlike ~/.local/state/home-manager's
# link, which points at whatever was activated last, specialisations included.
base_generation() {
  grep -o '/nix/store/[^ ]*-home-manager-generation' \
    "/etc/systemd/system/home-manager-$USER.service" | tail -n1
}

current() {
  local id=""
  [[ -f $STATE ]] && id="$(<"$STATE")"
  echo "${id:-$DEFAULT}"
}

# Programs that read their theme once at startup keep it until told otherwise.
# Everything else (hyprlock, bat, btop, zathura, ...) picks the new files up the
# next time it starts.
reload_running() {
  # --restore runs from the home-manager system service during a rebuild, which
  # has none of the session's environment. Point at the session's own runtime
  # dir, bus and compositor so the running programs still get told.
  export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$UID}"
  export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"
  if [[ -z ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
    local instance
    for instance in "$XDG_RUNTIME_DIR"/hypr/*/; do
      [[ -S $instance.socket.sock ]] && HYPRLAND_INSTANCE_SIGNATURE="$(basename "$instance")"
    done
    export HYPRLAND_INSTANCE_SIGNATURE
  fi

  # Colours and borders are in the regenerated config.
  hyprctl reload >/dev/null 2>&1 || true

  # Ghostty re-reads its config, theme included, on SIGUSR2. Not `pkill -x`:
  # the Nix wrapper's process name is ".ghostty-wrappe".
  pkill -USR2 ghostty 2>/dev/null || true

  # GTK loads ~/.config/gtk-{3,4}.0/gtk.css as part of loading its theme, so
  # changing the theme name away and back makes running apps load it again.
  local gtk
  gtk="$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || true)"
  if [[ -n $gtk ]]; then
    gsettings set org.gnome.desktop.interface gtk-theme "'Adwaita'"
    sleep 0.2
    gsettings set org.gnome.desktop.interface gtk-theme "$gtk"
  fi

  tmux source-file "${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf" >/dev/null 2>&1 || true
  makoctl reload >/dev/null 2>&1 || true

  # The theme's polarity may have changed, and with it the wallpaper folder.
  wallpaper --restore >/dev/null 2>&1 || true

  # nvf bakes the palette into the nvim package, which only new instances run,
  # so hand running ones the new palette through their RPC sockets.
  local palette="${XDG_CONFIG_HOME:-$HOME/.config}/stylix/palette.json" lua sock
  if [[ -f $palette ]]; then
    lua="$(jq -c 'with_entries(select(.key | test("^base0[0-9A-F]$")) | .value = "#" + .value)' "$palette")"
    for sock in "${XDG_RUNTIME_DIR:-/tmp}"/nvim.*.0; do
      [[ -S $sock ]] || continue
      timeout 2 nvim --server "$sock" --remote-expr \
        "luaeval('require(\"base16-colorscheme\").setup(vim.json.decode(_A))', '$lua')" >/dev/null 2>&1 || true
    done
  fi
}

activate() {
  local id="$1" base target
  base="$(base_generation)"
  [[ -n $base ]] || {
    echo "theme-switch: cannot find the home-manager generation" >&2
    return 1
  }
  if [[ $id == "$DEFAULT" ]]; then
    target="$base"
  else
    target="$base/specialisation/$id"
  fi
  [[ -x $target/activate ]] || {
    echo "theme-switch: no theme '$id' in $base" >&2
    return 1
  }
  "$target/activate" >/dev/null
}

case "${1:-}" in
--current)
  current
  ;;
--restore)
  # Called from the base generation's own activation (boot, nixos-rebuild),
  # which has just put the default theme back. Nothing to do if that is the
  # one remembered.
  id="$(current)"
  [[ $id == "$DEFAULT" ]] && exit 0
  activate "$id" && reload_running
  ;;
"" | -*)
  echo "usage: theme-switch <id> | --restore | --current" >&2
  exit 2
  ;;
*)
  mkdir -p "$STATE_DIR"
  # Remember first: the base activation's restore hook reads this, and the
  # default theme is itself an activation of the base generation.
  echo "$1" >"$STATE.tmp" && mv "$STATE.tmp" "$STATE"
  activate "$1"
  reload_running
  ;;
esac
