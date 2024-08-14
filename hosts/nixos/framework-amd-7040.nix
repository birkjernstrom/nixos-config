{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware/framework-amd-7040.nix
      ../../modules/nixos
      ../../modules/shared
    ];
}
