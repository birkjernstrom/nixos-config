{ config, lib, ... }:

with lib; let
  cfg = config.userSettings.hyprland;
  hypr = import ./lib.nix { inherit lib; };
  inherit (hypr) lua workspaceCount auxWorkspace;

  # Baseline so all eight exist from config load, before any event has fired:
  # an empty workspace with no object behind it has no monitor for the bar to
  # attribute it to, and nothing for `reflow` to place. `reflow` re-declares
  # these at runtime with a `monitor` attached once it knows the layout.
  persistentRules = map (i: { workspace = toString i; persistent = true; })
    (range 1 workspaceCount);

  # Keeps the workspace-to-monitor mapping fixed no matter which output a
  # window or a hotplug event lands on: the laptop panel owns `auxWorkspace`
  # alone and the big screen owns the rest, so SUPER+N always lands on the
  # same physical display.
  #
  # The mapping is expressed as workspace rules rather than as a batch of move
  # dispatches. Hyprland consults the rules in its own placement path, so it
  # stops inventing a replacement workspace every time we drain a monitor, and
  # the aux workspace stops being dragged onto the external on hotplug. The
  # dispatches that follow only relocate workspaces that already exist.
  reflow = lua ''
    (function()
      local reflowing = false

      local function pick(mons)
        if #mons < 2 then return nil, nil end

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
        if main then return main, internal end

        for _, m in ipairs(mons) do
          if not main or m.width * m.height > main.width * main.height then main = m end
        end
        for _, m in ipairs(mons) do
          if m ~= main and (not aux or m.width * m.height < aux.width * aux.height) then aux = m end
        end
        return main, aux
      end

      local function work()
        local mons = hl.get_monitors()
        if #mons == 0 then return end

        local main, aux = pick(mons)
        -- Undocked, the one remaining screen plays both roles. Re-pointing the
        -- rules at it matters more than it looks: a rule naming an output that
        -- has been unplugged strands its workspace with no monitor at all, so
        -- returning early here is what used to leave workspaces orphaned after
        -- the external was disconnected.
        if not (main and aux) then main, aux = mons[1], mons[1] end

        for i = 1, ${toString workspaceCount} do
          local target = (i == ${toString auxWorkspace}) and aux or main
          hl.workspace_rule({
            workspace = tostring(i),
            monitor = target.name,
            persistent = true,
            default = (i == 1 or i == ${toString auxWorkspace}),
          })
        end

        for _, ws in ipairs(hl.get_workspaces()) do
          if ws.id and ws.id > 0 and not ws.special then
            local target = (ws.id == ${toString auxWorkspace}) and aux or main
            if ws.monitor and ws.monitor.name ~= target.name then
              hl.dispatch(hl.dsp.workspace.move({ workspace = ws.id, monitor = target.name }))
            end
          end
        end
      end

      local function apply()
        -- The moves above re-enter this handler through workspace.created, so
        -- one hotplug would otherwise fan out into a storm of them. pcall is
        -- load-bearing rather than defensive: an error escaping with the flag
        -- still set would wedge it true and silently disable every future
        -- reflow for the rest of the session.
        if reflowing then return end
        reflowing = true
        pcall(work)
        reflowing = false
      end

      -- A freshly attached output is not finished being wired up when
      -- monitor.added fires - Hyprland gives it a scratch workspace before it
      -- announces the monitor at all. One pass now settles what is already
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
