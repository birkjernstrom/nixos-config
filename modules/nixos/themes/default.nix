{ config, lib, pkgs, inputs, ... }:

# Runtime theme switching for the whole desktop, not just the Quickshell bar.
#
# Stylix themes everything at build time, into read-only store paths, so a
# switch cannot rewrite its output in place. Instead every theme is built ahead
# of time: the default is this home-manager configuration as-is (Stylix set up
# in modules/shared/stylix.nix), and each other theme is a specialisation of it
# with Stylix pointed at another scheme. `theme-switch <id>` activates one and
# tells running programs to reload (see ./theme-switch.sh).
#
# Quickshell's theme menu calls it; quickshell/Common/Themes.qml lists the same
# themes, with the same overrides, for the bar's own palette.

with lib; let
  cfg = config.userSettings.themes;

  inherit (import ./themes.nix { inherit pkgs; }) default themes;

  mkColors = import ./colors.nix { inherit config lib pkgs inputs; };

  # Every theme's colour files, at <id>/<file>.
  themeColors = pkgs.linkFarm "theme-colors" (concatLists (mapAttrsToList
    (id: theme: mapAttrsToList (file: path: { name = "${id}/${file}"; inherit path; }) (mkColors id theme))
    themes));

  # Takes hyprctl from the package rather than the session: it also runs as
  # hyprpaper's ExecStartPost, outside any shell's PATH.
  wallpaper = pkgs.writeShellApplication {
    name = "wallpaper";
    runtimeInputs = with pkgs; [ coreutils findutils hyprland ];
    text = builtins.readFile ./wallpaper.sh;
  };

  themeSwitch = pkgs.writeShellApplication {
    name = "theme-switch";
    # hyprctl, makoctl, tmux, qs and nvim come from the session, so they always
    # match what is actually running.
    runtimeInputs = with pkgs; [ coreutils procps jq glib wallpaper ];
    text = builtins.readFile ./theme-switch.sh;
  };
in
{
  imports = [ ./programs.nix ];

  options.userSettings.themes = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Pre-build every theme and switch between them at runtime with theme-switch";
    };

    # Set inside each theme's specialisation. Their activations must not run
    # the restore hook below - they are what it activates.
    isSpecialisation = mkOption {
      type = types.bool;
      default = false;
      internal = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ themeSwitch wallpaper ];

    xdg.dataFile."theme-colors".source = themeColors;

    # The active theme's colour files. Repointed by theme-switch; created on
    # first activation, or when the theme it named no longer exists. Every
    # activation loads the default theme's color-scheme into dconf, so put
    # the active one's back.
    home.activation.themeCurrent = hm.dag.entryAfter [ "linkGeneration" "dconfSettings" ] ''
      current="${config.xdg.stateHome}/theme/current"
      if [[ ! -e $current/name ]]; then
        run mkdir -p "$(dirname "$current")"
        run ln -sfn "${config.xdg.dataHome}/theme-colors/${default}" "$current"
      fi
      if [[ -e $current/polarity ]]; then
        bus=""
        [[ -v DBUS_SESSION_BUS_ADDRESS ]] || bus="${pkgs.dbus}/bin/dbus-run-session --dbus-daemon=${pkgs.dbus}/bin/dbus-daemon"
        run $bus ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/color-scheme "'prefer-$(<"$current/polarity")'"
      fi
    '';

    # Out of the store so new images show up in the picker without a rebuild.
    xdg.dataFile."wallpapers".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.nixos-config/wallpapers";

    # hyprpaper starts on Stylix's image; put the picked one back over it.
    systemd.user.services.hyprpaper = mkIf config.services.hyprpaper.enable {
      Service.ExecStartPost = "${getExe wallpaper} --restore";
    };

    specialisation = mapAttrs (_: theme: {
      configuration = {
        userSettings.themes.isSpecialisation = true;
        stylix.base16Scheme = mkForce theme.scheme;
        stylix.override = mkForce (theme.override or { });
        stylix.polarity = mkForce (theme.polarity or "dark");
      };
    }) (removeAttrs themes [ default ]);

    # Stylix writes 'default' for light, which the portal reports as no
    # preference; Chromium and Electron only switch on an explicit one.
    dconf.settings."org/gnome/desktop/interface".color-scheme = mkForce
      (if config.stylix.polarity == "light" then "prefer-light" else "prefer-dark");

    # "auto" asks the terminal for its background, so running sessions follow
    # Ghostty's reload rather than keeping the polarity they started with.
    home.activation.claudeTheme = hm.dag.entryAfter [ "writeBoundary" ] ''
      settings="$HOME/.claude/settings.json"
      if [[ -f $settings && -z ''${DRY_RUN:-} ]]; then
        ${getExe pkgs.jq} '.theme = "auto"' "$settings" > "$settings.tmp" && mv "$settings.tmp" "$settings"
      fi
    '';
  };
}
