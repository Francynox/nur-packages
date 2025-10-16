{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.francynox.unbound;
in
{
  options.services.francynox.unbound = {
    enable = mkEnableOption "Unbound DNS recursor (francynox NUR version)";

    package = mkOption {
      type = types.package;
      default = pkgs.francynox.unbound;
      defaultText = literalExpression "pkgs.francynox.unbound";
      description = "The Unbound package (from francynox NUR) to use.";
    };

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to the main Unbound configuration file (unbound.conf).";
      example = literalExpression "/path/to/your/unbound.conf";
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of additional command-line arguments to pass to the named daemon.";
    };

    extraRestartTriggers = mkOption {
      type = types.listOf types.path;
      default = [ ];
      description = "A list of extra derivations to trigger a service restart when changed.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.configFile != null;
        message = "services.francynox.unbound.configFile must be set when services.francynox.unbound.enable is true.";
      }
    ];
    environment.systemPackages = [ cfg.package ];
    users.users.unbound = {
      isSystemUser = true;
      group = "unbound";
    };
    users.groups.unbound = { };
    systemd.services.unbound =
      let
        configFile = pkgs.writeText "unbound.conf" ''
          server:
            chroot: ""
            username: ""
            root-hints: "${pkgs.dns-root-data}/root.hints"

            include: "${cfg.configFile}"
        '';
      in
      {
        description = "Unbound DNS recursor (francynox)";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        preStart = ''
          until ${cfg.package}/bin/unbound-anchor; do
            echo "unbound-anchor failed, new try in 5 seconds..." >&2
            sleep 5
          done
        '';
        restartTriggers = cfg.extraRestartTriggers;
        serviceConfig = {
          Type = "notify";
          ExecStart = "${cfg.package}/bin/unbound -d -c ${configFile} ${escapeShellArgs cfg.extraArgs}";
          ExecReload = "${cfg.package}/bin/unbound-control reload";
          ExecStop = "${cfg.package}/sbin/unbound-control stop";
          AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
          CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
          User = "unbound";
          Group = "unbound";
          ConfigurationDirectory = "unbound";
          RuntimeDirectory = "unbound";
          RuntimeDirectoryPreserve = true;
          StateDirectory = "unbound";
          CacheDirectory = "unbound";
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
          RestrictAddressFamilies = [ "AF_UNIX AF_INET AF_INET6" ];
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
