# git, with delta as pager and 1Password as the SSH signing backend.
#
# The 1Password signer lives at a fixed path inside the macOS app bundle but
# comes from the _1password-gui package on Linux - hence the one platform
# branch. It reads the platform off pkgs rather than taking it as an argument.
#
# delta used to be written as `with inputs.nixpkgs-stable; [ delta ]`. That
# never did anything: that flake input has no `delta` attribute, so the name
# fell through to the enclosing `with pkgs` and resolved from unstable anyway.
# Spelled honestly here, and the unused nixpkgs-stable input is gone.
{
  flake.modules.homeManager.base = { pkgs, ... }: {
    home.packages = with pkgs; [
      git
      gh          # GitHub CLI
      delta       # Git diff viewer
    ];

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
          if pkgs.stdenv.hostPlatform.isDarwin then {
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
  };
}
