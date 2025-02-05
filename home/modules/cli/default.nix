{ config, pkgs, lib, inputs, ... }:

with lib;
{
  imports = [
    ./git.nix
    ./zsh.nix
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
    ];

    programs = {
      bat.enable = true;
      ripgrep.enable = true;

      zoxide = {
        enable = true;
        enableZshIntegration = config.features.cli.zsh.enable;
      };

      atuin = {
        enable = true;
        enableZshIntegration = config.features.cli.zsh.enable;
        settings = {
          auto_sync = true;
          filter_mode = "host";
          style = "compact";
          inline_height = 20;
        };
      };

      starship = {
        enable = true;
        enableZshIntegration = config.features.cli.zsh.enable;
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

    programs.zsh = mkIf config.features.cli.zsh.enable {
      shellAliases = {
        # zoxide override
        "cd" = "z";

        # zoxide override
        "cat" = "bat";

        # neovim
        "n" = "nvim";
      };
    };
  };
}
