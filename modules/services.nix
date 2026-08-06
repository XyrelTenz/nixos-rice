{
  config,
  lib,
  pkgs,
  username,
  ...
}: {
  virtualisation.docker.enable = true;

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    ensureDatabases = ["driveapp"];
    ensureUsers = [
      {
        name = username;
        ensureClauses.superuser = true;
      }
    ];
  };

  systemd.services.system76-power-balanced = {
    description = "Select the System76 balanced power profile";
    wantedBy = ["multi-user.target"];
    after = ["com.system76.PowerDaemon.service"];
    wants = ["com.system76.PowerDaemon.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.system76-power}/bin/system76-power profile balanced";
      RemainAfterExit = true;
    };
  };
}
