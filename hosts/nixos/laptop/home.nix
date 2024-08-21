{ ... }:

{
  imports = [
    ../../../modules/nixos/home.nix
  ];

  home.username = "birk";
  home.homeDirectory = "/home/birk";
}
