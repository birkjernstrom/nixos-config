{ config, pkgs, lib, inputs, ... }:

with lib;
{
  imports = [
    ./git.nix
    ./tmux.nix
  ];

  config = {
    home.packages = with pkgs; [
      zsh
      bat
      fzf
      zoxide
      starship
      ripgrep
      atuin
      vim
      neovim
      jq
    ];

    programs = {
      bat.enable = true;
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
          inline_height = 20;
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
    };

    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      shellAliases = {
        #  Regular aliases
        ".." = "cd ..";
        "-" = "cd -";
        "ll" = "ls -ahl";

        # zoxide override
        "cd" = "z";

        # zoxide override
        "cat" = "bat";

        # neovim
        "n" = "nvim";

        # Use zsh after nix develop -- unfortunately from within bash
        # https://github.com/NixOS/nix/issues/4609
        "nixdev" = "nix develop --command zsh";
      };

      sessionVariables = {
        EDITOR = "nvim";
        DISABLE_AUTO_TITLE = "true";
        TERM = "xterm-256color";

        ANTHROPIC_API_KEY = ''$(cat ${config.sops.secrets."anthropic".path})'';
      };
    };
  };
}
