#!/usr/bin/env bash
set -e

echo "[docker-init.sh] Starting container initialization..."

# Ensure the directory for EarnApp config exists
mkdir -p /etc/earnapp

# Write Docker's environment variable into /etc/earnapp/earnapp.conf
if [ -n "$EARNAPP_UUID" ]; then
  echo "[docker-init.sh] Writing EARNAPP_UUID=$EARNAPP_UUID to /etc/earnapp/earnapp.conf"
  echo "EARNAPP_UUID=$EARNAPP_UUID" > /etc/earnapp/earnapp.conf
else
  echo "[docker-init.sh] No EARNAPP_UUID provided."
  echo "# EARNAPP_UUID not set" > /etc/earnapp/earnapp.conf
fi

# Start systemd as PID 1
echo "[docker-init.sh] Launching systemd..."
exec /sbin/init 
