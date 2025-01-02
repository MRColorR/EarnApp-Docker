#!/usr/bin/env bash
set -e

echo "[Entrypoint] Setting up EarnApp at runtime..."

# 1) Make sure /etc/earnapp exists for storing config
mkdir -p /etc/earnapp
chmod a+wr /etc/earnapp/
touch /etc/earnapp/status
chmod a+wr /etc/earnapp/status

# 2) If EARNAPP_UUID is specified at runtime, write it to /etc/earnapp/uuid
# e.g. `docker run -e EARNAPP_UUID=myUUID earnapp:latest`
if [ -n "$EARNAPP_UUID" ]; then
  echo "[Entrypoint] Using EARNAPP_UUID=$EARNAPP_UUID"
  echo "$EARNAPP_UUID" > /etc/earnapp/uuid
else
  echo "[Entrypoint] No EARNAPP_UUID provided. EarnApp will generate a new one."
fi

# 3) Check if EarnApp is already installed (i.e., if /usr/bin/earnapp exists)
if [ ! -x /usr/bin/earnapp ]; then
  echo "[Entrypoint] EarnApp not installed; fetching official installer..."
  wget -qO /tmp/earnapp.sh https://brightdata.com/static/earnapp/install.sh

  # Optionally, remove the "-y" to require interactive acceptance.
  # But usually in Docker, we do "-y" to skip the TOS prompt.
  echo "[Entrypoint] Running official EarnApp installer..."
  bash /tmp/earnapp.sh -y || {
    echo "ERROR: EarnApp installer failed." >&2
    exit 1
  }
else
  echo "[Entrypoint] EarnApp already installed."
fi

# 4) Finally, execute the container's main CMD (e.g., "earnapp start && ...")
echo "[Entrypoint] Starting main command: $*"
exec "$@"
