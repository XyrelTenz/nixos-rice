# .config

User dotfiles managed via **Home Manager** alongside the NixOS configuration.

## Structure

```
.config/
├── hypr/                → ~/.config/hypr/         (Hyprland)
├── kitty/               → ~/.config/kitty/        (Terminal)
├── cava/                → ~/.config/cava/          (Visualizer)
├── nvim/                → ~/.config/nvim/          (Neovim / NvChad)
└── quickshell/
    └── Apertura/        → ~/.config/quickshell/Apertura/  (Shell UI)
```

Symlinks are managed automatically by Home Manager on every `nixos-rebuild switch`.
They point **directly** to this directory (not through the Nix store), so any edits
you make here are live — no rebuild needed for dotfile changes.

## How it works

`home.nix` uses `mkOutOfStoreSymlink` to tell Home Manager to create symlinks like:

```
~/.config/hypr  →  ~/nixos-config/.config/hypr
~/.config/nvim  →  ~/nixos-config/.config/nvim
...
```

## Apply / Rebuild

Remove the existing dirs first (one-time), then rebuild:

```bash
rm -rf ~/.config/hypr ~/.config/kitty ~/.config/cava ~/.config/nvim ~/.config/quickshell/Apertura

cd ~/nixos-config
sudo nixos-rebuild switch --flake .#XyrelTenz
```

Home Manager will create the symlinks automatically as part of the switch.

> **Tip:** After setup, edit any config directly in `~/nixos-config/.config/` — 
> changes take effect immediately without rebuilding.
