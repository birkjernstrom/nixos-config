# Yazi app module (system-level)
{ config, lib, pkgs, settings, isDarwin, ... }:

let
  yaziEnabled = settings.user.apps.yazi.enable or false;
  username = settings.user.name;
in
{
  home-manager.users.${username} = lib.mkIf yaziEnabled (lib.mkMerge [
    {
      programs.yazi = {
        enable = true;
        shellWrapperName = "y";
      };
    }

    # Shadows yazi's own yazi.desktop, which is Terminal=true and so depends on
    # whatever terminal xdg-open guesses at; this one names Ghostty.
    (lib.optionalAttrs (!isDarwin) {
      xdg.desktopEntries.yazi = {
        name = "Yazi";
        genericName = "File Manager";
        icon = "yazi";
        exec = "ghostty -e yazi %u";
        terminal = false;
        mimeType = [ "inode/directory" ];
        categories = [ "System" "FileTools" "FileManager" ];
      };

      xdg.mimeApps = {
        enable = true;
        defaultApplications."inode/directory" = "yazi.desktop";
      };
    })
  ]);
}
