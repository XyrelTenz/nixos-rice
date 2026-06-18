{ config, lib, pkgs, ... }:

{
  networking.hostName = "XyrelTenz";
  networking.networkmanager.enable = true;

  # Trust the wireless interface to allow hotspot client connections (DHCP/DNS)
  networking.firewall.trustedInterfaces = [ "wlo1" ];
}
