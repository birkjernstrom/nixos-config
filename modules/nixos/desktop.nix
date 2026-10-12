{ pkgs, ... }:

{
  services.gnome.gnome-keyring.enable = true;

  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
}
