{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware/utm-aarch64.nix
      ../../modules/nixos
      ../../modules/shared
    ];
}
