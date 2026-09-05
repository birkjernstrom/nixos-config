# Fonts.
#
# Berkeley Mono is a paid font, so the files live in the private config-private
# input rather than this repo. _berkeley-mono.nix is a package expression, not
# a module - import-tree skips it because of the `_`.
#
# The preferred monospace family is set by Stylix's fontconfig target from
# `stylix.fonts.monospace`; only the Nerd Font symbol fallback is set here.
{ inputs, ... }:

{
  flake.modules.nixos.desktop = { pkgs, ... }:
    let
      inherit (import ./_berkeley-mono.nix { inherit pkgs inputs; }) berkeleyMono;
    in
    {

    fonts.packages = [ berkeleyMono ];

    # The preferred monospace family itself is set by Stylix's fontconfig
    # target, from `stylix.fonts.monospace`. Only the Nerd Font fallback for
    # symbol glyphs is configured here.
    fonts.fontconfig = {
      enable = true;
      defaultFonts.monospace = [ "BerkeleyMono Nerd Font" ];

      localConf = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
        <fontconfig>
          <!-- Prefer BerkeleyMono Nerd Font when nerd font symbols are needed -->
          <alias>
            <family>monospace</family>
            <accept>
              <family>BerkeleyMono Nerd Font</family>
            </accept>
          </alias>

          <!-- Map requests for specific mono fonts to Berkeley Mono -->
          <match target="pattern">
            <test qual="any" name="family">
              <string>mono</string>
            </test>
            <edit name="family" mode="prepend" binding="strong">
              <string>Berkeley Mono</string>
            </edit>
          </match>
        </fontconfig>
      '';
    };
    };
}
