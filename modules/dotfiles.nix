# Hand-written config files that have no home-manager module worth using.
#
# Sourced from dotfiles/ at the repo root, so they stay editable as plain files.
{
  flake.modules.homeManager.base = {
    home.file = {
      ".ssh/config".source = ../dotfiles/ssh/config;

      # Wezterm
      ".config/wezterm" = {
        source = ../dotfiles/wezterm;
        recursive = true;
      };
    };
  };
}
