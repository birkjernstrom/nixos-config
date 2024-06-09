{ config, pkgs, ... }:

{
  zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    plugins = [
      {
        name = "vi-mode";
        src = pkgs.zsh-vi-mode;
        file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
      }
    ];
  };

  zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      character = {
        success_symbol = "";
        vicmd_symbol = "";
        error_symbol = ""; 
      };
      directory = {
        style = "blue bold";
      };
    };
  };
}
