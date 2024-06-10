{ config, pkgs, lib, ... }:

let
  zshConfig = import ./zsh.nix { inherit config pkgs lib; };
  gitConfig = import ./git.nix { inherit config pkgs lib; };
in
lib.mkMerge [
  zshConfig
  gitConfig
  {
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
