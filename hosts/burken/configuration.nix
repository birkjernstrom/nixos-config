{ config, pkgs, nixpkgs-stable, settings, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../configuration/shared
    ../../configuration/nixos
  ];

  networking.hostName = "burken";
  services.openssh.enable = true;
}
