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
    def run_checks():
      unbound.wait_for_unit("unbound.service")
      unbound.wait_for_open_port(53)

      unbound.succeed("test -f /var/lib/unbound/root.key")

      unbound.succeed("test -S /run/unbound/unbound.ctl")

      unbound.succeed("dig @localhost ns1.example.com +short | grep 127.0.0.1")

    def security_score():
      security_score = unbound.succeed("systemd-analyze security unbound.service --no-pager")
      unbound.log(f"Security Analysis:\n{security_score}")
      if "UNSAFE" in security_score:
        raise Exception("Unbound service security level is UNSAFE!")

    start_all()

    with subtest("Run Basic Checks"):
      run_checks()

    with subtest("Verify hardening"):
      security_score()

    with subtest("Verify Service Reload"):
      unbound.succeed("systemctl reload unbound.service")
      run_checks()

    with subtest("Verify Service Restart"):
      unbound.succeed("systemctl restart unbound.service")
      run_checks()
  '';
}
