{ config, lib, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [ "amdgpu.sg_display=0" ];
  boot.kernelModules = [ "kvm-amd" ];

  # CachyOS kernel (latest, x86_64-v1 default — binary cache via flake nixConfig)
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;
}
