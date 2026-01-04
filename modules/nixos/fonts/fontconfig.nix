{ pkgs, inputs, ... }:

let
  berkeleyMonoPkg = (import ./berkleymono.nix { inherit pkgs inputs; }).berkeleyMono;
in
{
  fonts.packages = [ berkeleyMonoPkg ];

  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = [
        "Berkeley Mono"
        "BerkeleyMono Nerd Font"
      ];
    };

    localConf = ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
      <fontconfig>
        <!-- Prefer Berkeley Mono for generic monospace -->
        <alias>
          <family>monospace</family>
          <prefer>
            <family>Berkeley Mono</family>
          </prefer>
        </alias>

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
