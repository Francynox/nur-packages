{
  pkgs,
  modules,
  ...
}:
pkgs.testers.runNixOSTest {
  name = "unbound";

  nodes.unbound =
    { pkgs, ... }:
    {
      imports = modules;

      environment.systemPackages = [ pkgs.francynox.bind ];

      services.francynox.unbound =
        let
          unboundConfFile = pkgs.writeText "unbound.conf" ''
            server:
              private-domain: "example.com"
              local-zone: "ns1.example.com" static
              local-data: "ns1.example.com A 127.0.0.1"
          '';
        in
        {
          enable = true;
          configFile = unboundConfFile;
        };
    };

  testScript = ''
    unbound.wait_for_unit("unbound.service")

    unbound.succeed("test -f /var/lib/unbound/root.key")

    unbound.succeed("dig @localhost ns1.example.com +short | grep 127.0.0.1")

    unbound.log(unbound.execute("systemd-analyze security unbound.service | grep 'exposure'")[1])
  '';
}
