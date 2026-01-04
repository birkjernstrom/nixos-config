{ config, lib, pkgs, settings, ... }:

{
  imports = [
    ./defaults.nix
    ./homebrew.nix
    # Uncomment to enable tiling window manager
    # ./yabai.nix
    # ./skhd.nix
  ];
}
