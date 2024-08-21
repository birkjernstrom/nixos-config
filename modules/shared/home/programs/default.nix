{ config, pkgs, lib, ... }:

{
  imports = [
    ./zsh.nix
    ./git.nix
    ./tmux.nix
  ];

  config = {
    programs = {
      bat.enable = true;
      tmux.enable = true;
      tmux.tmuxp.enable = true;
      ripgrep.enable = true;

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
    };
  };
}
