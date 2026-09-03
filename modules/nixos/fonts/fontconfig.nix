{ pkgs, inputs, ... }:

let
  berkeleyMonoPkg = (import ./berkleymono.nix { inherit pkgs inputs; }).berkeleyMono;
in
{
  fonts.packages = [ berkeleyMonoPkg ];

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
}
