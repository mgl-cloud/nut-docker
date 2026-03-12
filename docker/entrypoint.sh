#!/usr/bin/env sh
set -eu

CONFIG_DIR=/etc/nut
DEFAULT_DIR=/usr/share/nut/default-config
STATE_DIR=/var/state/nut
RUN_DIR=/var/run/nut

mkdir -p "$CONFIG_DIR" "$STATE_DIR" "$RUN_DIR"

echo "Initializing NUT configuration..."

if ! id -u nut >/dev/null 2>&1; then
    addgroup -S nut
    adduser -S -G nut -H -h /var/lib/nut nut
fi

# 1️⃣ 如果配置目录为空，用 sample 初始化
if [ -z "$(ls -A "$CONFIG_DIR" 2>/dev/null)" ]; then
    echo "First start detected, installing sample configuration..."

    for src in "$DEFAULT_DIR"/*.sample; do
        name=$(basename "$src" .sample)
        cp "$src" "$CONFIG_DIR/$name"
    done

    # conf.d 目录
    if [ -d "$DEFAULT_DIR/conf.d" ]; then
        mkdir -p "$CONFIG_DIR/conf.d"
        cp -a "$DEFAULT_DIR/conf.d/." "$CONFIG_DIR/conf.d/"
    fi
fi

# 2️⃣ 确保核心配置存在
for f in nut.conf ups.conf upsd.conf upsd.users; do
    if [ ! -f "$CONFIG_DIR/$f" ]; then
        sample="$DEFAULT_DIR/$f.sample"
        if [ -f "$sample" ]; then
            echo "Installing missing $f"
            cp "$sample" "$CONFIG_DIR/$f"
        fi
    fi
done

# 3️⃣ 默认 MODE=netserver
if grep -q "^MODE=none" "$CONFIG_DIR/nut.conf" 2>/dev/null; then
    echo "Setting MODE=netserver"
    sed -i 's/^MODE=.*/MODE=netserver/' "$CONFIG_DIR/nut.conf"
fi

# 3.5️⃣ 确保 upsd 有 LISTEN
if ! grep -q "^LISTEN" "$CONFIG_DIR/upsd.conf" 2>/dev/null; then
    echo "Adding default LISTEN 0.0.0.0 3493"
    echo "LISTEN 0.0.0.0 3493" >> "$CONFIG_DIR/upsd.conf"
fi

# 4️⃣ 权限修复
chmod 640 "$CONFIG_DIR"/*.conf 2>/dev/null || true
chmod 640 "$CONFIG_DIR"/upsd.users 2>/dev/null || true
chmod 750 "$STATE_DIR" "$RUN_DIR"

echo "NUT initialization complete. Mode: ${MODE:-custom}. Starting: $*"

exec "$@"
