#!/usr/bin/env bash
# Regenerates Common/Palette.qml.json from the Stylix palette.
#
# Quickshell turns any `Foo.qml.json` into a `Foo` singleton, giving every key a
# `readonly property`. Strings shaped like #rrggbb become real `color` values, so
# Palette.colors.base0E is a color, not a string. Nothing else needs to parse JSON.
#
# Re-run after changing stylix.base16Scheme. Quickshell hot-reloads the result;
# no nixos-rebuild is involved.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
out="$repo/quickshell/Common/Palette.qml.json"
host="${1:-framework}"

# One eval builds the whole document - nix is lazy, so naming `config` costs nothing
# and this avoids depending on jq being installed.
nix eval --json "$repo#nixosConfigurations.$host.config" --apply '
  cfg:
  let
    c = cfg.lib.stylix.colors.withHashtag;
    isBase = n: builtins.match "base[0-9A-F][0-9A-F]" n != null;
  in {
    colors = builtins.listToAttrs (
      map (n: { name = n; value = c.${n}; })
        (builtins.filter isBase (builtins.attrNames c))
    );
    font = {
      ui = cfg.stylix.fonts.sansSerif.name;
      mono = cfg.stylix.fonts.monospace.name;
      # Nerd Font glyphs (battery/wifi ramps) only render from the patched family.
      icon = "BerkeleyMono Nerd Font Mono";
      size = cfg.stylix.fonts.sizes.desktop;
    };
  }
' | python3 -m json.tool --indent 2 > "$out"

echo "wrote $out"
