# .config / Dotfiles

User dotfiles managed via **Home Manager** alongside the NixOS configuration.

## Structure

```
.config/
├── hypr/           → ~/.config/hypr/         (Hyprland window manager)
├── ghostty/        → ~/.config/ghostty/      (Ghostty terminal emulator)
├── cava/           → ~/.config/cava/         (Cava audio visualizer)
├── nvim/           → ~/.config/nvim/         (Neovim NvChad config)
├── quickshell/     → ~/.config/quickshell/   (Quickshell desktop panels)
├── fish/           → ~/.config/fish/         (Fish shell interactive config)
├── matugen/        → ~/.config/matugen/      (Matugen wallpaper color scheme templates)
├── brave-theme/    → ~/.config/brave-theme/  (Dynamic theme templates for Brave browser)
└── rishot/         → ~/.config/rishot/       (Rishot utility binary wrapper)
```

Symlinks are managed automatically by Home Manager on every `nixos-rebuild switch`.
They point **directly** to this directory (not through the Nix store), so any edits you make here are live — no rebuild needed for dotfile changes.

---

## NixOS Configuration Features

### 1. Neovim Setup
- **Background Transparency:** Configured NvChad with a default transparent background. Added hotkey `<leader>tt` to toggle transparency.
- **Telescope Search:** Configured to include hidden folders (like `.config/`) when searching for files.
- **Auto-Tags:** Added automatic tag closing and renaming support for TypeScript, TSX, React, and other frameworks via `nvim-ts-autotag`.

### 2. Gaming Setup
- **Steam:** Installed with standard firewall rule openings for remote play and local game transfers.
- **32-Bit Graphics Support:** Enabled to allow Steam/Proton games to run correctly on modern GPUs.
- **GameMode:** System-wide daemon optimizations are active during active gaming sessions.
- **Flatpak:** Configured system-wide support to install Roblox (via the Sober runtime).

---

## How to Apply & Rebuild

Remove existing configurations first (one-time command to avoid home-manager collision errors):

```bash
rm -rf ~/.config/{hypr,ghostty,cava,nvim,quickshell,fish,matugen,brave-theme,rishot}
```

Then rebuild and switch:

```bash
cd ~/nixos-config
sudo nixos-rebuild switch --flake .#XyrelTenz
```

Home Manager will create the symlinks automatically as part of the switch.

> **Tip:** After setup, edit any config directly in `~/nixos-config/.config/` — changes take effect immediately without rebuilding!
