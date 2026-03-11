#!/usr/bin/env bash
set -euo pipefail

mkdir -p /var/run/nut /var/state/nut /etc/nut

if [[ ! -f /etc/nut/upsd.conf ]]; then
  cat > /etc/nut/upsd.conf <<'CONF'
LISTEN 0.0.0.0 3493
CONF
fi

if [[ ! -f /etc/nut/nut.conf ]]; then
  cat > /etc/nut/nut.conf <<'CONF'
MODE=netserver
CONF
fi

exec "$@"
