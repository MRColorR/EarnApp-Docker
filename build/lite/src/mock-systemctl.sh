#!/usr/bin/env bash
#
# A mock systemctl script for Docker containers without real systemd.
# Always returns success (exit 0) to satisfy calls like:
#   systemctl daemon-reload
#   systemctl enable earnapp
#   systemctl start earnapp


CMD=$1
shift

case "$CMD" in
  daemon-reload|enable|start|stop|restart|status)
    echo "[mock-systemctl] Pretending to '$CMD' service(s): $@"
    exit 0
    ;;
  *)
    echo "[mock-systemctl] Ignoring unknown subcommand '$CMD' with args: $@"
    exit 0
    ;;
esac
