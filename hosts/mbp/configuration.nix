{ config, pkgs, nixpkgs-stable, settings, isDarwin, ... }:

{
  imports = [
    ../../configuration/shared
    ../../configuration/darwin
  ];

  users.users.${settings.user} = {
    name = "${settings.user}";
    home = "/Users/${settings.user}";
    isHidden = false;
    shell = pkgs.zsh;
  };
}
