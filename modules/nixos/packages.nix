{ pkgs }:

with pkgs;
let sharedPackages = import ../shared/home/packages.nix { inherit pkgs; }; in
sharedPackages ++ [
  # NixOS specific packages below

  # Build tools
  gnumake
  gcc

  # Development
  wezterm
]
