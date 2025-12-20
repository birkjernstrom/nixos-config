{ pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    bat
    fzf
    tree
    htop
    httpie
    zoxide
    starship
    ripgrep
    sesh
    atuin

    # Development
    lazydocker
    redis

    # AI tools
    claude-code
    opencode
  ];

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
