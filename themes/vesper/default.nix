# Vesper Theme
# https://github.com/nexxeln/vesper.nvim
{ pkgs }:

rec {
  name = "vesper";
  author = "nexxeln";
  polarity = "dark";

  # Neovim configuration
  # Vesper requires a custom plugin (not built into nvf)
  nvim = {
    name = "vesper";
    style = "";
    # Custom plugin for themes not in nvf
    plugin = pkgs.vimUtils.buildVimPlugin {
      pname = "vesper-nvim";
      version = "2025-01-01";
      src = pkgs.fetchFromGitHub {
        owner = "nexxeln";
        repo = "vesper.nvim";
        rev = "bc7b5865613732dfeab89ff6b1da382209cbff2e";
        hash = "sha256-ZJw33+ebe8Eh0NVCk62v+SDG0TgLG8xsTIUsN1cCYa8=";
      };
    };
    # Lua config to load the theme
    config = ''
      require("vesper").setup({
        transparent = false,
      })
      vim.cmd.colorscheme("vesper")
    '';
  };

  # Terminal theme name (for apps like ghostty, wezterm)
  terminal = "vesper";

  # Base16 scheme - mapped from Vesper's palette
  # Vesper is intentionally minimalist with limited accent colors
  base16 = {
    base00 = "101010"; # background
    base01 = "1a1a1a"; # lighter background (elevated)
    base02 = "232323"; # selection background
    base03 = "5c5c5c"; # comments, invisibles
    base04 = "7e7e7e"; # dark foreground (dim)
    base05 = "a0a0a0"; # foreground (muted)
    base06 = "c8c8c8"; # light foreground
    base07 = "ffffff"; # lightest foreground (bright)
    base08 = "ff8080"; # red - errors, deletions
    base09 = "ffc799"; # orange - integers, warnings (accent)
    base0A = "ffc799"; # yellow - classes, search (accent)
    base0B = "99ffe4"; # green - strings, success
    base0C = "99ffe4"; # cyan - support, info
    base0D = "ffc799"; # blue - functions, links (accent)
    base0E = "ffc799"; # purple - keywords, primary accent
    base0F = "a0a0a0"; # deprecated, misc (muted)
  };

  # Cursor configuration
  cursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
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
  # Based on nexxeln's vesper tmux config
  tmux = {
    bg = "#${base16.base00}";           # Primary background
    elevated = "#${base16.base01}";     # Elevated background (messages)
    selected = "#${base16.base02}";     # Selection background
    border = "#${base16.base02}";       # Pane borders
    fg_dim = "#${base16.base03}";       # Dim text (inactive windows)
    fg_muted = "#${base16.base05}";     # Muted text (status bar)
    fg = "#${base16.base07}";           # Primary foreground
    accent = "#${base16.base09}";       # Accent color (session name, active border)
  };

  # Ghostty terminal theme - generated from base16 colors
  ghostty = {
    # Theme file content for ~/.config/ghostty/themes/
    theme = ''
      # ${name} theme - generated from base16

      background = #${base16.base00}
      foreground = #${base16.base07}

      cursor-color = #${base16.base09}

      selection-background = #${base16.base02}
      selection-foreground = #${base16.base07}

      # ANSI Colors (Standard)
      palette = 0=#${base16.base00}
      palette = 1=#${base16.base08}
      palette = 2=#${base16.base0B}
      palette = 3=#${base16.base09}
      palette = 4=#${base16.base05}
      palette = 5=#${base16.base09}
      palette = 6=#${base16.base0B}
      palette = 7=#${base16.base07}

      # Bright Colors
      palette = 8=#${base16.base03}
      palette = 9=#ff9999
      palette = 10=#b3ffe4
      palette = 11=#ffd1a8
      palette = 12=#b0b0b0
      palette = 13=#${base16.base09}
      palette = 14=#66ddcc
      palette = 15=#${base16.base07}
    '';
  };

  # Starship prompt theme - minimal vesper style
  starship = {
    accent = "#${base16.base09}";       # Orange accent
    fg = "#${base16.base05}";           # Muted foreground
    fg_dim = "#${base16.base03}";       # Dim text
    green = "#${base16.base0B}";        # Success
    red = "#${base16.base08}";          # Error
  };
}
