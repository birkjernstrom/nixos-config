# Beekeeper Studio app module (system-level)
# Linux only: x86_64 .deb pinned ahead of nixpkgs.
{ config, lib, pkgs, settings, isDarwin, ... }:

let
  beekeeperEnabled = settings.user.apps.beekeeper-studio.enable or false;
  username = settings.user.name;

  beekeeper-studio = pkgs.beekeeper-studio.overrideAttrs (_: rec {
    version = "6.1.5";
    src = pkgs.fetchurl {
      url = "https://github.com/beekeeper-studio/beekeeper-studio/releases/download/v${version}/beekeeper-studio_${version}_amd64.deb";
      hash = "sha256-dNix1+d5h3iMGXJtfaIKk/pzyI2UGWJwaQhyBCFCaB4=";
    };
  });
in
{
  config = if isDarwin then { } else lib.mkIf beekeeperEnabled {
    # Still bundles EOL Electron 39; permitted for this exact version only.
    nixpkgs.config.permittedInsecurePackages = [ beekeeper-studio.name ];

    home-manager.users.${username}.home.packages = [ beekeeper-studio ];
  };
}
