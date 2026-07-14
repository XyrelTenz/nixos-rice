{ config, pkgs, lib, username, ... }:

let
  repoPath = "/home/${username}/nixos-config/.config";
in
{
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "26.05";

  home.packages = [
    # Android Studio's SDK is used, no need for Nix-managed SDK package here
  ];

  home.sessionVariables = {
    ANDROID_HOME = "/home/${username}/Android/Sdk";
    ANDROID_SDK_ROOT = "/home/${username}/Android/Sdk";
    ANDROID_AVD_HOME = "/home/${username}/.config/.android/avd";
    _JAVA_OPTIONS = "-Dorg.gradle.projectcachedir=$HOME/.gradle/project-cache";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.cargo/bin"
    "$HOME/Android/Sdk/cmdline-tools/latest/bin"
    "$HOME/Android/Sdk/emulator"
    "$HOME/Android/Sdk/platform-tools"
  ];

  home.activation.linkDotfiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    _linkConfig() {
      local src="${repoPath}/$1"
      local dst="$HOME/.config/$2"
      mkdir -p "$(dirname "$dst")"
      rm -rf "$dst"
      ln -sfn "$src" "$dst"
    }

    _linkConfig "hypr"                "hypr"
    _linkConfig "ghostty"             "ghostty"
    _linkConfig "cava"                "cava"
    _linkConfig "nvim"                "nvim"
    _linkConfig "quickshell"          "quickshell"
    _linkConfig "fish"                "fish"
    _linkConfig "matugen"             "matugen"
    _linkConfig "brave-theme"          "brave-theme"
    _linkConfig "rishot"               "rishot"

    # Starship config lives at ~/.config/starship.toml
    ln -sfn "${repoPath}/starship.toml" "$HOME/.config/starship.toml"

    # Link fastfetch lantern logo and config template
    mkdir -p "$HOME/.config/fastfetch"
    ln -sfn "${repoPath}/fastfetch/lantern.txt" "$HOME/.config/fastfetch/lantern.txt"
    ln -sfn "${repoPath}/fastfetch/config.jsonc.in" "$HOME/.config/fastfetch/config.jsonc.in"

    # Create placeholders for matugen and ricelin cache outputs to prevent startup crashes
    mkdir -p "$HOME/.cache/matugen"
    touch "$HOME/.cache/matugen/ghostty-colors"
    touch "$HOME/.cache/matugen/hypr-colors.lua"
    mkdir -p "$HOME/.cache/ricelin"
    touch "$HOME/.cache/ricelin/colors.json"
    touch "$HOME/.cache/ricelin/ghostty-colors"
    touch "$HOME/.cache/ricelin/hypr-colors.lua"
    touch "$HOME/.cache/ricelin/tmux-colors.conf"
  '';

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
  };

  systemd.user.services.hypridle = {
    Unit = {
      Description = "Hyprland idle daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.hypridle}/bin/hypridle";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
