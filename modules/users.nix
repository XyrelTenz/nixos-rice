{ config, lib, pkgs, username, ... }:

{
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "adbusers" "kvm" ];
    shell = pkgs.fish;
  };
}
