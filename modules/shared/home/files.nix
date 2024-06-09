{ config, pkgs, ... }:

{
  ".ssh/config".source = ../../../dotfiles/ssh/config;
  ".gitconfig".source = ../../../dotfiles/git/config;
  ".gitignore".source = ../../../dotfiles/git/ignore;

  # Prefer to configure nvim directly with lua
  ".config/nvim" = {
    source = ../../../dotfiles/nvim;
    recursive = true;
  };
}
