# try - fresh directories for every vibe (github.com/tobi/try).
#
# Not the `try` in nixpkgs: that one is binpash/try, an overlayfs sandbox for
# inspecting what a command changes. This is Tobi Lutke's, which gives every
# throwaway experiment a dated directory and a fuzzy jump back into it.
#
# Upstream ships its own home-manager module, so all this adds is the repo's
# usual userSettings toggle. The module writes the `eval "$(try init)"` line
# into the shell rc - without it `try` can print a cd but never perform one.
{ config, lib, inputs, ... }:

with lib; let
  cfg = config.userSettings.cli.try;
in
{
  imports = [ inputs.try.homeModules.default ];

  options.userSettings.cli.try = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable try (dated experiment directories, fuzzy-jumped).";
    };

    path = mkOption {
      type = types.str;
      default = "~/dev/tries";
      description = "Where the experiment directories are created.";
    };
  };

  config = mkIf cfg.enable {
    programs.try = {
      enable = true;
      inherit (cfg) path;
    };
  };
}
