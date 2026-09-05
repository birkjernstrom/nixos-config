#!/usr/bin/env bash
# Regenerates the theme palettes in Common/themes/ and Common/Typography.qml.json.
#
# Quickshell turns any `Foo.qml.json` into a `Foo` singleton, giving every key a
# `readonly property`. Strings shaped like #rrggbb become real `color` values, so
# TokyoNightStorm.base0E is a color, not a string, and nothing parses JSON at runtime.
#
# Palettes are read straight out of the base16-schemes package rather than from
# the live Stylix config, so any of its ~300 schemes can be added by appending to
# SCHEMES below and adding one line to Common/Themes.qml. Only base00-base0F are
# emitted: Theme.qml never reads the base10-base17 slots, and those are a Stylix
# base24 extension that the raw scheme files do not define anyway.
#
# Fonts stay owned by Stylix - they are theme-independent.
#
# Quickshell hot-reloads the result; no nixos-rebuild is involved.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
out="$repo/quickshell/Common"
host="${1:-framework}"

SCHEMES=(kanagawa-dragon tokyo-night-storm)

schemes_dir="$(nix eval --raw "$repo#nixosConfigurations.$host.pkgs.base16-schemes")/share/themes"

mkdir -p "$out/themes"

for scheme in "${SCHEMES[@]}"; do
  src="$schemes_dir/$scheme.yaml"
  [ -f "$src" ] || { echo "no such scheme: $src" >&2; exit 1; }

  # PascalCase: tokyo-night-storm -> TokyoNightStorm. Quickshell only registers
  # files whose name starts with an uppercase letter.
  name="$(echo "$scheme" | awk -F- '{ for (i=1;i<=NF;i++) printf toupper(substr($i,1,1)) substr($i,2); }')"

  # The scheme files are rigidly formatted (`  base00: "#24283B"`), so a regex
  # beats taking a pyyaml dependency - and there is no jq on this system.
  python3 - "$src" "$out/themes/$name.qml.json" <<'PY'
import json, re, sys

src, dest = sys.argv[1], sys.argv[2]
slots = dict(re.findall(r'^\s*(base0[0-9A-F]):\s*"?#?([0-9a-fA-F]{6})"?\s*$',
                        open(src).read(), re.M))
if len(slots) != 16:
    sys.exit(f"{src}: expected 16 base00-base0F slots, found {len(slots)}")

palette = {k: "#" + slots[k].lower() for k in sorted(slots)}
with open(dest, "w") as f:
    json.dump(palette, f, indent=2)
    f.write("\n")
PY
  echo "wrote $out/themes/$name.qml.json"
done

nix eval --json "$repo#nixosConfigurations.$host.config.stylix.fonts" --apply '
  f: {
    fontUi = f.sansSerif.name;
    fontMono = f.monospace.name;
    # Nerd Font glyphs (battery/wifi ramps) only render from the patched family.
    fontIcon = "BerkeleyMono Nerd Font Mono";
    fontSize = f.sizes.desktop;
  }
' | python3 -m json.tool --indent 2 > "$out/Typography.qml.json"

echo "wrote $out/Typography.qml.json"
