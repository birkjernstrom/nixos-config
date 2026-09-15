{ config, lib, ... }:

with lib; let
  cfg = config.userSettings.hyprland;
  hypr = import ./lib.nix { inherit lib; };
  inherit (hypr) lua;

  # Refresh rate the internal panel is pinned to while a heavy external is
  # attached. The BOE panel in this Framework offers exactly two rungs, 165 and
  # 60, with nothing in between, so this is not a tuning knob so much as the
  # only other option.
  dockedRefresh = 60;

  # An external above this is assumed to need ODM pipe-combine on the display
  # controller. Strictly greater than 4K, so the Studio Display (5120x2880 =
  # 14.7Mpx) trips it and a 4K screen does not.
  #
  # The 5K figure is measured; the 4K one is not. If a 4K dock ever reproduces
  # the black panel, drop this to `2560 * 1440` -- or to 0 to cap the internal
  # panel whenever any external at all is attached.
  heavyExternalPixels = 3840 * 2160;

  # Driving 2560x1600@165 on eDP-1 at the same time as 5120x2880@60 on the
  # Studio Display overruns the display controller on this machine (Radeon
  # 780M, DCN 3.1.4). The 5K mode needs pipe-combine, the 165Hz internal mode
  # needs a pipe split of its own, and the atomic check refuses the pair:
  #
  #   drm: eDP-1 is disabled, releasing crtc 84
  #   drm: connector eDP-1, has crtc -1, will be rechecked
  #   ERR: atomic drm request: failed to commit: Invalid argument,
  #        flags: ATOMIC_ALLOW_MODESET
  #
  # The failure is silent on the surface: Hyprland keeps reporting eDP-1 as
  # enabled at 165Hz with dpms on, while the kernel leaves the connector
  # unbound, so the laptop panel is simply black. `cat
  # /sys/class/drm/card1-eDP-1/{status,enabled}` reading `connected` +
  # `disabled` is the tell, and it is what separates this from the stale-CRTC
  # fault, where the *external* goes black and only a reboot clears it.
  #
  # At 60Hz the internal mode fits alongside the 5K and the commit succeeds, so
  # the panel is capped while docked and handed its preferred mode back the
  # moment the external goes away.
  capInternal = lua ''
    (function()
      local applied = nil
      local busy = false

      local function isInternal(m)
        return (m.name:match("^eDP") or m.name:match("^LVDS") or m.name:match("^DSI")) ~= nil
      end

      local function work()
        local internal, heavy = nil, false
        for _, m in ipairs(hl.get_monitors()) do
          if isInternal(m) then
            internal = internal or m
          elseif m.width * m.height > ${toString heavyExternalPixels} then
            heavy = true
          end
        end
        if not internal then return end

        -- Re-applying a mode is a real modeset, and a modeset re-enters this
        -- handler through monitor.added. Only act on a change.
        local want = heavy and "capped" or "preferred"
        if applied == want then return end
        applied = want

        -- Scale is read back off the live monitor rather than restated here,
        -- so the rule in ./home.nix stays the single definition of it. Passing
        -- the wrong one would silently resize every window on the panel.
        hl.monitor({
          output = internal.name,
          mode = heavy
            and string.format("%dx%d@${toString dockedRefresh}", internal.width, internal.height)
            or "preferred",
          position = "auto",
          scale = internal.scale,
        })
      end

      local function apply()
        if busy then return end
        busy = true
        pcall(work)
        busy = false
      end

      -- A freshly attached output is not finished being wired up when
      -- monitor.added fires, exactly as in ./workspaces.nix: the first pass
      -- catches what is already visible, the delayed one catches the rest.
      return function()
        apply()
        hl.timer(apply, { timeout = 400, type = "oneshot" })
      end
    end)()
  '';
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {
      capInternal = { _var = capInternal; };

      on = map (event: { _args = [ event (lua "capInternal") ]; }) [
        "config.reloaded"
        "monitor.added"
        "monitor.removed"
      ];
    };
  };
}
