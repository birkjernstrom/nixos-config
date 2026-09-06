#!/usr/bin/env bash
# Regenerates Common/IconMetrics.qml - the ink box of every Nerd Font glyph the
# shell draws.
#
# The glyphs come from three icon sets (Material Design Icons, Font Awesome, and
# whatever else a ramp reaches for) that were never drawn to a shared grid. At
# one font size MDI's battery is 998 font units tall while its wifi fan is 476,
# so a bar built by setting one font size looks assembled from spare parts.
# Widgets/Icon.qml fixes that by scaling each glyph so its longest side matches
# Theme.iconSize, which needs the measurements this script extracts.
#
# Run it after adding or changing a glyph in Common/Icons.qml. Quickshell
# hot-reloads the result; no nixos-rebuild is involved.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
common="$repo/quickshell/Common"

# The same family Theme.fontIcon resolves to, so the numbers describe the font
# actually rendering the bar rather than some other Nerd Font on the system.
family="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["fontIcon"])' "$common/Typography.qml.json")"
font="$(fc-match -f '%{file}' "$family")"

if [ ! -f "$font" ]; then
  echo "gen-icon-metrics: could not resolve a font file for '$family'" >&2
  exit 1
fi

echo "gen-icon-metrics: measuring $family" >&2
echo "gen-icon-metrics:   $font" >&2

nix-shell -p python3Packages.fonttools --run \
  "python3 '$repo/quickshell/tools/gen-icon-metrics.py' '$font' '$common/Icons.qml' '$common/IconMetrics.qml'"

echo "gen-icon-metrics: wrote $common/IconMetrics.qml" >&2
