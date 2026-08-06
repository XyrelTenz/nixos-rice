{
  config,
  lib,
  pkgs,
  ...
}: {
  networking.hostName = "XyrelTenz";
  networking.networkmanager.enable = true;
  networking.firewall.trustedInterfaces = ["wlo1"];
}
