{ config, pkgs, lib, ... }:

let
  skhdConfig = import ./skhd.nix { inherit config pkgs lib; };
  yabaiConfig = import ./yabai.nix { inherit config pkgs lib; };
in
lib.mkMerge [
  skhdConfig
  yabaiConfig
  {
  }
]
