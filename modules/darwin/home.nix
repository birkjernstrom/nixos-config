{ config, pkgs, lib, home-manager, ... }:

let
  user = "birk";
  sharedFiles = import ../shared/home/files.nix { inherit config pkgs; };
  sharedPrograms = import ../shared/home/programs.nix { inherit config pkgs; };
in
{
  users.users.${user} = {
    name = "${user}";
    home = "/Users/${user}";
    isHidden = false;
    shell = pkgs.zsh;
    packages = with pkgs; [
      
    ];
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${user} = { pkgs, config, lib, ... }:{
      home = {
        file = lib.mkMerge [
          sharedFiles
        ];
        stateVersion = "24.05";
      };

      programs = lib.mkMerge [
        sharedPrograms
      ];
    };
  };
}
