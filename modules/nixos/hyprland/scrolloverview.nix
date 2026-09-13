{ config, lib, pkgs, ... }:

with lib; let
  cfg = config.userSettings.hyprland;
  hypr = import ./lib.nix { inherit lib; };
  inherit (hypr) bind mod lua;

  # The niri-style zoomed-out view of the whole scrolling tape, bound to
  # SUPER+G below.
  #
  # Built here rather than taken from nixpkgs because there is nothing left to
  # take: hyprwm/hyprland-plugins dropped hyprexpo (and hyprscrolling, which
  # moved into Hyprland proper) in May 2026 under "drop unmaintained plugins",
  # and hyprlandPlugins.hyprspace - the only overview still packaged - is
  # pinned to a commit that stops at Hyprland 0.55 and fails to compile against
  # 0.56 headers.
  #
  # This is the upstream flake's own derivation with `hyprland` left at the
  # nixpkgs build the rest of the config uses, so the plugin and the compositor
  # are built from the same headers and the ABI matches by construction. A
  # Hyprland bump that outruns the plugin will fail at build time, not at
  # runtime with a refusal to load.
  scrolloverview = pkgs.hyprlandPlugins.mkHyprlandPlugin {
    pluginName = "scrolloverview";
    version = "0-unstable-2026-09-07";

    src = pkgs.fetchFromGitHub {
      owner = "yayuuu";
      repo = "hyprland-scroll-overview";
      rev = "5e96ae20ec73c320248bcf3ff68b330bc1ed4152";
      hash = "sha256-clDeTM5itsJPvqpbEkbWUmuPROsz2+YUnTpqsjQDMqU=";
    };

    buildInputs = [ pkgs.lua5_4 ];
    enableParallelBuilding = true;
    dontUseCmakeConfigure = true;

    buildPhase = ''
      runHook preBuild
      make all
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib"
      mv scrolloverview.so "$out/lib/libscrolloverview.so"
      runHook postInstall
    '';

    meta = {
      description = "Scrollable workspace overview plugin for Hyprland";
      homepage = "https://github.com/yayuuu/hyprland-scroll-overview";
      license = licenses.bsd3;
      platforms = platforms.linux;
    };
  };
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      # Rendered as hl.plugin.load("<store path>/lib/libscrolloverview.so"),
      # ahead of the hl.config() call that configures it.
      plugins = [ scrolloverview ];

      settings = {
        config.plugin.scrolloverview = {
          # Everything else is left at the plugin's defaults (scale 0.5,
          # vertical stacking, no wallpaper, no shadow); only the gap is
          # wrong out of the box, where 0 leaves the workspace cards sharing
          # an edge with nothing to separate them.
          workspace_gap = 100;
        };

        # The plugin exposes dispatchers as hl.plugin.<name>.<dispatcher>,
        # which call rather than return, so the bind takes a closure instead
        # of the hl.dsp.* dispatcher value the other binds use.
        #
        # "all" opens the overview on every monitor at once rather than only
        # the focused one - with workspace 8 living alone on the laptop panel
        # (./workspaces.nix) the per-monitor view would hide half the layout.
        bind = [
          (bind (mod "G") (lua ''function() hl.plugin.scrolloverview.overview("toggle all") end''))
        ];
      };
    };
  };
}
