{ config, pkgs, ... }:

let
  user = "birk";
  sharedFiles = import ../shared/home/files.nix { inherit config pkgs; };
in
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home = {
    username = "${user}";
    homeDirectory = "/home/${user}";
    file = lib.mkMerge [
      sharedFiles
    ];
    packages = [
      pkgs.git
    ];
    sessionVariables = {
      # EDITOR = "emacs";
    };

    stateVersion = "24.05"; # Please read the comment before changing.
  }

  programs.zsh = {
    enable = true;
    shellAliases = {
      ".." = "cd ..";
    };
  };
}
