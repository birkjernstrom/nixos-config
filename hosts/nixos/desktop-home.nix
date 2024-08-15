{ config, pkgs, nixpkgs-stable, settings, isDarwin, ... }:

{
  imports =
    [
      ./hardware/amd-x86-64.nix
      ../../modules/nixos
      ../../modules/shared
    ];
}
