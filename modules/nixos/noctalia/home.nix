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
  configSeed = pkgs.replaceVars ./config.toml {
    wallpaper = wallpaperPath;
  };

  # Noctalia splits its configuration in two. config.toml, under
  # XDG_CONFIG_HOME, is the hand-authored half; everything its settings window
  # writes back - theme, bar geometry, launcher behaviour - lands in
  # settings.toml here, under XDG_STATE_HOME. Both need seeding for a new host
  # to come up looking like this one.
  stateDir = config.xdg.stateHome + "/noctalia";
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

    # Noctalia writes both of these files itself - config.toml whenever its
    # settings window saves, settings.toml on every toggle in the GUI - so
    # home-manager cannot own either: a store symlink would be read-only and
    # the save would fail. Seeding them once gets the idle chain, the
    # wallpaper, the keybinds and the theme onto a new host without taking the
    # files hostage; after that they belong to Noctalia and to you.
    #
    # Which means this is also the answer to "how do I get my current setup
    # onto another machine": copy the live files back over the seeds in this
    # directory, drop whatever is specific to one host's monitors, and commit.
    home.activation.noctaliaSeedConfig = hm.dag.entryAfter [ "writeBoundary" ] (
      let
        # Copy-if-absent, never copy-over: a host that has been used already
        # has the newer file, and re-seeding would silently revert it.
        seedFile = target: source: ''
          if [ ! -e "${target}" ]; then
            run mkdir -p "$(dirname "${target}")"
            run cp ${source} "${target}"
            run chmod u+w "${target}"
          fi
        '';
      in
      ''
        ${seedFile "${config.xdg.configHome}/noctalia/config.toml" configSeed}
        ${seedFile "${stateDir}/settings.toml" ./settings.toml}
        # The palette settings.toml names. Noctalia downloads community
        # palettes into this directory on demand and URL-encodes the name to
        # get the file name, hence the %20 for the space; the repo copy is
        # spelled plainly because only the destination has to match. Seeding it
        # means a fresh host is themed at first login rather than after the
        # first successful fetch - Noctalia re-downloads it anyway once the
        # catalogue's checksum moves on.
        ${seedFile "${stateDir}/community-palettes/Kanagawa%20Dragon.json" ./palettes/kanagawa-dragon.json}

        # Noctalia runs its first-start setup wizard while this marker is
        # missing, and the wizard writes its own answers over settings.toml.
        # Planting it is what lets the seeded settings survive the first login.
        if [ ! -e "${stateDir}/.setup-complete" ]; then
          run mkdir -p "${stateDir}"
          run touch "${stateDir}/.setup-complete"
        fi
      ''
    );
  };
}
