# Remove GNOME

Goal: drop `services.desktopManager.gnome` and `services.displayManager.gdm`
from both hosts (`hosts/framework/configuration.nix`, `hosts/xps/configuration.nix`)
without losing anything the Hyprland session relies on. One step at a time,
rebuild and verify after each.

Shared replacements go in one module (e.g. `modules/nixos/session.nix`)
rather than duplicated per host.

## Done

- [x] Remove Noctalia (module, flake input, settings, references).

## Steps

### 1. Login screen: GDM -> greetd + tuigreet

- [x] `modules/nixos/greetd.nix`: greetd + tuigreet, `--cmd start-hyprland`,
  remembers user and session, lists `wayland-sessions`.
- [x] GDM and `defaultSession` removed from both hosts.
- [ ] Verify after rebuild + reboot: login, logout, suspend/resume, hyprlock
  still locks, keyring unlocked at login.
- [ ] Later (step 8): drop `services.xserver.enable`; keep
  `services.xserver.xkb` (used by `console.useXkbConfig`).

### 2. Polkit agent

- [x] Quickshell is the agent: `quickshell/Polkit/PolkitPrompt.qml`
  (`Quickshell.Services.Polkit`), themed like Pathway. hyprpolkitagent was
  tried first and dropped for looking unstyled.
- [ ] Verify: 1Password system unlock, `pkexec true`, popsicle drive listing.

### 3. Keyring

Keep `services.gnome.gnome-keyring.enable = true` standalone. greetd's PAM
stack includes `login`, which already gets `enableGnomeKeyring`, so unlock at
login needs nothing extra.

- Verify: Chromium, Slack, Zoom stay logged in across reboots.

### 4. Portals

`programs.hyprland` only adds xdg-desktop-portal-hyprland. Add
`xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ]` for file
chooser and the settings portal.

- Verify: file picker in browser/Slack, theme switch flips Chromium/Electron
  dark/light (`modules/nixos/themes/default.nix` color-scheme), screenshare.

### 5. File manager

`modules/nixos/hyprland/home.nix` binds `fileManager = nautilus`. Install
`pkgs.nautilus` explicitly, or switch (Thunar, Nemo, yazi).

### 6. Services GNOME enabled implicitly

- `services.gvfs.enable = true` (trash, MTP, smb in the file manager).
- `services.udisks2.enable = true` (automount; popsicle already sets it).
- Keep `programs.dconf.enable = true`; drop the `dconf` package and the
  "Only in case GNOME is enabled" comment.
- Already explicit, nothing to do: bluetooth, upower, power-profiles-daemon,
  NetworkManager.

### 7. Apps

Add back whatever GNOME apps are actually used (image viewer, video player,
calculator, archive manager, text editor). Zathura already covers PDFs.

### 8. Remove GNOME

Delete `services.desktopManager.gnome.enable` and the GDM lines from both
hosts. Then:

- Revisit `modules/nixos/stylix.nix` Qt target (disabled because of GNOME's
  Qt platform).
- Add `services.gnome.at-spi2-core.enable = true` only if accessibility-bus
  warnings show up.
- Compare closure size before/after.
