{ config, pkgs, ... }:

{
  ".ssh/config".source = ../../../dotfiles/ssh/config;

  # Prefer to configure nvim directly with lua
  ".config/nvim" = {
    source = ../../../dotfiles/nvim;
    recursive = true;
  };

  # Wezterm
  ".config/wezterm" = {
    source = ../../../dotfiles/wezterm;
    recursive = true;
  };
}
