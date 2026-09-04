# Central theming - the single source of truth for colours and fonts.
#
# Nothing outside of this file (and its NixOS companion,
# modules/nixos/stylix.nix) should hardcode a colour. Modules either let a
# Stylix target style the program for them, or - when only layout-level CSS
# needs a colour - read it back from `config.lib.stylix.colors`.
#
# To switch theme, point `base16Scheme` at any other scheme in
# `${pkgs.base16-schemes}/share/themes`.
{ pkgs, ... }:

{
  stylix = {
    enable = true;

    # Style every supported program by default. Individual programs opt out
    # via `stylix.targets.<name>.enable = false` next to their own config.
    autoEnable = true;

    polarity = "dark";

    # Kanagawa Dragon - the warm, desaturated variant of Kanagawa.
    #
    # It follows base16 terminal semantics: base08 is red, base0B green,
    # base0D blue, base0E purple. So errors, urgent workspaces and failed
    # unlock attempts all render in the colour they should.
    base16Scheme = "${pkgs.base16-schemes}/share/themes/kanagawa-dragon.yaml";

    fonts = {
      monospace = {
        # Berkeley Mono is installed via modules/nixos/fonts/berkleymono.nix
        # from config-private.
        name = "Berkeley Mono";
      };
      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };
      serif = {
        package = pkgs.noto-fonts;
        name = "Noto Serif";
      };
      sizes = {
        applications = 11;
        # The Quickshell bar renders at this size.
        desktop = 10;
        popups = 11;
        terminal = 12;
      };
    };
  };
}
