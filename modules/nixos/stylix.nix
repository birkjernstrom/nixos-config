{ config, pkgs, theme, ... }:

{
  # Stylix theming - configured via theme from themes/
  stylix = {
    enable = true;
    autoEnable = true;
    polarity = theme.polarity;

    # Color scheme from theme
    base16Scheme = theme.base16;

    # Wallpaper from theme
    image = theme.wallpaper;

    # Font configuration
    fonts = {
      monospace = {
        # Berkeley Mono fonts are installed via fonts/berkleymono.nix from config-private
        name = "Berkeley Mono";
      };
      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };
      serif = {
        package = pkgs.noto-fonts;
        name = "Noto Serif";
      };
      sizes = {
        applications = 11;
        desktop = 11;
        popups = 11;
        terminal = 12;
      };
    };

    cursor = theme.cursor;

    # Target-specific settings
    targets = {
      gtk.enable = true;
      # Disable stylix Qt theming - it doesn't support GNOME's Qt platform
      qt.enable = false;
    };
  };
}
