{ config, pkgs, lib, ... }:

with lib; let
  cfg = config.userSettings.cli.core;
in
{
  options.userSettings.cli.core.enable = mkOption {
    type = types.bool;
    default = true;
    description = "Enable core CLI tools (bat, fzf, ripgrep, zoxide, starship, etc.)";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      bat
      fzf
      tree
      htop
      httpie
      zoxide
      starship
      ripgrep
      sesh
      atuin
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
            success_symbol = "";
            vicmd_symbol = "";
            error_symbol = "";
          };
          directory = {
            style = "blue bold";
          };
        };
      };
    };
  };
}
