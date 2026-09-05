# Webapps: a site launched as its own Chrome window, with a desktop entry so
# the rest of the system treats it as an installed application.
#
# The declarative counterpart to Omarchy's `omarchy-webapp-install`: rather than
# a script that writes a .desktop file into ~/.local/share, a site is one entry
# in hosts/<host>/settings.nix and everything else is generated from it.
#
# Chrome only - `--app` is a Chromium feature, and Firefox dropped its site
# specific browser mode years ago.
{ config, lib, pkgs, ... }:

with lib; let
  cfg = config.userSettings.apps.webapps;
  hypr = import ./hyprland/lib.nix { inherit lib; };
  inherit (hypr) bind exec mod;

  # "linear" -> "Linear", for the display name when a site does not set one.
  capitalize = s: (toUpper (substring 0 1 s)) + (substring 1 (stringLength s) s);

  # Installed under a `webapp-` prefix so a site can never shadow the icon of a
  # real application with the same name.
  iconName = key: "webapp-${key}";

  # hicolor keeps vectors in `scalable` and rasters in a per-size directory.
  # 512 is what a PWA manifest normally offers, and both GTK and Qt scale down.
  iconExt = icon: last (splitString "." (baseNameOf (toString icon)));
  iconDir = icon: if iconExt icon == "svg" then "scalable" else "512x512";

  # --profile-directory is what makes the window land in the right Chrome
  # account, and is also the only way to make its app_id predictable - see the
  # `class` option below.
  command = site: concatStringsSep " " ([
    cfg.browser
    "--app=${site.url}"
  ] ++ optional (site.profile != null) ''--profile-directory="${site.profile}"'');

  siteModule = { name, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        default = capitalize name;
        description = "Display name, as it appears in Pathway and any other launcher.";
      };

      url = mkOption {
        type = types.str;
        example = "https://linear.app";
        description = "The site to open. Chrome strips the browser chrome from the window.";
      };

      icon = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = literalExpression "../../icons/webapps/linear.png";
        description = ''
          An image file in this repo, installed into the user's hicolor theme.
          A site's own PWA manifest (/site.webmanifest) is usually the best
          source for one; 512x512 PNG or SVG.
        '';
      };

      categories = mkOption {
        type = types.listOf types.str;
        default = [ "Network" ];
        description = "Freedesktop menu categories for the generated entry.";
      };

      key = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "SHIFT + L";
        description = ''
          Optional launcher key, bound after SUPER - so "SHIFT + L" is
          SUPER + SHIFT + L.
        '';
      };

      profile = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "Profile 1";
        description = ''
          Chrome profile directory to open the site in. Unset means whichever
          profile Chrome opens by default.
        '';
      };

      class = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "chrome-linear.app__-Profile_1";
        description = ''
          Window class to advertise as StartupWMClass, and the string to match
          on in a Hyprland window rule.

          Chrome derives this from the URL and the profile rather than from
          `--class`, which it ignores whenever an instance is already running,
          so it has to be read off a live window (`hyprctl clients`) instead of
          chosen here. Pinning `profile` is what keeps it stable.
        '';
      };
    };
  };
in
{
  options.userSettings.apps.webapps = {
    browser = mkOption {
      type = types.str;
      default = "google-chrome-stable";
      description = "Chromium-based browser used to open the app windows.";
    };

    sites = mkOption {
      type = types.attrsOf (types.submodule siteModule);
      default = { };
      example = literalExpression ''
        {
          linear = {
            url = "https://linear.app";
            icon = ../../icons/webapps/linear.png;
            key = "SHIFT + L";
          };
        }
      '';
      description = "Sites to install as webapps. An empty set installs nothing.";
    };
  };

  config = mkIf (cfg.sites != { }) {
    xdg.desktopEntries = mapAttrs (key: site: {
      inherit (site) name categories;
      exec = command site;
      icon = if site.icon != null then iconName key else null;
      # Pathway shows this under the name; the URL says more than "Web app".
      comment = site.url;
      terminal = false;
      type = "Application";
      settings = optionalAttrs (site.class != null) {
        StartupWMClass = site.class;
      };
    }) cfg.sites;

    xdg.dataFile = mapAttrs' (key: site:
      nameValuePair "icons/hicolor/${iconDir site.icon}/apps/${iconName key}.${iconExt site.icon}" {
        source = site.icon;
      }) (filterAttrs (_: site: site.icon != null) cfg.sites);

    wayland.windowManager.hyprland.settings.bind =
      mkIf config.userSettings.hyprland.enable
        (mapAttrsToList (_: site: bind (mod site.key) (exec (command site)))
          (filterAttrs (_: site: site.key != null) cfg.sites));
  };
}
