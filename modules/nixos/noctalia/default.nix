{ config, lib, inputs, ... }:

with lib; let
  cfg = config.systemSettings.noctalia;
in
{
  # The flake's own module rather than the one in nixpkgs: it carries a
  # `disabledModules` for the nixpkgs copy, so importing it is what keeps the
  # two definitions of programs.noctalia from colliding. It also defaults
  # `package` to the flake's build, which - because the input follows this
  # config's nixpkgs - is compiled against the same package set as everything
  # else here.
  imports = [ inputs.noctalia.nixosModules.default ];

  options.systemSettings.noctalia.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Noctalia, the Wayland desktop shell (system-level)";
  };

  config = mkIf cfg.enable {
    programs.noctalia = {
      enable = true;

      systemd = {
        enable = true;

        # Not graphical-session.target: Hyprland's own session target is what
        # home-manager's hyprland module starts from the `hyprland.start`
        # handler, once WAYLAND_DISPLAY and HYPRLAND_INSTANCE_SIGNATURE are in
        # the user environment. Started any earlier the shell comes up with no
        # compositor to attach its layer surfaces to.
        target = "hyprland-session.target";
      };

      # Every option behind this is mkDefault, so it only fills in what is not
      # already set: NetworkManager is on in hosts/framework/configuration.nix
      # and stays as configured there (iwd backend and all). What this adds is
      # bluetooth, UPower and a power profile daemon, which the control centre
      # and the battery and bluetooth widgets read.
      recommendedServices.enable = true;
    };
  };
}
