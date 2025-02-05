{ ... }:

{
  imports = [
    ./cli.nix
    ./programming
    ./sops.nix
    ./dotfiles.nix
    ./zsh.nix
    ./git.nix
    ./tmux.nix

    ./scripts
  ];
}
