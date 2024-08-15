{ config, pkgs, nixpkgs-stable, settings, isDarwin, ... }:

{
  imports =
    [
      ./hardware/utm-aarch64.nix
      ../../modules/nixos
      ../../modules/shared
    ];
}
