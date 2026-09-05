# Linux-only theming, layered on top of modules/theme.nix.
{
  flake.modules.nixos.desktop = { pkgs, ... }: {
    stylix = {
      # Wallpaper. Only used as the desktop background - colours come from
      # `base16Scheme`, not from this image.
      image = ../../wallpapers/polar_01.jpg;

      cursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Classic";
        size = 24;
      };

      # Stylix's Qt theming doesn't support GNOME's Qt platform.
      targets.qt.enable = false;
    };

    # The Qt target exists separately in home-manager and is *not* inherited
    # from the system setting above, so it has to be turned off here too.
    # Left on, it writes a Kvantum theme into ~/.config/Kvantum, which is what
    # was blocking home-manager activation.
    home-manager.sharedModules = [
      { stylix.targets.qt.enable = false; }
    ];
  };
}
