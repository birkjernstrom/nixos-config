{ config, pkgs, ... }:

{
  ".ssh/config".source = ../../../dotfiles/ssh/config;
  ".zshrc".source = ../../../config/zsh/zshrc;
  ".gitconfig".source = ../../../config/git/config;
}
