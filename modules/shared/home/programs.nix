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
    shellAliases = {
      # zoxide override
      "cd" = "zoxide";

      #  Regular aliases
      ".." = "cd ..";
      "-" = "cd -";

      # zoxide override
      "cat" = "bat";

      # neovim
      "n" = "nvim";
      "v" = "nvim";

      # git
      "g" = "git";
      "gp" = "git push";
      "gpo" = "git push -u origin";
      "gb" = "git branch";
      "gbd" = "git branch -d";
      "gs" = "git status";
      "gc" = "git commit";
      "gd" = "git diff";
    };
  };

  bat.enable = true;

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
