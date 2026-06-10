{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # ── Core System Tools ────────────────────────────────────────────────
    wget
    git
    kitty
    rofi
    fastfetch
    unzip
    go
    python3

    # ── Desktop & Apps ───────────────────────────────────────────────────
    kdePackages.dolphin
    kdePackages.qtsvg
    waybar
    firefox

    # ── Development & Android ────────────────────────────────────────────
    neovim
    android-tools
    tree-sitter
    flutter
    nodejs_22
    clang
    ninja
    cmake
    pkg-config

    # ── LSPs & Formatters ────────────────────────────────────────────────
    clang-tools
    typescript
    typescript-language-server
    vue-language-server
    lua-language-server
    gopls
    golines
    go-tools
    sqls
    lazygit
    gcc
    dart
    jdt-language-server
    rust-analyzer
    slint-lsp
    tailwindcss-language-server
    vscode-langservers-extracted
    stylua
    golangci-lint
    nixd
    alejandra
    kdePackages.qtdeclarative

    # ── Apertura / Aesthetics ────────────────────────────────────────────
    grim
    slurp
    satty
    cava
    matugen
    awww

    # ── Quickshell (wrapped with runtime deps) ───────────────────────────
    (symlinkJoin {
      name = "quickshell-wrapped";
      paths = [ quickshell ];
      nativeBuildInputs = [ makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/qs \
          --prefix PATH : "${lib.makeBinPath [ (python3.withPackages (ps: [ ps.pyxdg ])) bluez networkmanager wireplumber matugen awww cava ]}" \
          --prefix QML2_IMPORT_PATH : "${kdePackages.qt5compat}/lib/qt-6/qml"
      '';
    })
  ];
}
