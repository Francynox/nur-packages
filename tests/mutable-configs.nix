{
  pkgs,
  modules,
  ...
}:
pkgs.testers.runNixOSTest {
  name = "mutable-configs";

  nodes = {
    machine =
      { pkgs, lib, ... }:
      {
        imports = modules;

        # Mock telegram-notify package
        services.francynox.telegram-notify = {
          enable = true;
          botTokenFile = "/etc/telegram-token";
          chatIdFile = "/etc/telegram-chat-id";
          package = pkgs.writeShellScriptBin "telegram-notify" ''
            echo "MOCK telegram-notify: $@" >> /tmp/telegram.log
            exit 0
          '';
        };

        # Mock the ExecStart of nixos-upgrade to do nothing
        systemd.services.nixos-upgrade.serviceConfig.ExecStart = lib.mkForce (
          pkgs.writeShellScript "mock-upgrade-exec" "echo MOCK UPGRADE EXEC; exit 0"
        );

        # Enable autoUpgrade so nixos-upgrade.service is generated
        system.autoUpgrade.enable = true;

        # Configure mock credentials
        environment.etc = {
          "telegram-token".text = "mock-telegram-token";
          "telegram-chat-id".text = "mock-telegram-chat-id";
        };

        # Enable mutable configs
        services.francynox.mutable-configs."test.conf" = {
          source = pkgs.writeText "test-source" "original-content\n";
          notifyOnUpgrade = true;
          stopAutoUpgrade = true;
        };
      };
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")

    # TEST CASE 1: No configuration drift
    # The target file /etc/test.conf matches pristine copy /etc/pristine/test.conf
    # nixos-upgrade.service should start and finish successfully
    machine.succeed("systemctl start nixos-upgrade.service")

    # TEST CASE 2: Configuration drift detected (local modification)
    # We modify /etc/test.conf so it differs from pristine
    machine.succeed("echo 'local-modification' > /etc/test.conf")

    # nixos-upgrade.service should now FAIL because of preStart check abort
    machine.fail("systemctl start nixos-upgrade.service")

    # Read telegram log to verify that the drift notification was sent
    telegram_log = machine.succeed("cat /tmp/telegram.log")
    machine.log(f"Telegram log content:\\n{telegram_log}")
    assert "Configuration Drift Detected" in telegram_log
    assert "test.conf" in telegram_log
    assert "Upgrade aborted" in telegram_log
  '';
}
