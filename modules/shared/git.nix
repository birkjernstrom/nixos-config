{ config, pkgs, lib, inputs, isDarwin, ... }:

with lib; let
  cfg = config.userSettings.cli.git;
in
{
  options.userSettings.cli.git.enable = mkOption {
    type = types.bool;
    default = true;
    description = "Enable git configuration.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      git
      gh          # GitHub CLI
    ] ++ (with inputs.nixpkgs-stable;
    [
      delta       # Git diff viewer
    ]);

    programs.git = {
      enable = true;
      signing = {
        key = "~/.ssh/github.pub";
        signByDefault = true;
      };
      settings = {
        user = {
          name = "Birk Jernstrom";
          email = "birkjernstrom@gmail.com";
        };
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
        alias = {
          init-submodules = "git submodule init && git submodule foreach git submodule init";
          update-submodules = "git submodule update && git submodule foreach git submodule update";
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
    };
    programs.zsh = mkIf config.userSettings.cli.zsh.enable {
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
  };
}
