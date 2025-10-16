{
  pkgs,
  modules,
  ...
}:
pkgs.testers.runNixOSTest {
  name = "kea";

  nodes = {
    router =
      { pkgs, ... }:
      {
        imports = modules;

        virtualisation.vlans = [ 1 ];

        networking = {
          useDHCP = false;
          firewall.allowedUDPPorts = [ 67 ];
        };

        systemd.network = {
          enable = true;
          networks = {
            "01-eth1" = {
              name = "eth1";
              networkConfig = {
                Address = "10.0.0.1/29";
              };
            };
          };
        };

        services.francynox.kea.dhcp4 = {
          enable = true;
          configFile = pkgs.writeText "kea-dhcp4-test.conf" ''
            {
              "Dhcp4": {
                "interfaces-config": {
                  "dhcp-socket-type": "raw",
                  "interfaces": [ "eth1" ]
                },
                "lease-database": {
                  "type": "memfile",
                  "persist": true,
                  "name": "/var/lib/kea/dhcp4.leases"
                },
                "control-sockets": [
                  {
                    "socket-type": "unix",
                    "socket-name": "/run/kea/dhcp4.sock"
                  }
                ],
                "valid-lifetime": 3600,
                "renew-timer": 900,
                "rebind-timer": 1800,
                "subnet4": [
                  {
                    "id": 1,
                    "subnet": "10.0.0.0/29",
                    "pools": [
                      {
                        "pool": "10.0.0.3 - 10.0.0.3"
                      }
                    ]
                  }
                ],
                "dhcp-ddns": {
                  "enable-updates": true
                },
                "ddns-send-updates": true,
                "ddns-qualifying-suffix": "lan.nixos.test."
              }
            }
          '';
        };

        services.francynox.kea.dhcp-ddns = {
          enable = true;
          configFile = pkgs.writeText "kea-ddns-test.conf" ''
            {
              "DhcpDdns": {
                "forward-ddns": {
                  "ddns-domains": [
                    {
                      "name": "lan.nixos.test.",
                      "key-name": "",
                      "dns-servers": [
                        {
                          "ip-address": "10.0.0.2",
                          "port": 53
                        }
                      ]
                    }
                  ]
                }
              }
            }
          '';
        };
      };

    nameserver =
      { pkgs, ... }:
      {
        imports = modules;

        virtualisation.vlans = [ 1 ];

        networking = {
          useDHCP = false;
          firewall.allowedUDPPorts = [ 53 ];
        };

        systemd.network = {
          enable = true;
          networks = {
            "01-eth1" = {
              name = "eth1";
              networkConfig = {
                Address = "10.0.0.2/29";
              };
            };
          };
        };

        services.resolved.enable = false;

        environment.etc."bind/rndc.key" = {
          source = pkgs.runCommand "rndc.key" { } ''
            ${pkgs.bind}/bin/rndc-confgen -a -c $out
          '';
          mode = "0640";
          group = "bind";
        };

        services.francynox.bind =
          let
            zoneFile = pkgs.writeText "lan.nixos.test" ''
              $TTL 1D
              @       IN      SOA     ns1.nixos.test. root.nixos.test. (
                                      2024010101 ; Serial
                                      1D         ; Refresh
                                      1H         ; Retry
                                      1W         ; Expire
                                      3H )       ; Negative Cache TTL
              ;
                      IN      NS      ns1.nixos.test.
              nameserver     IN      A       10.0.0.3
              router         IN      A       10.0.0.1
            '';

            namedConfFile = pkgs.writeText "named-test.conf" ''
              options {
                directory "/var/cache/bind";
                empty-zones-enable no;
              };
              zone "lan.nixos.test" {
                type master;
                file "${zoneFile}";
                journal "/var/lib/bind/db.lan.nixos.test.jnl";
                allow-update { 10.0.0.1; };
              };
            '';
          in
          {
            enable = true;
            configFile = namedConfFile;
          };
      };

    client =
      { pkgs, ... }:
      {
        virtualisation.vlans = [ 1 ];
        systemd.services.systemd-networkd.environment.SYSTEMD_LOG_LEVEL = "debug";
        networking = {
          useNetworkd = true;
          useDHCP = false;
          firewall.enable = false;
          interfaces.eth1.useDHCP = true;
        };
      };
  };
  testScript =
    { ... }:
    ''
      start_all()
      router.wait_for_unit("kea-dhcp4.service")
      router.wait_for_unit("kea-dhcp-ddns.service")

      client.systemctl("start systemd-networkd-wait-online.service")
      client.wait_for_unit("systemd-networkd-wait-online.service")

      client.wait_until_succeeds("ping -c 5 10.0.0.1", timeout = 60)
      router.wait_until_succeeds("ping -c 5 10.0.0.3", timeout = 60)

      nameserver.wait_until_succeeds("dig +short client.lan.nixos.test @10.0.0.2 | grep -q 10.0.0.3", timeout = 60)

      router.log(router.execute("systemd-analyze security kea-dhcp4.service | grep 'exposure'")[1])
      router.log(router.execute("systemd-analyze security kea-dhcp-ddns.service | grep 'exposure'")[1])
    '';
}
