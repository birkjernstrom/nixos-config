{ config, pkgs, ... }:

{
  ".ssh/config".source = ../../../dotfiles/ssh/config;
  ".gitconfig".source = ../../../dotfiles/git/config;
  ".gitignore".source = ../../../dotfiles/git/ignore;
}
