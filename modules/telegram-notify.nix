{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.francynox.telegram-notify;

  telegramNotifyScript = pkgs.writeShellScriptBin "telegram-notify" ''
    if [ "$#" -ne 1 ]; then
      echo "Usage: telegram-notify \"<message>\""
      exit 1
    fi

    if [ ! -f "${cfg.botTokenFile}" ]; then
      echo "Error: Bot token file not found at ${cfg.botTokenFile}"
      exit 1
    fi

    if [ ! -f "${cfg.chatIdFile}" ]; then
      echo "Error: Chat ID file not found at ${cfg.chatIdFile}"
      exit 1
    fi

    BOT_TOKEN=$(cat "${cfg.botTokenFile}")
    CHAT_ID=$(cat "${cfg.chatIdFile}")
    MESSAGE="$1"

    ${pkgs.curl}/bin/curl -s -X POST "https://api.telegram.org/bot''${BOT_TOKEN}/sendMessage" \
      -d chat_id="''${CHAT_ID}" \
      -d text="''${MESSAGE}" \
      -d parse_mode="Markdown" > /dev/null
  '';
in
{
  options.services.francynox.telegram-notify = {
    enable = mkEnableOption "Telegram notification service";

    botTokenFile = mkOption {
      type = types.path;
      description = "Path to the file containing the Telegram bot token.";
    };

    chatIdFile = mkOption {
      type = types.path;
      description = "Path to the file containing the Telegram chat ID.";
    };

    package = mkOption {
      type = types.package;
      internal = true;
      default = telegramNotifyScript;
      description = "Package containing the Telegram notification script.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
  };
}
