{ config, pkgs, inputs, ... }:
let
  configPrivate = inputs.config-private;

  berkeleyMono = pkgs.stdenvNoCC.mkDerivation {
    pname = "berkeley-mono";
    version = "1.0.0";

    src = "${configPrivate}/assets/fonts";

    installPhase = ''
      runHook preInstall
      install -Dm644 *.ttf -t $out/share/fonts/truetype/
      runHook postInstall
    '';
  };
in
{
  # Install the Berkeley Mono fonts
  fonts.packages = [ berkeleyMono ];

  # Configure fontconfig to prefer Berkeley Mono for monospace
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = [
        "Berkeley Mono"
        "BerkeleyMono Nerd Font"
      ];
    };

    # Local fontconfig rules for fine-grained control
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
