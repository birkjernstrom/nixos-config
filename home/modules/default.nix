{ ... }:

{
  imports = [
    ./core.nix
    ./sops.nix
    ./dotfiles.nix
    ./zsh.nix
    ./git.nix
    ./tmux.nix
    ./nvim

    ./programming
    ./scripts
  ];
}
