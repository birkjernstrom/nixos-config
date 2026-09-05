# Language toolchains.
#
# One file rather than six: these are all the same shape, and splitting them
# only pays off once a language needs real configuration of its own.
{
  flake.modules.homeManager.dev = { pkgs, ... }: {
    home.packages = with pkgs; [
      # Python
      pyenv
      poetry
      uv
      python314

      # TypeScript
      nodejs_24
      pnpm

      # Rust
      rustup

      # Go
      go
    ];

    # rustup installs toolchain shims here.
    home.sessionPath = [ "$HOME/.cargo/bin" ];

    programs = {
      pyenv = {
        enable = true;
        enableZshIntegration = true;
      };

      poetry.enable = true;
    };
  };
}
