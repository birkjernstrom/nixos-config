{ ... }:

{
  imports = [
    ./ai.nix
    ./pi.nix
    ./tools.nix

    # Languages
    ./c.nix
    ./python.nix
    ./typescript.nix
    ./rust.nix
    ./go.nix
  ];
}
