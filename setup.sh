#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$HOME/.moto_build_tool.config"
BASHRC_FILE="$HOME/.bashrc"
FLASH_TOOL_FILE="$SCRIPT_DIR/motoBuildTool.sh"

is_sourced() {
    [[ "${BASH_SOURCE[0]}" != "${0}" ]]
}

echo "== Moto build tool setup =="

read -rp "Set your SSH host name (reston, ladybug): " SSH_HOST
read -rp "Set V remote build variant path: " BUILD_REMOTE_PATH_V
read -rp "Set W remote build variant path: " BUILD_REMOTE_PATH_W

cat > "$CONFIG_FILE" <<EOF
# Moto build tool config file
export SSH_HOST="$SSH_HOST"
export BUILD_REMOTE_PATH_V="$BUILD_REMOTE_PATH_V"
export BUILD_REMOTE_PATH_W="$BUILD_REMOTE_PATH_W"
EOF

echo "✅ Config stored at $CONFIG_FILE"

if ! grep -Fxq "source \"$CONFIG_FILE\"" "$BASHRC_FILE"; then
    {
        echo ""
        echo "# Moto Build Tool Setup"
        echo "source \"$CONFIG_FILE\""
        echo "source \"$FLASH_TOOL_FILE\""
    } >> "$BASHRC_FILE"
    echo "✅ Config and tool script sourced in $BASHRC_FILE"
fi


mkdir -p "$SCRIPT_DIR/out"
echo "✅ 'out/' folder created at $SCRIPT_DIR"

if is_sourced; then
    source "$CONFIG_FILE"
    source "$FLASH_TOOL_FILE"
    echo "✅ Enviroment variables loaded"
else
    echo "⚠️  To use this variables please run:"
    echo "    source $CONFIG_FILE"
    echo "or reopen this terminal."
fi

