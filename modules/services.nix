{ config, lib, pkgs, username, ... }:

{

  virtualisation.docker.enable = true;

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    ensureDatabases = [ "driveapp" ];
    ensureUsers = [
      {
        name = username;
        ensureClauses.superuser = true;
      }
    ];
  };
}
