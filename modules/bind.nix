{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.francynox.bind;
in
{
  options.services.francynox.bind = {
    enable = mkEnableOption "BIND DNS server (francynox NUR version)";

    package = mkOption {
      type = types.package;
      default = pkgs.francynox.bind;
      defaultText = literalExpression "pkgs.francynox.bind";
      description = "The BIND package (from francynox NUR) to use.";
    };

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to the main BIND configuration file (named.conf).";
      example = literalExpression "/path/to/your/named.conf";
    };

    zoneFiles = mkOption {
      type = types.attrsOf types.path;
      default = { };
      description = ''
        An attribute set of zone files to be copied into the zones directory. (/var/lib/bind)
        The attribute name will be the destination filename.
      '';
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
        message = "services.francynox.bind.configFile must be set when services.francynox.bind.enable is true.";
      }
    ];
    environment.systemPackages = [ cfg.package ];
    users.users.bind = {
      isSystemUser = true;
      group = "bind";
    };
    users.groups.bind = { };
    systemd.services.named = {
      description = "BIND Domain Name Server (francynox)";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      preStart = ''
        ${concatStringsSep "\n" (
          mapAttrsToList (
            destName: srcPath:
            ''cp -n ${srcPath} /var/lib/bind/${destName} && chmod 600 /var/lib/bind/${destName}''
          ) cfg.zoneFiles
        )}

        if [ ! -r /etc/bind/rndc.key ]; then
          echo "/etc/bind/rndc.key file not found or not readable by user 'bind'. Cannot start bind service.";
          exit 1;
        fi
      '';
      restartTriggers = cfg.extraRestartTriggers;
      serviceConfig = {
        Type = "notify";
        ExecStart = "${cfg.package}/bin/named -f -c ${cfg.configFile} ${escapeShellArgs cfg.extraArgs}";
        ExecReload = "${cfg.package}/bin/rndc reload";
        ExecStop = "${cfg.package}/bin/rndc stop";
        AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
        CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
        User = "bind";
        Group = "bind";
        ConfigurationDirectory = "bind";
        RuntimeDirectory = "named";
        RuntimeDirectoryPreserve = true;
        StateDirectory = "bind";
        CacheDirectory = "bind";
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
        RestrictAddressFamilies = [ "AF_UNIX AF_INET AF_INET6 AF_NETLINK" ];
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
