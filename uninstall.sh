#!/bin/bash

CONFIG_FILE="$HOME/.moto_build_tool.config"
BASHRC_FILE="$HOME/.bashrc"

RED='\e[31m'
GREEN_BOLD='\e[1;32m'
YELLOW_BOLD='\e[1;33m'
NC='\e[0m'

echo -e "${YELLOW_BOLD}===== Moto Build Tool Uninstall $MOTO_BUILD_TOOL_VERSION =====${NC}"
if grep -q "#===== Moto Build Tool Setup" "$BASHRC_FILE"; then
    echo -e "${YELLOW_BOLD}Cleaning $BASHRC_FILE...${NC}"
    sed -i '/#===== Moto Build Tool Setup/,/#==============================/d' "$BASHRC_FILE"
    sed -i '/source ".*motoBuildTool\.sh"/d' "$BASHRC_FILE"
    sed -i '/export MOTO_BUILD_TOOL_VERSION=/d' "$BASHRC_FILE"
    echo -e "✅ ${GREEN_BOLD}All Moto Build Tool configurations removed from $BASHRC_FILE${NC}"
else
    echo -e "ℹ️ ${RED}No Moto Build Tool configurations found in $BASHRC_FILE${NC}"
fi

if [ -f "$CONFIG_FILE" ]; then
    rm -v "$CONFIG_FILE"
    echo -e "✅ ${GREEN_BOLD}Config file removed: $CONFIG_FILE${NC}"
else
    echo -e "ℹ️ ${RED}No config file found at $CONFIG_FILE${NC}"
fi

if [ -d "out" ]; then
    rm -rvf "out"
    echo -e "✅ ${GREEN_BOLD}Removed compiled files${NC}"
fi

echo -e "\n✅ ${GREEN_BOLD}Uninstall complete.${NC}"
echo -e "${YELLOW_BOLD}Please close and reopen your terminal to complete the cleanup.${NC}"