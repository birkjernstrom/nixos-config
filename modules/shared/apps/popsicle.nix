# Popsicle app module (system-level)
# Linux only: upstream is Pop!_OS and nixpkgs has no Darwin build.
{ config, lib, pkgs, settings, isDarwin, ... }:

let
  popsicleEnabled = settings.user.apps.popsicle.enable or false;
  username = settings.user.name;
in
{
  # Stands in for balenaEtcher, which was dropped from nixpkgs entirely (no
  # package, no alias) and as of 2.1.6 no longer ships an AppImage either --
  # only a .deb/.rpm/.zip, so the only route left would be a hand-maintained
  # derivation around 118MB of vendored Electron.
  config = if isDarwin then { } else {
    home-manager.users.${username} = lib.mkIf popsicleEnabled {
      home.packages = [ pkgs.popsicle ];
    };

    # popsicle-gtk reaches block devices through udisks2 rather than by
    # self-elevating through pkexec, so without this it starts fine and then
    # simply lists no drives. It is already enabled here, but only as a
    # side-effect of gnome, fwupd and gvfs -- naming it means the flasher keeps
    # working if any of those three is ever turned off.
    services.udisks2.enable = lib.mkIf popsicleEnabled true;
  };
}
