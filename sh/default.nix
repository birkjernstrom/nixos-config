{ pkgs, ... }:

with pkgs;
let t = import ./t.nix { inherit pkgs; }; in
[
  t
]
