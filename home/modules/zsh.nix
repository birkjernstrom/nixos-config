{ config, pkgs, lib, inputs, settings, ... }:

with lib; let
  feat = config.features.cli.git;
in
{
  options.features.cli.zsh.enable = mkOption {
    type = types.bool;
    default = true;
    description = "Enable zsh configuration.";
  };

  config = mkIf feat.enable {
    home.packages = with pkgs; [
      zsh
    ];

    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
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

        "ldo" = "lazydocker";

        # Use zsh after nix develop -- unfortunately from within bash
        # https://github.com/NixOS/nix/issues/4609
        "nixdev" = "nix develop --command zsh";
      };

      sessionVariables = {
        EDITOR = "nvim";
        DISABLE_AUTO_TITLE = "true";

        ANTHROPIC_API_KEY = ''$(cat ${config.sops.secrets."anthropic".path})'';
      };
    };
  };
}
