{ config, lib, pkgs, ... }:

with lib; let
  cfg = config.userSettings.noctalia;
  hypr = import ../hyprland/lib.nix { inherit lib; };
  inherit (hypr) bind mod exec;

  # Where the wallpaper is installed below, and what the seed points at.
  #
  # unsafeDiscardStringContext because this ends up as a file name: Nix refuses
  # a string used that way while it still carries a reference to the store path
  # it was derived from. Only the extension is kept - the store name would drag
  # the hash along with it and change on every rebuild of the image.
  imageName = baseNameOf (builtins.unsafeDiscardStringContext (toString config.stylix.image));
  imageExt = let m = builtins.match ".*(\\.[^./]+)$" imageName; in if m == null then "" else head m;
  wallpaperName = "wallpaper${imageExt}";
  wallpaperPath = "${config.home.homeDirectory}/.local/share/noctalia/${wallpaperName}";

  # The seed carries the wallpaper Stylix used to hand to hyprpaper, so the
  # desktop does not come up blank on the first start.
  seed = pkgs.replaceVars ./config.toml {
    wallpaper = wallpaperPath;
  };
in
{
  options.userSettings.noctalia.enable = mkOption {
    type = types.bool;
    default = false;
    description = ''
      Enable Noctalia as the desktop shell, in place of the Quickshell bar and
      Pathway launcher. Noctalia also owns notifications, the lock screen, idle
      behaviour and the wallpaper, so mako, hyprlock, hypridle and Stylix's
      hyprpaper target all stand down when this is on.
    '';
  };

  config = mkIf cfg.enable {
    # mkForce because hyprland/home.nix turns both on unconditionally as the
    # companions of a Hyprland session. Two bars would stack, and two
    # notification daemons would race for org.freedesktop.Notifications with
    # whichever won the bus name silently swallowing the other's popups.
    userSettings.quickshell.enable = mkForce false;
    userSettings.mako.enable = mkForce false;

    # Noctalia draws the wallpaper itself. Left on, hyprpaper would keep
    # painting the same image underneath and would quietly undo any wallpaper
    # picked from Noctalia's own panel.
    #
    # This option, not `stylix.targets.hyprpaper.enable`: that one only decides
    # whether Stylix themes hyprpaper, while this is the gate Stylix's Hyprland
    # target checks before switching the hyprpaper *service* on at all. Turning
    # off the theming target alone left the daemon running.
    stylix.targets.hyprland.hyprpaper.enable = false;

    # Installed, not merely named. With the hyprpaper target off, nothing in
    # the closure refers to Stylix's image any more, so seeding its /nix/store
    # path straight into config.toml would write down an address that the next
    # garbage collection is free to empty - and the file Noctalia reads is a
    # plain user file, so nothing would ever repair it. A home.file keeps the
    # image alive for as long as the generation pointing at it does.
    home.file.".local/share/noctalia/${wallpaperName}".source = config.stylix.image;

    # libnotify came in with mako; notify-send is still how anything in a
    # terminal raises a notification, and Noctalia is the daemon receiving it.
    home.packages = [ pkgs.libnotify ];

    wayland.windowManager.hyprland.settings = {
      # The Lua local behind SUPER+space (hyprland/home.nix). Overriding it
      # here rather than rebinding the key keeps one definition of what the
      # launcher key does.
      menu = mkForce { _var = "noctalia msg panel-toggle launcher"; };
      clipboard = mkForce { _var = "noctalia msg panel-toggle clipboard"; };

      # hyprlock owns SUPER+SHIFT+Q while it is enabled; with it stood down,
      # this is the replacement. `loginctl lock-session` reaches the same code
      # path while Noctalia is running, so the hypridle-era lock command in
      # anything else keeps working too.
      bind = [
        (bind (mod "SHIFT + Q") (exec "noctalia msg session lock"))
      ];
    };

    # Noctalia's settings window writes ~/.config/noctalia/config.toml, so
    # home-manager cannot own it: a store symlink would be read-only and every
    # toggle in the GUI would fail to save. Seeding it once gets the idle chain
    # and the wallpaper across without taking the file hostage - after this,
    # the config belongs to Noctalia and to you.
    home.activation.noctaliaSeedConfig = hm.dag.entryAfter [ "writeBoundary" ] ''
      noctaliaConfig="${config.xdg.configHome}/noctalia/config.toml"
      if [ ! -e "$noctaliaConfig" ]; then
        run mkdir -p "$(dirname "$noctaliaConfig")"
        run cp ${seed} "$noctaliaConfig"
        run chmod u+w "$noctaliaConfig"
      fi
    '';
  };
}
