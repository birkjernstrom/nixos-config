{ config, lib, pkgs, ... }:

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

  # The base generation's theme - whatever modules/shared/stylix.nix sets.
  default = "kanagawa-dragon";

  schemes = "${pkgs.base16-schemes}/share/themes";

  # id -> Stylix settings. Keep in step with Themes.qml.
  themes = {
    tokyo-night-storm = {
      scheme = "${schemes}/tokyo-night-storm.yaml";
      # Storm does not follow base16 terminal semantics: its base08 is a pale
      # blue and base0A a cyan. Red and yellow are what errors, warnings and
      # the terminal's ANSI red/yellow should be.
      override = {
        base08 = "f7768e";
        base0A = "ff9e64";
      };
    };
    vesper = {
      # Hand-mapped from the original theme; see the file for why not the
      # base16-schemes one.
      scheme = ../../../quickshell/tools/schemes/vesper.yaml;
      override = { };
    };
    nord = {
      scheme = "${schemes}/nord.yaml";
      # base07 is the terminal's bright white; Nord puts a frost teal there.
      override.base07 = "eceff4";
    };
    grayscale-dark = {
      scheme = "${schemes}/grayscale-dark.yaml";
      # All-grey accents would hide errors and warnings; bring back one muted
      # red and one muted amber.
      override = {
        base08 = "c76b6b";
        base0A = "c9a866";
      };
    };
    rose-pine = {
      scheme = "${schemes}/rose-pine.yaml";
      # base07 (bright white) is a dark grey in the port, and base0A (warnings)
      # the pale rose; use Rosé Pine's text colour and its gold.
      override = {
        base07 = "e0def4";
        base0A = "f6c177";
      };
    };
  };

  themeSwitch = pkgs.writeShellApplication {
    name = "theme-switch";
    # hyprctl, makoctl, tmux and nvim come from the session, so they always
    # match what is actually running.
    runtimeInputs = with pkgs; [ coreutils gnugrep procps jq glib ];
    text = replaceStrings [ "@default@" ] [ default ] (builtins.readFile ./theme-switch.sh);
  };
in
{
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
    home.packages = [ themeSwitch ];

    specialisation = mapAttrs (_: theme: {
      configuration = {
        userSettings.themes.isSpecialisation = true;
        stylix.base16Scheme = mkForce theme.scheme;
        stylix.override = mkForce theme.override;
      };
    }) themes;

    # Boot and every nixos-rebuild activate the base generation, i.e. the
    # default theme. Put the remembered one back straight after.
    home.activation.restoreTheme = mkIf (!cfg.isSpecialisation)
      (hm.dag.entryAfter [ "reloadSystemd" ] ''
        run ${getExe themeSwitch} --restore || true
      '');
  };
}
