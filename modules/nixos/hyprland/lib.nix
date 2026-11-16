# Helpers for expressing Hyprland's Lua configuration from Nix.
#
# With `configType = "lua"`, home-manager renders every attribute of
# `wayland.windowManager.hyprland.settings` into an `hl.<name>(...)` call:
# lists produce one call per element, an `_args` list produces a
# multi-argument call, `_var` produces a Lua local, and `mkLuaInline` values
# are emitted as raw Lua expressions.
{ lib }:

let
  inherit (lib.generators) mkLuaInline;
  toLua = lib.generators.toLua { };
in
rec {
  # How many workspaces exist, and which one is reserved for the laptop panel
  # when an external monitor is attached. Shared by ./bindings.nix (the SUPER+N
  # binds) and ./workspaces.nix (the persistent rules and the reflow handler);
  # the Quickshell bar hardcodes the same 8 in Bar/modules/Workspaces.qml.
  workspaceCount = 8;
  auxWorkspace = 8;

  # Raw Lua expression, passed through verbatim.
  lua = mkLuaInline;

  # A key combo prefixed with the `mainMod` Lua local: mod "SHIFT + Q".
  mod = keys: mkLuaInline ''mainMod .. " + ${keys}"'';

  # hl.bind(keys, dispatcher, { description = "Group: Action" }), listed in
  # Pathway's Keybinds. null keeps a bind out of that list.
  bind = description: keys: dispatcher: bindWith { } description keys dispatcher;

  # Same, with extra bind flags, e.g. `locked` (also fires while the session
  # is locked) and `repeating` (keeps firing while the key is held).
  bindWith = flags: description: keys: dispatcher:
    let opts = flags // lib.optionalAttrs (description != null) { inherit description; };
    in { _args = [ keys dispatcher ] ++ lib.optional (opts != { }) opts; };

  # hl.dsp.exec_cmd("<command>")
  exec = cmd: mkLuaInline "hl.dsp.exec_cmd(${toLua cmd})";

  # hl.dsp.exec_cmd(<lua expression>), for locals such as `terminal`.
  execLua = expr: mkLuaInline "hl.dsp.exec_cmd(${expr})";
}
