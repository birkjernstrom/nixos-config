{ pkgs, isDarwin, ... }:

{
  programs.git = {
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
      "gpg \"ssh\"" =
        if isDarwin then {
          # _1password-gui is broken on darwin. So cannot make it shared & need
          # to install 1password as a cask on macOS + provide an absolute path.
          program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
        } else {
          program = "${pkgs._1password-gui}/share/1password/op-ssh-sign";
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

  programs.zsh = {
    shellAliases = {
      "g" = "git";
      "gp" = "git push";
      "gpo" = "git push -u origin";
      "gb" = "git branch";
      "gbd" = "git branch -d";
      "gs" = "git status";
      "gc" = "git commit";
      "gcm" = "git commit -m";
      "gd" = "git diff";
    };
  };
}
