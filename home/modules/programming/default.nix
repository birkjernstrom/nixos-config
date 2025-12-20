{ ... }:

{
  imports = [
    ./ai.nix
    ./tools.nix

    # Languages
    ./python.nix
    ./typescript.nix
    ./go.nix
  ];
}
