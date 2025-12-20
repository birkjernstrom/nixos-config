{ ... }:

{
  imports = [
    ./ai.nix
    ./tools.nix

    # Languages
    ./python.nix
    ./typescript.nix
    ./rust.nix
    ./go.nix
  ];
}
