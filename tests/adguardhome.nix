{
  pkgs,
  modules,
  ...
}:
pkgs.testers.runNixOSTest {
  name = "adguardhome";

  nodes = {
    adguardhome =
      { pkgs, ... }:
      {
        imports = modules;

        environment.systemPackages = [ pkgs.francynox.bind ];

        services.francynox.adguardhome =
          let
            adguardHomeConfig = pkgs.writeText "AdGuardHome.yaml" ''
              http:
                address: 0.0.0.0:80
              dns:
                bootstrap_dns:
                  - 1.1.1.1
              filtering:
                rewrites:
                  - domain: test.home.arpa
                    answer: 10.10.10.10
              schema_version: 29
            '';
          in
          {
            enable = true;
            configFile = adguardHomeConfig;
          };
      };
  };
  testScript =
    { ... }:
    ''
      adguardhome.wait_for_unit("adguardhome.service")
      adguardhome.wait_for_open_port(80, timeout = 15)

      adguardhome.succeed("curl -s http://localhost:80/ | grep 'AdGuard Home'")

      adguardhome.succeed("dig @localhost test.home.arpa +short | grep 10.10.10.10")

      adguardhome.log(adguardhome.execute("systemd-analyze security adguardhome.service | grep 'exposure'")[1])
    '';
}
