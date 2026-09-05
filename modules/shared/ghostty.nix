# Ghostty terminal configuration (system-level)
# Installs via homebrew on Darwin, via nixpkgs on NixOS.
# Colours and font come from Stylix's ghostty target.
{ config, lib, pkgs, settings, isDarwin, ... }:

let
  cfg = settings.user.terminal.ghostty or {};
  ghosttyEnabled = cfg.enable or false;
  username = settings.user.name;
in
{
  config = lib.mkMerge [
    # Darwin: the application comes from a homebrew cask.
    (lib.optionalAttrs isDarwin {
      homebrew.casks = lib.mkIf ghosttyEnabled [ "ghostty" ];
    })

    {
      home-manager.users.${username} = lib.mkIf ghosttyEnabled {
        programs.ghostty = {
          enable = true;

          # On Darwin the cask above provides the binary.
          package = if isDarwin then null else pkgs.ghostty;

          settings = {
            font-feature = [ "-calt" "-liga" "-dlig" ];
            cursor-style = "block";

            window-padding-x = "4,4";
            window-padding-y = "4,4";
          }
          # Stylix writes its palette to a read-only theme in the Nix store, so
          # it cannot follow a runtime theme switch. On Linux, Quickshell owns
          # ~/.config/ghostty/themes/pathway instead and reloads open terminals
          # with SIGUSR2. Stylix keeps the font. Darwin has no Quickshell, so it
          # stays on the Stylix theme.
          // lib.optionalAttrs (!isDarwin) {
            theme = lib.mkForce "pathway";
          };
        };
      };
    }
  ];
}
