#!@runtimeShell@
set -e -o pipefail
export PATH=@path@

INSTANCE="$1"
HOST="${INSTANCE%%@*}"
IP="${INSTANCE##*@}"

TARGET_USER="@targetUser@"
TELEGRAM_NOTIFY="@telegramNotifyBin@"

# Per-host lock to prevent concurrent deploys
LOCK_FILE="/run/deploy-webhook/deploy-${HOST}.lock"
exec 200>"$LOCK_FILE"
if ! flock -n 200; then
  echo "Error: Deploy already in progress for host $HOST. Skipping."
  exit 1
fi

notify() {
  local msg="$1"
  if [ -n "$TELEGRAM_NOTIFY" ] && [ -x "$TELEGRAM_NOTIFY" ]; then
    "$TELEGRAM_NOTIFY" "$msg" || true
  fi
}

handle_exit() {
  exit_code=$?
  if [ $exit_code -eq 0 ]; then
    notify "✅ *Deploy successful*: $HOST"
  else
    notify "❌ *Deploy failed*: $HOST"
  fi
}
trap handle_exit EXIT

export NIX_SSHOPTS="-i @sshKeyFile@ -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/run/deploy-webhook/known_hosts"

echo "Building and deploying configuration to attribute #$HOST at IP $IP as user $TARGET_USER..."
nixos-rebuild switch \
  --target-host "$TARGET_USER@$IP" \
  --use-remote-sudo \
  --flake "@flakePath@#$HOST"

echo "Triggering reboot check on target host $HOST at IP $IP..."
ssh $NIX_SSHOPTS "$TARGET_USER@$IP" "sudo systemctl start --no-block push-reboot-detector"
