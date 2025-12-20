{ ... }:

{
  home.file = {
    ".ssh/config".source = ../../dotfiles/ssh/config;

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
