#!/usr/bin/env bash
# Regenerates Common/Scheme.qml.json from the Stylix palette.
#
# Quickshell turns any `Foo.qml.json` into a `Foo` singleton, giving every key a
# `readonly property`. Strings shaped like #rrggbb become real `color` values, so
# Scheme.base0E is a color, not a string. Nothing else needs to parse JSON.
#
# Re-run after changing stylix.base16Scheme. Quickshell hot-reloads the result;
# no nixos-rebuild is involved.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
out="$repo/quickshell/Common/Scheme.qml.json"
host="${1:-framework}"

# One eval builds the whole document - nix is lazy, so naming `config` costs nothing
# and this avoids depending on jq being installed.
nix eval --json "$repo#nixosConfigurations.$host.config" --apply '
  cfg:
  let
    c = cfg.lib.stylix.colors.withHashtag;
    isBase = n: builtins.match "base[0-9A-F][0-9A-F]" n != null;
  in
    # Deliberately flat. A nested object here would be synthesized as an object
    # binding on the singleton, which resolves to undefined when another
    # singleton reads it during construction.
    builtins.listToAttrs (
      map (n: { name = n; value = c.${n}; })
        (builtins.filter isBase (builtins.attrNames c))
    ) // {
      fontUi = cfg.stylix.fonts.sansSerif.name;
      fontMono = cfg.stylix.fonts.monospace.name;
      # Nerd Font glyphs (battery/wifi ramps) only render from the patched family.
      fontIcon = "BerkeleyMono Nerd Font Mono";
      fontSize = cfg.stylix.fonts.sizes.desktop;
    }
' | python3 -m json.tool --indent 2 > "$out"

echo "wrote $out"
