{ pkgs }:

with pkgs;
let sharedPackages = import ../shared/home/packages.nix { inherit pkgs; }; in
sharedPackages ++ [
  # Darwin specific packages below
]
