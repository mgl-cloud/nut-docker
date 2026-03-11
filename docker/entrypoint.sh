#!/usr/bin/env sh
set -eu

mkdir -p /var/run/nut /var/state/nut /etc/nut

DEFAULT_CONFIG_DIR="/usr/share/nut/default-config"

if [ -d "$DEFAULT_CONFIG_DIR" ]; then
  find "$DEFAULT_CONFIG_DIR" -mindepth 1 -maxdepth 1 | while IFS= read -r src; do
    name=$(basename "$src")
    dst="/etc/nut/$name"

    if [ ! -e "$dst" ]; then
      cp -a "$src" "$dst"
    fi
  done
fi

if [ ! -f /etc/nut/upsd.conf ]; then
  cat > /etc/nut/upsd.conf <<'CONF'
LISTEN 0.0.0.0 3493
CONF
fi

if [ ! -f /etc/nut/nut.conf ]; then
  cat > /etc/nut/nut.conf <<'CONF'
MODE=netserver
CONF
fi

exec "$@"
