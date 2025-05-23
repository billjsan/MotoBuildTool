#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$HOME/.moto_build_tool.config"
BASHRC_FILE="$HOME/.bashrc"
FLASH_TOOL_FILE="$SCRIPT_DIR/motoBuildTool.sh"
VERSION="v0.3"

RED='\e[31m'
GREEN_BOLD='\e[1;32m'
YELLOW_BOLD='\e[1;33m'
NC='\e[0m'

is_sourced() {
    [[ "${BASH_SOURCE[0]}" != "${0}" ]]
}

echo -e "${YELLOW_BOLD}===== Moto Build Tool Setup $VERSION =====${NC}"
read -rp "Set your SSH host name (reston, ladybug): " SSH_HOST
read -rp "Set V remote build variant path: " BUILD_REMOTE_PATH_V
read -rp "Set W remote build variant path: " BUILD_REMOTE_PATH_W

cat > "$CONFIG_FILE" <<EOF
============ Moto build tool config file $VERSION ===========
===== Changing this file can cause bad functioning ======

=== remote config
SSH_HOST=$SSH_HOST
BUILD_REMOTE_PATH_V=$BUILD_REMOTE_PATH_V
BUILD_REMOTE_PATH_W=$BUILD_REMOTE_PATH_W
EOF

echo -e "✅ ${GREEN_BOLD}Config stored at: ${RED}$CONFIG_FILE${NC}"
if ! grep -Fxq "source \"$CONFIG_FILE\"" "$BASHRC_FILE"; then
    {
        echo ""
        echo "#===== Moto Build Tool Setup $VERSION ====="
        echo "source \"$FLASH_TOOL_FILE\""
        echo "export MOTO_BUILD_TOOL_VERSION=\"$VERSION\""
    } >> "$BASHRC_FILE"
    echo -e "✅ ${GREEN_BOLD}Build tool script sourced in $BASHRC_FILE${NC}"
fi

mkdir -p "$SCRIPT_DIR/out/log"
if is_sourced; then
    source "$FLASH_TOOL_FILE"
    source "$BASHRC_FILE"
    echo -e "✅ ${GREEN_BOLD}Flash tool loaded${NC}"
else
    echo -e "⚠️  ${YELLOW_BOLD}To use Moto Build Tool please run:${NC}"
    echo -e "${GREEN_BOLD}    source $BASHRC_FILE${NC}"
    echo -e "${YELLOW_BOLD}or reopen this terminal.${NC}"
fi