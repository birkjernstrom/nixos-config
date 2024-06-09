{ config, pkgs, ... }:

{
  zsh = {
    enable = true;
    plugins = [
      pkgs.zsh-autosuggestions
      pkgs.zsh-fast-syntax-highlighting
      pkgs.zsh-vi-mode
    ];
  };

  fzf = {
    enable = true;
    enableZshIntegration = true;
  }
}
