{ pkgs, nixpkgs-stable }:

with pkgs;
let
  sharedPackages = import ../shared/home/packages.nix {
    inherit pkgs;
    inherit nixpkgs-stable;
  };
in
sharedPackages ++ [
  # NixOS specific packages below

  # Build tools
  gnumake
  gcc

  # Development
  wezterm
]
