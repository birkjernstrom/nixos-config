{ ... }:

{
  home.file = {
    ".ssh/config".source = ../../dotfiles/ssh/config;

    # Wezterm
    ".config/wezterm" = {
      source = ../../dotfiles/wezterm;
      recursive = true;
    };
  };
}
