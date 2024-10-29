{ config, pkgs, lib, settings, isDarwin, ... }:

let
  zshConfig = import ./zsh.nix { inherit config pkgs lib settings isDarwin; };
  gitConfig = import ./git.nix { inherit config pkgs lib settings isDarwin; };
  tmuxConfig = import ./tmux.nix { inherit config pkgs lib settings isDarwin; };
in
lib.mkMerge [
  gitConfig
  tmuxConfig
  {
    bat.enable = true;
    tmux.enable = true;
    tmux.tmuxp.enable = true;
    ripgrep.enable = true;

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    atuin = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        auto_sync = true;
        filter_mode = "host";
        style = "compact";
      };
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
  zshConfig
]
