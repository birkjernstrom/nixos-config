# Terminal coding agents.
{
  flake.modules.homeManager.dev = { pkgs, ... }: {
    home.packages = with pkgs; [
      claude-code
      opencode
      herdr             # Agent multiplexer for the terminal (herdr.dev)
      pi-coding-agent   # `pi` coding agent CLI (pi.dev)
    ];
  };
}
