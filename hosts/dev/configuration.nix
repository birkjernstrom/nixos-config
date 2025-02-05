{ config, pkgs, nixpkgs-stable, settings, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../configuration/shared
    ../../configuration/nixos
  ];

  networking.hostName = "birkdev"; # Define your hostname.
  services.openssh.enable = true;
}
