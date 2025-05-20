#!/bin/bash

CONFIG_FILE="$HOME/.moto_build_tool.config"
BASHRC_FILE="$HOME/.bashrc"

echo "== Moto Build Tool Uninstall =="


if grep -q 'Moto Build Tool Setup' "$BASHRC_FILE"; then
    echo "Clining $BASHRC_FILE..."
    sed -i '/# Moto Build Tool Setup/,+2d' "$BASHRC_FILE"
    echo "✅ Lines removed from $BASHRC_FILE"
else
    echo "ℹ️ No modification found $BASHRC_FILE"
fi


if [ -f "$CONFIG_FILE" ]; then
    rm "$CONFIG_FILE"
    echo "Config file removed: $CONFIG_FILE"
else
    echo "ℹ️ Any file config found."
fi

echo "✅ Uninstall complete. Reset terminal to take efect"

