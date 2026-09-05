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
      btop
      fastfetch
      httpie
      jq
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
        # Colour names below resolve through the base16 palette that Stylix
        # installs into Starship, so the prompt follows the active theme.
        settings = {
          format = "$directory$git_branch$git_status$character";
          right_format = "$cmd_duration";

          character = {
            success_symbol = "[❯](blue)";
            error_symbol = "[❯](red)";
            vimcmd_symbol = "[❮](blue)";
          };

          directory = {
            style = "white";
            truncation_length = 3;
            truncate_to_repo = true;
          };

          git_branch = {
            format = "[$symbol$branch]($style) ";
            style = "bright-black";
            symbol = "";
          };

          git_status = {
            format = "[$all_status$ahead_behind]($style)";
            style = "blue";
            conflicted = "=";
            ahead = "⇡";
            behind = "⇣";
            diverged = "⇕";
            untracked = "?";
            # Escaped: these values are format strings, so a bare `$` is read
            # as the start of a variable reference and fails to parse.
            stashed = "\\$";
            modified = "!";
            staged = "+";
            renamed = "»";
            deleted = "✘";
          };

          cmd_duration = {
            format = "[$duration]($style)";
            style = "bright-black";
            min_time = 2000;
          };
        };
      };
    };
  };
}
