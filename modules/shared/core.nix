{ config, pkgs, lib, theme, ... }:

with lib; let
  cfg = config.userSettings.cli.core;
  colors = theme.starship;
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
      btop
      fastfetch
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
          format = "$directory$git_branch$git_status$character";
          right_format = "$cmd_duration";

          character = {
            success_symbol = "[❯](${colors.accent})";
            error_symbol = "[❯](${colors.red})";
            vimcmd_symbol = "[❮](${colors.accent})";
          };

          directory = {
            style = "${colors.fg}";
            truncation_length = 3;
            truncate_to_repo = true;
          };

          git_branch = {
            format = "[$symbol$branch]($style) ";
            style = "${colors.fg_dim}";
            symbol = "";
          };

          git_status = {
            format = "[$all_status$ahead_behind]($style)";
            style = "${colors.accent}";
            conflicted = "=";
            ahead = "⇡";
            behind = "⇣";
            diverged = "⇕";
            untracked = "?";
            stashed = "$";
            modified = "!";
            staged = "+";
            renamed = "»";
            deleted = "✘";
          };

          cmd_duration = {
            format = "[$duration]($style)";
            style = "${colors.fg_dim}";
            min_time = 2000;
          };
        };
      };
    };
  };
}
