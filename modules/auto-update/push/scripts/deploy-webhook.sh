#!@runtimeShell@
set -e -o pipefail
export PATH=@path@

HOST="$1"
X_REAL_IP="$2"
TOKEN="$3"

VALID_TOKEN=$(cat "@tokenFile@" | tr -d '\n\r ')
if [ "$TOKEN" != "$VALID_TOKEN" ]; then
  echo "Error: Unauthorized token."
  exit 1
fi

if [ -z "$X_REAL_IP" ]; then
  echo "Error: Remote client IP missing from request headers."
  exit 1
fi

echo "Triggering deploy for host $HOST (detected IP: $X_REAL_IP)..."

# Start deployment service using host@ip template instance
/run/wrappers/bin/sudo systemctl start --no-block "deploy-host@$HOST@$X_REAL_IP"

