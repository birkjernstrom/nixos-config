{ config, pkgs, ... }:

{
  zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    plugins = [
      {
        name = "vi-mode";
        src = pkgs.zsh-vi-mode;
        file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
      }
    ];
    shellAliases = {
      # zoxide override
      "cd" = "z";

      #  Regular aliases
      ".." = "cd ..";
      "-" = "cd -";
      "ll" = "ls -ahl";

      # zoxide override
      "cat" = "bat";

      # neovim
      "n" = "nvim";
      "v" = "nvim";

      # git
      "g" = "git";
      "gp" = "git push";
      "gpo" = "git push -u origin";
      "gb" = "git branch";
      "gbd" = "git branch -d";
      "gs" = "git status";
      "gc" = "git commit";
      "gd" = "git diff";
    };

    sessionVariables = {
      EDITOR = "nvim";
    };
  };
}
