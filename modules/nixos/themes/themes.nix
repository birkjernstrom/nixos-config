{ pkgs }:

let
  schemes = "${pkgs.base16-schemes}/share/themes";
in
{
  # Also the theme Stylix renders (modules/shared/stylix.nix), for everything
  # that does not switch at runtime.
  default = "kanagawa-dragon";

  # id -> base16 scheme, polarity (default dark) and slot overrides. Keep in
  # step with quickshell/Common/Themes.qml.
  themes = {
    kanagawa-dragon = {
      scheme = "${schemes}/kanagawa-dragon.yaml";
    };
    tokyo-night-storm = {
      scheme = "${schemes}/tokyo-night-storm.yaml";
      # Storm does not follow base16 terminal semantics: its base08 is a pale
      # blue and base0A a cyan. Red and yellow are what errors, warnings and
      # the terminal's ANSI red/yellow should be.
      override = {
        base08 = "f7768e";
        base0A = "ff9e64";
      };
    };
    vesper = {
      # Hand-mapped from the original theme; see the file for why not the
      # base16-schemes one.
      scheme = ../../../quickshell/tools/schemes/vesper.yaml;
    };
    nord = {
      scheme = "${schemes}/nord.yaml";
      # base07 is the terminal's bright white; Nord puts a frost teal there.
      override.base07 = "eceff4";
    };
    grayscale-dark = {
      scheme = "${schemes}/grayscale-dark.yaml";
      # All-grey accents would hide errors and warnings; bring back one muted
      # red and one muted amber.
      override = {
        base08 = "c76b6b";
        base0A = "c9a866";
      };
    };
    rose-pine = {
      scheme = "${schemes}/rose-pine.yaml";
      # base07 (bright white) is a dark grey in the port, and base0A (warnings)
      # the pale rose; use Rosé Pine's text colour and its gold.
      override = {
        base07 = "e0def4";
        base0A = "f6c177";
      };
    };
    rose-pine-dawn = {
      scheme = "${schemes}/rose-pine-dawn.yaml";
      polarity = "light";
      # Same fixes as Rosé Pine: base07 is a pale grey and base0A the rose;
      # use Dawn's text colour and its gold.
      override = {
        base07 = "575279";
        base0A = "ea9d34";
      };
      # Dawn's highlight-high and highlight-med; base03 reads as a pale blue.
      borders = {
        active = "cecacd";
        inactive = "dfdad9";
      };
    };
  };
}
