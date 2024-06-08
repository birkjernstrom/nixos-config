{ config, pkgs, ... }:

{
  ".ssh/config".source = ../../../config/ssh/config;
  ".zshrc".source = ../../../config/zsh/zshrc;
  ".gitconfig".source = ../../../config/git/config;
}
