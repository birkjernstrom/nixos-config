{ config, lib, pkgs, inputs }:

# One theme's colour files. Programs include them from
# ~/.local/state/theme/current; see ./default.nix.
name: theme:

let
  colors = (config.stylix.base16.mkSchemeAttrs theme.scheme).override (theme.override or { });
  polarity = theme.polarity or "dark";
  opacity = config.stylix.opacity;

  slots = map (i: "base0${i}") [ "0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "A" "B" "C" "D" "E" "F" ];
  file = n: text: pkgs.writeText "${name}-${n}" text;
  stylixTemplate = path: ext: colors {
    template = builtins.readFile "${inputs.stylix}/modules/${path}";
    extension = ext;
  };

  rgb = c: "rgb(${c})";
  ch = c: k: colors."${c}-rgb-${k}";
  zrgb = c: "rgb(${ch c "r"}, ${ch c "g"}, ${ch c "b"})";
  zrgba = c: a: "rgba(${ch c "r"}, ${ch c "g"}, ${ch c "b"}, ${toString a})";

  borders = theme.borders or { active = colors.base03; inactive = colors.base01; };

  hyprland = {
    general = {
      "col.active_border" = rgb borders.active;
      "col.inactive_border" = rgb borders.inactive;
    };
    decoration = {
      inactive_opacity = if polarity == "light" then 0.85 else 0.95;
      shadow.color = "rgba(${colors.base00}99)";
    };
    group = {
      "col.border_inactive" = rgb colors.base03;
      "col.border_active" = rgb colors.base0D;
      "col.border_locked_active" = rgb colors.base0C;
      groupbar = {
        text_color = rgb colors.base05;
        "col.active" = rgb colors.base0D;
        "col.inactive" = rgb colors.base03;
      };
    };
    misc.background_color = rgb colors.base00;
  };

  ghostty = with colors.withHashtag; ''
    background = ${colors.base00}
    cursor-color = ${colors.base05}
    foreground = ${colors.base05}
  '' + lib.concatImapStrings (i: c: "palette = ${toString (i - 1)}=${c}\n") [
    base00 base08 base0B base0A base0D base0E base0C base05
    base03 base08 base0B base0A base0D base0E base0C base07
  ] + ''
    selection-background = ${colors.base02}
    selection-foreground = ${colors.base05}
  '';

  zathura = {
    default-bg = zrgba "base00" opacity.applications;
    default-fg = zrgb "base01";
    statusbar-fg = zrgb "base04";
    statusbar-bg = zrgb "base02";
    inputbar-bg = zrgb "base00";
    inputbar-fg = zrgb "base07";
    notification-bg = zrgb "base00";
    notification-fg = zrgb "base07";
    notification-error-bg = zrgb "base00";
    notification-error-fg = zrgb "base08";
    notification-warning-bg = zrgb "base00";
    notification-warning-fg = zrgb "base08";
    highlight-color = zrgba "base0A" 0.5;
    highlight-active-color = zrgba "base0D" 0.5;
    completion-bg = zrgb "base01";
    completion-fg = zrgb "base0D";
    completion-highlight-fg = zrgb "base07";
    completion-highlight-bg = zrgb "base0D";
    recolor-lightcolor = zrgb "base00";
    recolor-darkcolor = zrgb "base06";
  };

  starshipPalette = with colors.withHashtag; {
    black = base00;
    bright-black = base03;
    white = base05;
    bright-white = base07;
    purple = magenta;
    bright-purple = bright-magenta;
    inherit red orange yellow green cyan blue magenta brown
      bright-red bright-yellow bright-green bright-cyan bright-blue bright-magenta
      base00 base01 base02 base03 base04 base05 base06 base07 base08 base09
      base10 base11 base12 base13 base14 base15 base16 base17;
    base0a = base0A;
    base0b = base0B;
    base0c = base0C;
    base0d = base0D;
    base0e = base0E;
    base0f = base0F;
  };

  makoAlpha = lib.toHexString (builtins.ceil (opacity.popups * 255));
  mako = with colors.withHashtag; lib.recursiveUpdate config.services.mako.settings {
    background-color = base00 + makoAlpha;
    border-color = base0D;
    text-color = base05;
    progress-color = "over ${base02}";
    "urgency=low" = {
      background-color = base00 + makoAlpha;
      border-color = base03;
      text-color = base05;
    };
    "urgency=critical" = {
      background-color = base00 + makoAlpha;
      border-color = base08;
      text-color = base05;
    };
  };

  # Same layout as home-manager's services.mako.
  makoConfig = settings:
    let
      value = v: if builtins.isBool v then lib.boolToString v else toString v;
      lines = lib.mapAttrsToList (k: v: "${k}=${value v}");
      global = lib.filterAttrs (_: v: !lib.isAttrs v) settings;
      sections = lib.filterAttrs (_: lib.isAttrs) settings;
    in
    lib.concatStringsSep "\n" (lines global)
    + lib.concatStrings (lib.mapAttrsToList (n: s: "\n\n[${n}]\n" + lib.concatStringsSep "\n" (lines s)) sections);
in
{
  name = file "name" name;
  polarity = file "polarity" polarity;
  "palette.json" = file "palette.json" (builtins.toJSON (lib.genAttrs slots (s: colors.${s})));
  "hyprland.lua" = file "hyprland.lua" "return ${lib.generators.toLua { } hyprland}\n";
  ghostty = file "ghostty" ghostty;
  "tmux.conf" = colors { templateRepo = inputs.stylix.inputs.tinted-tmux; target = "base16"; };
  "gtk.css" = stylixTemplate "gtk/gtk.css.mustache" ".css";
  "hyprlock.conf" = file "hyprlock.conf"
    (lib.concatMapStrings (s: "\$${s} = rgb(${colors.${s}})\n") slots);
  zathurarc = file "zathurarc"
    (lib.concatStrings (lib.mapAttrsToList (k: v: "set ${k}\t\"${v}\"\n") zathura));
  "starship.toml" = (pkgs.formats.toml { }).generate "${name}-starship.toml"
    (config.programs.starship.settings // {
      palette = "base16";
      palettes.base16 = starshipPalette;
    });
  mako = file "mako" (makoConfig mako);
}
