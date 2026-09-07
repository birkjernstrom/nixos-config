{ config, lib, ... }:

with lib; let
  cfg = config.userSettings.hyprland;
  hypr = import ./lib.nix { inherit lib; };
  inherit (hypr) lua workspaceCount auxWorkspace;

  # Every workspace exists from startup, on both the pinned and the unpinned
  # side. Without this an empty workspace has no object for `reflow` to place
  # and no monitor for the bar to attribute it to, so pressing SUPER+N would
  # create it on whichever monitor happened to be focused - exactly the
  # behaviour this module exists to prevent.
  persistentRules = map (i: { workspace = toString i; persistent = true; })
    (range 1 workspaceCount);

  # Keeps the workspace-to-monitor mapping fixed no matter which output a
  # window or a hotplug event lands on: the laptop panel owns `auxWorkspace`
  # alone and the big screen owns the rest, so SUPER+N always lands on the
  # same physical display.
  #
  # Hyprland refuses to leave a monitor with no workspace at all - drain the
  # laptop first and it immediately steals one of the others back - so the aux
  # workspace is placed before the loop that sweeps everything else onto main.
  reflow = lua ''
    (function()
      local reflowing = false

      local function apply()
        if reflowing then return end

        local mons = hl.get_monitors()
        if #mons < 2 then return end

        -- The internal panel is the aux screen whenever it is attached, even
        -- if it out-resolutions what it is docked to; a desk with two
        -- externals and no laptop falls back to "biggest is main, smallest is
        -- aux".
        local internal, main, aux
        for _, m in ipairs(mons) do
          if not internal and (m.name:match("^eDP") or m.name:match("^LVDS") or m.name:match("^DSI")) then
            internal = m
          end
        end
        for _, m in ipairs(mons) do
          if m ~= internal and (not main or m.width * m.height > main.width * main.height) then
            main = m
          end
        end
        if main then
          aux = internal
        else
          for _, m in ipairs(mons) do
            if not main or m.width * m.height > main.width * main.height then main = m end
          end
          for _, m in ipairs(mons) do
            if m ~= main and (not aux or m.width * m.height < aux.width * aux.height) then aux = m end
          end
        end
        if not (main and aux) then return end

        -- The moves below re-enter this handler through workspace.created; the
        -- flag keeps one hotplug from fanning out into a storm of them.
        reflowing = true
        local function place(ws, target)
          if ws and ws.monitor and ws.monitor.name ~= target.name then
            hl.dispatch(hl.dsp.workspace.move({ workspace = ws.id, monitor = target.name }))
          end
        end
        place(hl.get_workspace(${toString auxWorkspace}), aux)
        for _, ws in ipairs(hl.get_workspaces()) do
          if ws.id > 0 and ws.id ~= ${toString auxWorkspace} and not ws.special then
            place(ws, main)
          end
        end
        reflowing = false
      end

      -- A freshly attached output is not finished being wired up when
      -- monitor.added fires - Hyprland hands it a workspace only after the
      -- handler returns, and the re-entrancy guard swallows the
      -- workspace.created that follows. One pass now settles what is already
      -- visible, one pass afterwards settles the rest.
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
      # Rendered as `local reflow = (...)()` ahead of every hl.* call, so the
      # subscriptions below can name it.
      reflow = { _var = reflow; };

      workspace_rule = persistentRules;

      # config.reloaded covers startup and `hyprctl reload`; the monitor events
      # cover docking and undocking; workspace.created catches an id above
      # workspaceCount being opened by a window rule or a dispatcher.
      on = map (event: { _args = [ event (lua "reflow") ]; }) [
        "config.reloaded"
        "monitor.added"
        "monitor.removed"
        "workspace.created"
      ];
    };
  };
}
