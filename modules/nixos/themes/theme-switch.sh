#!/usr/bin/env bash
#
# Packaged by ./default.nix with writeShellApplication, which lints it with
# ShellCheck at build time, prepends `set -euo pipefail`, and puts the tools
# listed in its runtimeInputs on PATH.
#
# Switches the desktop to another theme at runtime. Every program's config
# includes its colours from ~/.local/state/theme/current, a link to one of the
# theme folders built by ./default.nix, so a switch repoints that link and
# tells running programs to re-read it.
#
#   theme-switch <id>        switch to a theme
#   theme-switch --current   print the active theme's id

THEMES="${XDG_DATA_HOME:-$HOME/.local/share}/theme-colors"
CURRENT="${XDG_STATE_HOME:-$HOME/.local/state}/theme/current"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"

# By binary path: Nix wrappers rename the processes (".mako-wrapped").
running() { pgrep -f "/bin/$1( |$)" >/dev/null; }

case "${1:-}" in
--current)
  cat "$CURRENT/name"
  exit
  ;;
"" | -*)
  echo "usage: theme-switch <id> | --current" >&2
  exit 2
  ;;
esac

id="$1"
if [[ ! -f $THEMES/$id/name ]]; then
  ids=("$THEMES"/*)
  echo "theme-switch: no theme '$id'; one of: ${ids[*]##*/}" >&2
  exit 1
fi

mkdir -p "$(dirname "$CURRENT")"
ln -sfn "$THEMES/$id" "$CURRENT.tmp"
mv -T "$CURRENT.tmp" "$CURRENT"

gsettings set org.gnome.desktop.interface color-scheme "'prefer-$(<"$CURRENT/polarity")'" || true

if running Hyprland; then
  hyprctl reload >/dev/null || true
  # Its polarity may have changed, and with it the wallpaper folder.
  wallpaper --restore >/dev/null 2>&1 || true
fi

# Ghostty re-reads its config, theme included, on SIGUSR2.
pkill -USR2 ghostty 2>/dev/null || true

if tmux has-session 2>/dev/null; then
  tmux source-file "$CONFIG/tmux/tmux.conf" >/dev/null || true
fi

if running mako; then
  makoctl reload || true
fi

# GTK loads gtk.css as part of loading its theme, so changing the theme name
# away and back makes running apps load it again.
gtk="$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || true)"
if [[ -n $gtk ]]; then
  gsettings set org.gnome.desktop.interface gtk-theme "'Adwaita'"
  sleep 0.2
  gsettings set org.gnome.desktop.interface gtk-theme "$gtk"
fi

# Quickshell's bar has its own copy of each palette and only needs the id.
qs ipc call theme set "$id" >/dev/null 2>&1 || true

# nvf bakes the default palette into the nvim package; running instances get
# the new one through their RPC sockets, new ones read it at startup.
lua="$(jq -c 'map_values("#" + .)' "$CURRENT/palette.json")"
for sock in "${XDG_RUNTIME_DIR:-/tmp}"/nvim.*.0; do
  [[ -S $sock ]] || continue
  timeout 2 nvim --server "$sock" --remote-expr \
    "luaeval('require(\"base16-colorscheme\").setup(vim.json.decode(_A))', '$lua')" >/dev/null 2>&1 || true
done
