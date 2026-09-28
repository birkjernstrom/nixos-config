# Zathura app module (system-level)
# Linux only: default-app associations are an XDG (mimeapps.list) concept with
# no Darwin equivalent.
{ config, lib, pkgs, settings, isDarwin, ... }:

let
  zathuraEnabled = settings.user.apps.zathura.enable or false;
  username = settings.user.name;
in
{
  config = if isDarwin then { } else {
    home-manager.users.${username} = lib.mkIf zathuraEnabled {
      programs.zathura.enable = true;

      # zathura's own desktop entry (org.pwmt.zathura.desktop) carries no
      # MimeType - each backend plugin declares the formats it handles, and
      # pkgs.zathura bundles the mupdf one, whose entry is what claims
      # application/pdf.
      xdg.mimeApps = {
        enable = true;
        defaultApplications."application/pdf" = "org.pwmt.zathura-pdf-mupdf.desktop";
      };
    };
  };
}
