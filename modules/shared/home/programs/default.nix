{ config, pkgs, lib, ... }:

let
  gitConfig = import ./git.nix { inherit config pkgs lib; };
in
lib.mkMerge [
  gitConfig
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
        "cd" = "z";

        #  Regular aliases
        ".." = "cd ..";
        "-" = "cd -";
        "ll" = "ls -ahl";

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

      sessionVariables = {
        EDITOR = "nvim";
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
      defaultOptions = [
        "--height 40%"
        "--layout=reverse"
        "--border"
      ];
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

    ###############################################################################
    # Python
    ###############################################################################

    pyenv = {
      enable = true;
      enableZshIntegration = true;
    };

    poetry.enable = true;
  }
]
