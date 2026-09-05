# zsh: the login shell on every host.
#
# ANTHROPIC_API_KEY is read at shell start from the sops secret declared in
# modules/secrets.nix, so the key never lands in the Nix store.
{
  flake.modules.homeManager.base = { config, pkgs, ... }: {
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
