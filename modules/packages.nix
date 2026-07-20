{
  config,
  lib,
  pkgs,
  inputs,
  username,
  ...
}: let
  matugenPkg = inputs.matugen.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  environment.systemPackages = with pkgs; [
    wget
    git
    ghostty
    kitty
    fastfetch
    unzip
    go
    python3
    fish
    discord
    starship
    ripgrep
    fzf
    wf-recorder
    scrcpy

    kdePackages.dolphin
    kdePackages.qtsvg
    brave
    mangohud
    protonup-qt
    jetbrains-toolbox
    appimage-run
    devin-desktop

    inputs.nixpkgs-neovim.legacyPackages.${pkgs.stdenv.hostPlatform.system}.neovim
    android-tools
    jdk21
    tree-sitter
    nodejs_22
    clang
    ninja
    cmake
    pkg-config
    rustup
    just
    bun
    flutter
    gradle
    docker-compose
    openssl


    clang-tools
    typescript
    typescript-language-server
    taplo
    vue-language-server
    lua-language-server
    gopls
    gotools
    golines
    go-tools
    sqls
    lazygit
    gcc
    jdt-language-server
    rust-analyzer
    tailwindcss-language-server
    vscode-langservers-extracted
    stylua
    golangci-lint
    nixd
    alejandra
    kdePackages.qtdeclarative
    prettier
    ktfmt
    google-java-format
    rustfmt

    zed-editor-fhs
    code-cursor-fhs

    grim
    satty
    hyprpicker
    wl-clipboard
    cava
    matugenPkg
    awww
    brightnessctl
    cliphist
    imagemagick
    jq
    desktop-file-utils
    vlc
    ddcutil
    gpu-screen-recorder
    ffmpeg
    hypridle
    playerctl
    (symlinkJoin {
      name = "quickshell-wrapped";
      paths = [quickshell];
      nativeBuildInputs = [makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/qs \
          --prefix PATH : "${lib.makeBinPath [(python3.withPackages (ps: [ps.pyxdg])) bluez networkmanager wireplumber matugenPkg awww cava bash brightnessctl grim slurp satty hyprpicker wl-clipboard cliphist imagemagick jq desktop-file-utils ddcutil gpu-screen-recorder ffmpeg]}" \
          --prefix QML2_IMPORT_PATH : "${kdePackages.qt5compat}/lib/qt-6/qml" \
          --prefix QT_PLUGIN_PATH : "${kdePackages.qtimageformats}/lib/qt-6/plugins"
      '';
    })
    (writeShellScriptBin "rishot" ''
      exec /home/${username}/.config/rishot/bin/rishot "$@"
    '')
  ];
}
