{ pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    zsh
    bat
    fzf
    zoxide
    starship
    ripgrep
    sesh
    atuin

    # Tmux
    tmux
    tmuxp

    # Development
    neovim
    git
    gh    # GitHub CLI
    lazydocker
    redis
    claude-code

    # Node
    nodejs_20
    # corepack  # To install pnpm as needed etc

    # Go
    go

    # Python
    pyenv
    poetry
    uv
    python314
  ] ++ (with inputs.nixpkgs-stable;
  [
    # Disable short-term due to nix issues with delta
    delta # Git diff
  ]);

  programs = {
    bat.enable = true;
    tmux.enable = true;
    tmux.tmuxp.enable = true;
    ripgrep.enable = true;

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    atuin = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        auto_sync = true;
        filter_mode = "host";
        style = "compact";
        inline_height = 20;
      };
    };

    starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        character = {
          success_symbol = "";
          vicmd_symbol = "";
          error_symbol = ""; 
        };
        directory = {
          style = "blue bold";
        };
      };
    };

    ###############################################################################
    # Python
    ###############################################################################

    pyenv = {
      enable = true;
      enableZshIntegration = true;
    };

    poetry.enable = true;
  };
}
