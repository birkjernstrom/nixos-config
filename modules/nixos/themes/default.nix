{ config, lib, pkgs, inputs, ... }:

# Runtime theme switching for the whole desktop, not just the Quickshell bar.
#
# Each theme in ./themes.nix is rendered into a folder of colour files
# (./colors.nix), and ~/.local/state/theme/current links to the active one.
# The programs in ./programs.nix include their colours from there, so their
# own configs are the same for every theme. `theme-switch <id>` repoints the
# link and reloads them (see ./theme-switch.sh). Stylix still themes fonts,
# the cursor, and every other program, in the default theme.
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
      description = "Switch between the themes in ./themes.nix at runtime with theme-switch";
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
        gtk="${config.gtk.theme.name}"
        [[ $(<"$current/polarity") == dark ]] && gtk+="-dark"
        run $bus ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/gtk-theme "'$gtk'"
      fi
    '';

    # Out of the store so new images show up in the picker without a rebuild.
    xdg.dataFile."wallpapers".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.nixos-config/wallpapers";

    # hyprpaper starts on Stylix's image; put the picked one back over it.
    systemd.user.services.hyprpaper = mkIf config.services.hyprpaper.enable {
      Service.ExecStartPost = "${getExe wallpaper} --restore";
    };

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
