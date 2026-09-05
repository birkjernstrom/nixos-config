# Ghostty, the terminal on both hosts.
#
# Colours and font come from Stylix's ghostty target on macOS. On Linux they do
# not: Stylix writes its palette to a read-only theme in the Nix store, so it
# cannot follow a runtime theme switch. There Quickshell owns
# ~/.config/ghostty/themes/pathway and reloads open terminals with SIGUSR2,
# so the theme is forced to "pathway" and Stylix keeps only the font.
{
  flake.modules.darwin.gui-apps = {
    homebrew.casks = [ "ghostty" ];
  };

  flake.modules.homeManager.gui-apps = { pkgs, lib, ... }: {
    programs.ghostty = {
      enable = true;

      # On macOS the homebrew cask above provides the binary.
      package = if pkgs.stdenv.hostPlatform.isDarwin then null else pkgs.ghostty;

      settings = {
        font-feature = [ "-calt" "-liga" "-dlig" ];
        cursor-style = "block";

        window-padding-x = "4,4";
        window-padding-y = "4,4";
      }
      // lib.optionalAttrs (!pkgs.stdenv.hostPlatform.isDarwin) {
        theme = lib.mkForce "pathway";
      };
    };
  };
}
