{ ... }:

{
  home.file = {
    ".ssh/config".source = ../../dotfiles/ssh/config;

    # Tmuxp templates
    ".config/tmuxp" = {
      source = ../../dotfiles/tmuxp;
      recursive = true;
    };

    # Ghostty
    ".config/ghostty" = {
      source = ../../dotfiles/ghostty;
      recursive = true;
    };

    # Wezterm
    ".config/wezterm" = {
      source = ../../dotfiles/wezterm;
      recursive = true;
    };
  };
}
