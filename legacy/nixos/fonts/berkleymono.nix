{ pkgs, inputs, ... }:

let
  configPrivate = inputs.config-private;
in
{
  berkeleyMono = pkgs.stdenvNoCC.mkDerivation {
    pname = "berkeley-mono";
    version = "1.0.0";

    src = "${configPrivate}/assets/fonts";

    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/fonts/truetype
      mkdir -p $out/share/fonts/opentype

      # Install TTF fonts if present
      find $src -name "*.ttf" -exec install -Dm644 {} -t $out/share/fonts/truetype/ \;

      # Install OTF fonts if present
      find $src -name "*.otf" -exec install -Dm644 {} -t $out/share/fonts/opentype/ \;

      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "Berkeley Mono font family";
      license = licenses.unfree;
      platforms = platforms.all;
    };
  };
}
