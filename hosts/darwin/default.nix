{ config, pkgs, nixpkgs-stable, settings, isDarwin, ... }:

{
  imports =
    [
      ../../modules/darwin
      ../../modules/shared
    ];
}
