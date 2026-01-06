# Ghostty terminal configuration (system-level)
# Installs via homebrew on Darwin, via nixpkgs on NixOS
# Theme colors are derived from the active theme
{ config, lib, pkgs, settings, isDarwin, theme, ... }:

let
  cfg = settings.user.terminal.ghostty or {};
  ghosttyEnabled = cfg.enable or false;
  username = settings.user.name;
  fontFamily = cfg.font.family or "BerkeleyMono Nerd Font Mono";
  fontSize = cfg.font.size or 12;
in
{
  config = if isDarwin then {
    # Darwin: install via homebrew cask
    homebrew.casks = lib.mkIf ghosttyEnabled [ "ghostty" ];
  } else {
    # NixOS/Linux: install via home-manager
    home-manager.users.${username} = lib.mkIf ghosttyEnabled {
      home.packages = [ pkgs.ghostty ];

      # Ghostty main config
      home.file.".config/ghostty/config".text = ''
        theme = ${theme.terminal}
        font-family = ${fontFamily}
        font-size = ${toString fontSize}
        font-feature = -calt, -liga, -dlig
        cursor-style = block

        window-padding-x = 4,4
        window-padding-y = 4,4
      '';

      # Ghostty theme file - generated from the active theme
      home.file.".config/ghostty/themes/${theme.terminal}".text = theme.ghostty.theme;
    };
  };
}
