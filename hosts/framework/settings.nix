{
  username = "birk";

  # Maps to config.systemSettings.*
  system = {
    hyprland.enable = true;
  };

  # Maps to config.userSettings.*
  user = {
    cli = {
      core.enable = true;
      zsh.enable = true;
      git.enable = true;
      tmux.enable = true;
      nvim.enable = true;
    };
    programming = {
      languages = {
        python.enable = true;
        typescript.enable = true;
        go.enable = true;
        rust.enable = true;
      };
      ai.enable = true;
      tools.enable = true;
    };
    hyprland.enable = true;
  };
}
