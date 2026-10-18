{ ... }:

{
  imports = [
    ./ai.nix
    ./pi.nix
    ./tools.nix

    # Languages
    ./python.nix
    ./typescript.nix
    ./rust.nix
    ./go.nix
  ];
}
