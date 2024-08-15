{ pkgs, nixpkgs-stable }:

with pkgs;
let
  sharedPackages = import ../shared/home/packages.nix {
    inherit pkgs;
    inherit nixpkgs-stable;
  };
in
sharedPackages ++ [
  # Darwin specific packages below

  # Window management
  skhd
  yabai
]
