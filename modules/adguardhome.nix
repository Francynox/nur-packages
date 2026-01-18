{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.francynox.adguardhome;
in
{
  options.services.francynox.adguardhome = {
    enable = lib.mkEnableOption "AdGuard Home DNS ad-blocker (francynox NUR version)";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.francynox.adguardhome;
      defaultText = lib.literalExpression "pkgs.francynox.adguardhome";
      description = "The AdGuard Home package (from francynox NUR) to use.";
    };

    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to the main AdGuard Home configuration file (AdGuardHome.yaml).";
      example = lib.literalExpression "/path/to/your/AdGuardHome.yaml";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of additional command-line arguments to pass to the AdGuard Home daemon.";
    };

    extraRestartTriggers = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "A list of extra derivations to trigger a service restart when changed.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.configFile != null;
        message = "services.francynox.adguardhome.configFile must be set when services.francynox.adguardhome.enable is true.";
      }
    ];
    environment.systemPackages = [ cfg.package ];
    users.users.adguardhome = {
      isSystemUser = true;
      group = "adguardhome";
    };
    users.groups.adguardhome = { };
    systemd.services.adguardhome =
      let
        workDir = "/var/lib/adguardhome";
        pidFile = "/run/adguardhome/AdGuardHome.pid";
        configFile = "${workDir}/AdGuardHome.yaml";
      in
      {
        description = "AdGuard Home DNS ad-blocker (francynox)";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        preStart = ''
          set -e

          ORIGINAL_CONFIG_FILE="${cfg.configFile}"
          WORKING_FILE="${configFile}"

          cp -n "$ORIGINAL_CONFIG_FILE" "$WORKING_FILE"
          chmod 600 "$WORKING_FILE"
        '';
        restartTriggers = cfg.extraRestartTriggers;
        serviceConfig = {
          ExecStart = "${cfg.package}/bin/adguardhome -c ${configFile} --work-dir ${workDir} --pidfile ${pidFile} --no-check-update -s run ${lib.escapeShellArgs cfg.extraArgs}";
          WorkingDirectory = workDir;
          AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
          CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
          User = "adguardhome";
          Group = "adguardhome";
          RuntimeDirectory = "adguardhome";
          RuntimeDirectoryPreserve = true;
          StateDirectory = "adguardhome";
          StateDirectoryMode = "0700";
          Restart = "on-failure";
          # Security
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
          PrivateMounts = true;
          ProtectHostname = true;
          ProtectClock = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectKernelLogs = true;
          ProtectControlGroups = true;
          ProtectProc = "invisible";
          ProcSubset = "pid";
          RemoveIPC = true;
          RestrictAddressFamilies = [ "AF_INET AF_INET6 AF_NETLINK AF_PACKET" ];
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          RestrictNamespaces = true;
          SystemCallArchitectures = "native";
          SystemCallFilter = "~@clock @cpu-emulation @debug @module @mount @obsolete @privileged @raw-io @reboot @resources @swap";
        };
      };
  };
}
