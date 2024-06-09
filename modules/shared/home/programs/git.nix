{ config, pkgs, ... }:

{
  git = {
    enable = true;
    userName = "Birk Jernstrom";
    userEmail = "birkjernstrom@gmail.com";
    signing = {
      key = "~/.ssh/github.pub";
      signByDefault = true;
    };
    extraConfig = {
      gpg = {
        format = "ssh";
      };
      "gpg \"ssh\"" = {
        # Change path for NixOS
        program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      };
      init = {
        defaultBranch = "main";
      };
      core = {
        editor = "nvim";
        pager = "delta";
      };
      color = {
        branch = true;
        diff = true;
        decorate = true;
        grep = true;
        interactive = true;
        pager = true;
        showbranch = true;
        status = true;
        ui = true;
      };
      interactive = {
        diffFilter = "delta --color-only";
      };
      delta = {
        navigate = true;
        light = false;
      };
      merge = {
        conflictstyle = "diff3";
      };
      diff = {
        colorMoved = "default";
      };
    };
    ignores = [
      "*.~"
      "*.o"
      "*.swp"
      "*.nfs*"
      "tmp.*"
      ".DS_Store"

      "build/"

       # Cocoa development
       "*~.nib"
       "*.pbxuser"
       "*.mode*"
       "*.perspective*"
       "xuserdata"
    ];
    aliases = {
      init-submodules = "git submodule init && git submodule foreach git submodule init";
      update-submodules = "git submodule update && git submodule foreach git submodule update";
    };
  };
}
