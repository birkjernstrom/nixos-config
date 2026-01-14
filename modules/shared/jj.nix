{ config, pkgs, lib, isDarwin, ... }:

with lib; let
  cfg = config.userSettings.cli.jj;
in
{
  options.userSettings.cli.jj.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable jujutsu (jj) version control.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      jujutsu
    ];

    programs.jujutsu = {
      enable = true;
      settings = {
        user = {
          name = "Birk Jernstrom";
          email = "birkjernstrom@gmail.com";
        };
        signing = {
          sign-all = true;
          backend = "ssh";
          key = "~/.ssh/github.pub";
          backends.ssh.program =
            if isDarwin
            then "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
            else "${pkgs._1password-gui}/share/1password/op-ssh-sign";
        };
        ui = {
          default-command = "log";
          pager = "delta";
          diff.format = "git";
        };
      };
    };

    programs.zsh = mkIf config.userSettings.cli.zsh.enable {
      shellAliases = {
        "j" = "jj";
        "jl" = "jj log";
        "js" = "jj status";
        "jd" = "jj diff";
        "jn" = "jj new";
        "jc" = "jj commit";
        "jdesc" = "jj describe";
      };
    };
  };
}
