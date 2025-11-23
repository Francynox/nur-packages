{
  pkgs,
  modules,
  ...
}:
pkgs.testers.runNixOSTest {
  name = "bind";

  nodes.bind =
    { pkgs, ... }:
    {
      imports = modules;

      environment.etc."bind/rndc.key" = {
        source = pkgs.runCommand "rndc.key" { } ''
          ${pkgs.bind}/bin/rndc-confgen -a -c $out
        '';
        mode = "0640";
        group = "bind";
      };

      services.francynox.bind =
        let
          zoneFile = pkgs.writeText "db.example.com" ''
            $TTL 1D
            @       IN      SOA     ns1.example.com. root.example.com. (
                                    1          ; Serial
                                    1D         ; Refresh
                                    1H         ; Retry
                                    1W         ; Expire
                                    3H )       ; Negative Cache TTL
            ;
                    IN      NS      ns1.example.com.
            ns1     IN      A       127.0.0.1
          '';

          namedConfFile = pkgs.writeText "named-test.conf" ''
            options {
              directory "/var/cache/bind";
              empty-zones-enable no;
            };
            zone "example.com" {
              type master;
              file "/var/lib/bind/db.example.com";

              allow-update { localhost; };
            };
          '';
        in
        {
          enable = true;
          configFile = namedConfFile;
          zoneFiles = {
            "db.example.com" = zoneFile;
          };
        };
    };

  testScript =
    { ... }:
    ''
      def run_checks():
        bind.wait_for_unit("named.service")
        bind.wait_for_open_port(53)

        bind.succeed("test -f /var/lib/bind/db.example.com")

        bind.succeed("dig @localhost ns1.example.com +short | grep 127.0.0.1")

        cmd_update = """
        echo -e 'server 127.0.0.1
        zone example.com
        update add client.example.com 3600 A 127.0.0.2
        send' | nsupdate
        """
        bind.succeed(cmd_update)

        bind.succeed("dig @localhost client.example.com +short | grep 127.0.0.2")

        bind.succeed("rndc sync")
        bind.wait_until_succeeds("grep -q client.example.com /var/lib/bind/db.example.com")

      def security_score():
        security_score = bind.succeed("systemd-analyze security named.service --no-pager")
        bind.log(f"Security Analysis:\n{security_score}")
        if "UNSAFE" in security_score:
          raise Exception("Bind service security level is UNSAFE!")

      start_all()

      with subtest("Run Basic Checks"):
        run_checks()

      with subtest("Verify hardening"):
        security_score()

      with subtest("Verify Service Reload"):
        bind.succeed("systemctl reload named.service")
        run_checks()

      with subtest("Verify Service Restart"):
        bind.succeed("systemctl restart named.service")
        run_checks()
    '';
}
