#!/bin/bash

CONFIG_FILE="$HOME/.moto_build_tool.config"
BASHRC_FILE="$HOME/.bashrc"

RED='\e[31m'
GREEN_BOLD='\e[1;32m'
YELLOW_BOLD='\e[1;33m'
NC='\e[0m'

echo -e "${YELLOW_BOLD}===== Moto Build Tool Uninstall $MOTO_BUILD_TOOL_VERSION =====${NC}"
if grep -q "===== Moto Build Tool Setup $MOTO_BUILD_TOOL_VERSION =====" "$BASHRC_FILE"; then
    echo -e "${YELLOW_BOLD}Cleaning $BASHRC_FILE...${NC}"
    sed -i "/#===== Moto Build Tool Setup $MOTO_BUILD_TOOL_VERSION =====/,+2d" "$BASHRC_FILE"
    echo -e "✅${GREEN_BOLD} Lines removed from $BASHRC_FILE${NC}"
else
    echo -e "ℹ️ ${RED}No modification found $BASHRC_FILE${NC}"
fi

if [ -f "$CONFIG_FILE" ]; then
    rm "$CONFIG_FILE"
    echo -e "✅${GREEN_BOLD} Config file removed: $CONFIG_FILE${NC}"
else
    echo -e "ℹ️ ${RED}Any file config found.${NC}"
fi

echo -e "✅${GREEN_BOLD} Uninstall complete. Reset terminal to take effect${NC}"

