{ config, host, isDarwin, ... }:

let
  flake = "${config.home.homeDirectory}/.nixos-config#${host}";
in
{
  programs.nh = {
    enable = true;
    osFlake = if isDarwin then null else flake;
    darwinFlake = if isDarwin then flake else null;
  };
}
