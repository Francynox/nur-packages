{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.francynox.kea;

  commonServiceConfig = {
    User = "kea";
    Group = "kea";
    ConfigurationDirectory = "kea";
    RuntimeDirectory = "kea";
    RuntimeDirectoryPreserve = true;
    RuntimeDirectoryMode = "0750";
    StateDirectory = "kea";
    CacheDirectory = "kea";
    Restart = "on-failure";
    ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
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
    RestrictAddressFamilies = [ "AF_UNIX AF_INET AF_INET6 AF_NETLINK AF_PACKET" ];
    LockPersonality = true;
    MemoryDenyWriteExecute = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    RestrictNamespaces = true;
    SystemCallArchitectures = "native";
    SystemCallFilter = "~@clock @cpu-emulation @debug @module @mount @obsolete @privileged @raw-io @reboot @resources @swap";
  };
in
{
  options.services.francynox.kea = {
    package = mkOption {
      type = types.package;
      default = pkgs.francynox.kea;
      defaultText = literalExpression "pkgs.francynox.kea";
      description = "The Kea package (from francynox NUR) to use for all Kea services.";
    };

    ctrl-agent = mkOption {
      description = "Kea Control Agent configuration. (francynox NUR version)";
      default = { };
      type = types.submodule {
        options = {
          enable = mkEnableOption "Kea Control Agent daemon";
          extraArgs = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "List of additional arguments to pass to the daemon.";
          };
          configFile = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "Path to the Kea Control Agent configuration file.";
            example = literalExpression "/path/to/your/kea-ctrl-agent.json";
          };
          extraRestartTriggers = mkOption {
            type = types.listOf types.path;
            default = [ ];
            description = "A list of extra derivations to trigger a service restart when changed.";
          };
        };
      };
    };

    dhcp4 = mkOption {
      description = "Kea DHCPv4 Server configuration. (francynox NUR version)";
      default = { };
      type = types.submodule {
        options = {
          enable = mkEnableOption "Kea DHCPv4 server";
          extraArgs = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Additional arguments.";
          };
          configFile = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "Path to the Kea DHCPv4 configuration file.";
            example = literalExpression "/path/to/your/kea-dhcp4.json";
          };
          extraRestartTriggers = mkOption {
            type = types.listOf types.path;
            default = [ ];
            description = "A list of extra derivations to trigger a service restart when changed.";
          };
        };
      };
    };

    dhcp6 = mkOption {
      description = "Kea DHCPv6 Server configuration. (francynox NUR version)";
      default = { };
      type = types.submodule {
        options = {
          enable = mkEnableOption "Kea DHCPv6 server";
          extraArgs = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Additional arguments.";
          };
          configFile = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "Path to the Kea DHCPv6 configuration file.";
            example = literalExpression "/path/to/your/kea-dhcp6.json";
          };
          extraRestartTriggers = mkOption {
            type = types.listOf types.path;
            default = [ ];
            description = "A list of extra derivations to trigger a service restart when changed.";
          };
        };
      };
    };

    dhcp-ddns = mkOption {
      description = "Kea DHCP-DDNS module configuration. (francynox NUR version)";
      default = { };
      type = types.submodule {
        options = {
          enable = mkEnableOption "Kea DHCP-DDNS server";
          extraArgs = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Additional arguments.";
          };
          configFile = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "Path to the Kea DHCP-DDNS configuration file.";
            example = literalExpression "/path/to/your/kea-dhcp-ddns.json";
          };
          extraRestartTriggers = mkOption {
            type = types.listOf types.path;
            default = [ ];
            description = "A list of extra derivations to trigger a service restart when changed.";
          };
        };
      };
    };
  };

  config =
    mkIf
      (any (component: component.enable) [
        cfg.ctrl-agent
        cfg.dhcp4
        cfg.dhcp6
        cfg.dhcp-ddns
      ])
      (mkMerge [
        {
          environment.systemPackages = [ cfg.package ];
          users.users.kea = {
            isSystemUser = true;
            group = "kea";
          };
          users.groups.kea = { };
        }

        (mkIf cfg.ctrl-agent.enable {
          assertions = [
            {
              assertion = cfg.ctrl-agent.configFile != null;
              message = "services.francynox.kea.ctrl-agent.configFile must be set when services.francynox.kea.ctrl-agent.enable is true.";
            }
          ];
          systemd.services."kea-ctrl-agent" = {
            description = "Kea Control Agent (francynox)";
            after = [
              "network-online.target"
              "time-sync.target"
            ];
            wants = [ "network-online.target" ];
            environment = {
              KEA_PIDFILE_DIR = "/run/kea";
              KEA_LOCKFILE_DIR = "/run/kea";
            };
            restartTriggers = cfg.ctrl-agent.extraRestartTriggers;
            serviceConfig = {
              ExecStart = "${cfg.package}/bin/kea-ctrl-agent -c ${cfg.ctrl-agent.configFile} ${escapeShellArgs cfg.ctrl-agent.extraArgs}";
              KillMode = "process";
            }
            // commonServiceConfig;
          };
        })

        (mkIf cfg.dhcp4.enable {
          assertions = [
            {
              assertion = cfg.dhcp4.configFile != null;
              message = "services.francynox.kea.dhcp4.configFile must be set when services.francynox.kea.dhcp4.enable is true.";
            }
          ];
          systemd.services."kea-dhcp4" = {
            description = "Kea DHCPv4 Server (francynox)";
            after = [
              "network-online.target"
              "time-sync.target"
            ];
            wants = [
              "network-online.target"
            ];
            wantedBy = [ "multi-user.target" ];
            environment = {
              KEA_PIDFILE_DIR = "/run/kea";
              KEA_LOCKFILE_DIR = "/run/kea";
            };
            restartTriggers = cfg.dhcp4.extraRestartTriggers;
            serviceConfig = {
              ExecStart = "${cfg.package}/bin/kea-dhcp4 -c ${cfg.dhcp4.configFile} ${escapeShellArgs cfg.dhcp4.extraArgs}";
              AmbientCapabilities = [
                "CAP_NET_BIND_SERVICE"
                "CAP_NET_RAW"
              ];
              CapabilityBoundingSet = [
                "CAP_NET_BIND_SERVICE"
                "CAP_NET_RAW"
              ];
            }
            // commonServiceConfig;
          };
        })

        (mkIf cfg.dhcp6.enable {
          assertions = [
            {
              assertion = cfg.dhcp6.configFile != null;
              message = "services.francynox.kea.dhcp6.configFile must be set when services.francynox.kea.dhcp6.enable is true.";
            }
          ];
          systemd.services."kea-dhcp6" = {
            description = "Kea DHCPv6 Server (francynox)";
            after = [
              "network-online.target"
              "time-sync.target"
            ];
            wants = [
              "network-online.target"
            ];
            wantedBy = [ "multi-user.target" ];
            environment = {
              KEA_PIDFILE_DIR = "/run/kea";
              KEA_LOCKFILE_DIR = "/run/kea";
            };
            restartTriggers = cfg.dhcp6.extraRestartTriggers;
            serviceConfig = {
              ExecStart = "${cfg.package}/bin/kea-dhcp6 -c ${cfg.dhcp6.configFile} ${escapeShellArgs cfg.dhcp6.extraArgs}";
              AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
              CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
            }
            // commonServiceConfig;
          };
        })

        (mkIf cfg.dhcp-ddns.enable {
          assertions = [
            {
              assertion = cfg.dhcp-ddns.configFile != null;
              message = "services.francynox.kea.dhcp-ddns.configFile must be set when services.francynox.kea.dhcp-ddns.enable is true.";
            }
          ];
          systemd.services."kea-dhcp-ddns" = {
            description = "Kea DHCP-DDNS Server (francynox)";
            after = [
              "network-online.target"
              "time-sync.target"
            ];
            wants = [
              "network-online.target"
            ];
            wantedBy = [ "multi-user.target" ];
            environment = {
              KEA_PIDFILE_DIR = "/run/kea";
              KEA_LOCKFILE_DIR = "/run/kea";
            };
            restartTriggers = cfg.dhcp-ddns.extraRestartTriggers;
            serviceConfig = {
              ExecStart = "${cfg.package}/bin/kea-dhcp-ddns -c ${cfg.dhcp-ddns.configFile} ${escapeShellArgs cfg.dhcp-ddns.extraArgs}";
              AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
              CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
            }
            // commonServiceConfig;
          };
        })
      ]);
}
