# Theme configuration and selection
#
# To add a new theme:
# 1. Create a directory: themes/<theme-name>/default.nix
# 2. Define base16 colors and other required attributes
# 3. Add to the `themes` attribute set below
#
# Usage in modules:
#   theme.base16.base00  - background color
#   theme.css            - CSS variable definitions
#   theme.cursor         - cursor package and settings
#
{ pkgs }:

let
  # Available themes
  themes = {
    catppuccin-mocha = import ./catppuccin-mocha { inherit pkgs; };
    # Add more themes here:
    # tokyo-night = import ./tokyo-night { inherit pkgs; };
    # gruvbox = import ./gruvbox { inherit pkgs; };
  };

  # Select the active theme here
  selected = "catppuccin-mocha";

in themes.${selected}
