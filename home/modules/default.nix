{ ... }:

{
  imports = [
    ./sops.nix
    ./dotfiles.nix
    ./zsh.nix
    ./cli.nix
    ./git.nix
    ./tmux.nix
    ./nvim

    ./programming
    ./scripts
  ];
}
