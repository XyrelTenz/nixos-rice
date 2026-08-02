## Previews

  > Preview 1
![Neovim Preview 1](preview/preview1.png)

  > Preview 2
![Neovim Preview 2](preview/preview2.png)

<!-- # Neovim -->
## Installation
 > Install requires Neovim nightly but might works on latest stable release. Always review the code before installing a configuration.

 > Make sure you delete or backup your old neovim configuration to somewhere safe before installing this one.


### Backup for linux & MacOS

```bash
# required
mv ~/.config/nvim{,.bak}

# optional but recommended
mv ~/.local/share/nvim{,.bak}
mv ~/.local/state/nvim{,.bak}
mv ~/.cache/nvim{,.bak}
```

### Backup for Windows

```bash
# required
Move-Item $env:LOCALAPPDATA\nvim $env:LOCALAPPDATA\nvim.bak

# optional but recommended
Move-Item $env:LOCALAPPDATA\nvim-data $env:LOCALAPPDATA\nvim-data.bak
```

### Installation for Linux & MacOS

```bash
git clone https://github.com/XyrelTenz/nvim.git ~/.config/nvim
```

### Installation for Windows

```bash
git clone https://github.com/XyrelTenz/nvim.git $env:LOCALAPPDATA\nvim
```
