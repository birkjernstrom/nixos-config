# Ghostty terminal configuration
# Theme colors are derived from the active theme
{ config, lib, theme, ... }:

with lib; let
  cfg = config.userSettings.terminal.ghostty;
in
{
  options.userSettings.terminal.ghostty = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Ghostty terminal configuration";
    };

    font = {
      family = mkOption {
        type = types.str;
        default = "BerkeleyMono Nerd Font Mono";
        description = "Font family for Ghostty";
      };
      size = mkOption {
        type = types.int;
        default = 12;
        description = "Font size for Ghostty";
      };
    };
  };

  config = mkIf cfg.enable {
    # Ghostty main config
    home.file.".config/ghostty/config".text = ''
      theme = ${theme.terminal}
      font-family = ${cfg.font.family}
      font-size = ${toString cfg.font.size}
      font-feature = -calt, -liga, -dlig
      cursor-style = block

      window-padding-x = 4,4
      window-padding-y = 4,4
    '';

    # Ghostty theme file - generated from the active theme
    home.file.".config/ghostty/themes/${theme.terminal}".text = theme.ghostty.theme;
  };
}
