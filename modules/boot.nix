{ config, lib, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    useOSProber = true;
    configurationLimit = 3;
    gfxmodeEfi = "1920x1080";
    gfxmodeBios = "1920x1080";
    gfxpayloadEfi = "keep";

    backgroundColor = "#000000";
    splashImage = null;

    theme = pkgs.stdenv.mkDerivation {
      pname = "wuthering-grub-theme";
      version = "1.0";
      src = ../themes/wuthering-grub;
      installPhase = ''
        mkdir -p $out
        cp -a common/*.pf2 $out/
        cp -a config/theme-1080p.txt $out/theme.txt
        cp -a backgrounds/background-changli.jpg $out/background.jpg
        cp -a assets/assets-icons/icons-1080p $out/icons
        cp -a assets/assets-other/other-1080p/*.png $out/
      '';
    };
  };
  boot.plymouth = {
    enable = true;
    theme = "dragon";
    logo = pkgs.runCommand "transparent-logo.png" { buildInputs = [ pkgs.imagemagick ]; } ''
      convert -size 1x1 xc:transparent $out
    '';
    extraConfig = ''
      [Daemon]
      ShowDelay=0
      DeviceTimeout=8
    '';
    themePackages = [
      (pkgs.stdenv.mkDerivation {
        pname = "plymouth-theme-dragon";
        version = "1.0";
        src = ../themes/plymouth-dragon;
        buildInputs = [ pkgs.plymouth ];
        installPhase = ''
          dir=$out/share/plymouth/themes/dragon
          mkdir -p $dir
          cp -r * $dir/
          find $dir -type f \( -name "*.plymouth" -o -name "*.script" \) \
            -exec sed -i "s|/usr/share/plymouth/themes/dragon|$dir|g" {} +
        '';
      })
    ];
  };

  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;
  boot.initrd.systemd.enable = true;
  boot.initrd.availableKernelModules = [ "amdgpu" ];
  boot.initrd.kernelModules = [ "amdgpu" ];

  boot.kernelParams = [
    "amdgpu.sg_display=0"
    "bgrt_disable=1"
    "quiet"
    "splash"
    "logo.nologo"
    "fbcon=logo-count:0"
    "boot.shell_on_fail"
    "loglevel=3"
    "rd.systemd.show_status=false"
    "rd.udev.log_level=3"
    "udev.log_priority=3"
    "systemd.show_status=false"
    "vt.global_cursor_default=0"
    "video=efifb:off"
  ];
  boot.kernelModules = [ "kvm-amd" ];

  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;
}
