# Catppuccin Mocha Theme
# https://github.com/catppuccin/catppuccin
{ pkgs }:

rec {
  name = "catppuccin-mocha";
  author = "Catppuccin";
  polarity = "dark";

  # Neovim configuration
  # Catppuccin is built into nvf, no custom plugin needed
  nvim = {
    name = "catppuccin";
    style = "mocha";
    plugin = null;
    config = null;
  };

  # Terminal theme name (for apps like ghostty, wezterm)
  terminal = "catppuccin-mocha";

  # Base16 scheme - the single source of truth for colors
  # All other color references should derive from these
  base16 = {
    base00 = "1e1e2e"; # background
    base01 = "181825"; # lighter background
    base02 = "313244"; # selection background
    base03 = "45475a"; # comments, invisibles
    base04 = "585b70"; # dark foreground
    base05 = "cdd6f4"; # foreground
    base06 = "f5e0dc"; # light foreground
    base07 = "b4befe"; # lightest foreground
    base08 = "f38ba8"; # red - errors, deletions
    base09 = "fab387"; # orange - integers, warnings
    base0A = "f9e2af"; # yellow - classes, search
    base0B = "a6e3a1"; # green - strings, success
    base0C = "94e2d5"; # cyan - support, info
    base0D = "89b4fa"; # blue - functions, links
    base0E = "cba6f7"; # purple - keywords, primary accent
    base0F = "f2cdcd"; # deprecated, misc
  };

  # Cursor configuration
  cursor = {
    package = pkgs.catppuccin-cursors.mochaDark;
    name = "catppuccin-mocha-dark-cursors";
    size = 24;
  };

  # Wallpaper
  wallpaper = ../../wallpapers/mountain.png;

  # CSS color definitions derived from base16
  # Uses generic names that map to base16 values
  css = ''
    @define-color bg #${base16.base00};
    @define-color bg-alt #${base16.base01};
    @define-color bg-selection #${base16.base02};
    @define-color bg-subtle #${base16.base03};
    @define-color fg-dim #${base16.base04};
    @define-color fg #${base16.base05};
    @define-color fg-light #${base16.base06};
    @define-color fg-bright #${base16.base07};
    @define-color red #${base16.base08};
    @define-color orange #${base16.base09};
    @define-color yellow #${base16.base0A};
    @define-color green #${base16.base0B};
    @define-color cyan #${base16.base0C};
    @define-color blue #${base16.base0D};
    @define-color purple #${base16.base0E};
    @define-color misc #${base16.base0F};
  '';

  # Tmux theme colors - semantic names for status bar styling
  tmux = {
    bg = "#${base16.base00}";           # Primary background
    elevated = "#${base16.base01}";     # Elevated background (messages)
    selected = "#${base16.base02}";     # Selection background
    border = "#${base16.base02}";       # Pane borders
    fg_dim = "#${base16.base03}";       # Dim text (inactive windows)
    fg_muted = "#${base16.base05}";     # Muted text (status bar)
    fg = "#${base16.base07}";           # Primary foreground
    accent = "#${base16.base0E}";       # Accent color (purple for catppuccin)
  };

  # Ghostty terminal theme - generated from base16 colors
  ghostty = {
    # Theme file content for ~/.config/ghostty/themes/
    theme = ''
      # ${name} theme - generated from base16

      background = #${base16.base00}
      foreground = #${base16.base05}

      cursor-color = #${base16.base0E}

      selection-background = #${base16.base02}
      selection-foreground = #${base16.base05}

      # ANSI Colors (Standard)
      palette = 0=#${base16.base00}
      palette = 1=#${base16.base08}
      palette = 2=#${base16.base0B}
      palette = 3=#${base16.base0A}
      palette = 4=#${base16.base0D}
      palette = 5=#${base16.base0E}
      palette = 6=#${base16.base0C}
      palette = 7=#${base16.base05}

      # Bright Colors
      palette = 8=#${base16.base03}
      palette = 9=#${base16.base08}
      palette = 10=#${base16.base0B}
      palette = 11=#${base16.base0A}
      palette = 12=#${base16.base0D}
      palette = 13=#${base16.base0E}
      palette = 14=#${base16.base0C}
      palette = 15=#${base16.base07}
    '';
  };
}
