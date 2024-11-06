{ config, pkgs, settings, ... }:

{
  imports = [
    ./homebrew.nix
    ./skhd.nix
    ./yabai.nix
  ];
}
