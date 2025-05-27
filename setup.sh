#!/bin/bash

VERSION="v0.4"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
CONFIG_FILE="$HOME/.moto_build_tool.config"
BASHRC_FILE="$HOME/.bashrc"
FLASH_TOOL_FILE="$SCRIPT_DIR/motoBuildTool.sh"

SSH_HOST_KEY="SSH_HOST"
BUILD_REMOTE_PATH_V_KEY="BUILD_REMOTE_PATH_V"
BUILD_REMOTE_PATH_W_KEY="BUILD_REMOTE_PATH_W"

RED='\e[31m'
GREEN_BOLD='\e[1;32m'
YELLOW_BOLD='\e[1;33m'
NC='\e[0m'

is_sourced() {
  [[ "${BASH_SOURCE[0]}" != "${0}" ]]
}

echo -e "${YELLOW_BOLD}===== Moto Build Tool Setup $VERSION =====${NC}"
touch "$CONFIG_FILE"

ensure_remote_config_section_exists() {
  if ! grep -q "^=== remote config" "$CONFIG_FILE"; then
    echo -e "\n=== remote config" >> "$CONFIG_FILE"
    echo -e "# Remote build configuration" >> "$CONFIG_FILE"
  fi
}

update_remote_config() {
  local key="$1"
  local prompt="$2"
  local new_val=""
  local section_start section_end
  ensure_remote_config_section_exists

  section_start=$(grep -n "^=== remote config" "$CONFIG_FILE" | cut -d':' -f1)
  section_end=$(awk -v start="$section_start" 'NR > start && /^# Remote build configuration/{print NR; exit}' "$CONFIG_FILE")
  [[ -z "$section_end" ]] && section_end=$(wc -l < "$CONFIG_FILE")

  local current_val
  current_val=$(sed -n "${section_start},${section_end}p" "$CONFIG_FILE" | grep "^${key}=" | cut -d'=' -f2-)

  if [[ -n "$current_val" ]]; then
    echo -e "⚠️  ${YELLOW_BOLD}$key is currently set to: ${RED}${current_val}${NC}"
    read -rp "Do you want to update it? [Y/n]: " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      read -rp "$prompt: " new_val
      sed -i "${section_start},${section_end}{/^${key}=/d;}" "$CONFIG_FILE"
      sed -i "${section_start}a\\${key}=${new_val}" "$CONFIG_FILE"
    else
      echo -e "✅ ${GREEN_BOLD}Keeping existing $key.${NC}"
    fi
  else
    read -rp "$prompt: " new_val
    sed -i "${section_start}a\\${key}=${new_val}" "$CONFIG_FILE"
  fi
}

update_remote_config "$SSH_HOST_KEY" "Set your SSH host name (reston, ladybug)"
update_remote_config "$BUILD_REMOTE_PATH_V_KEY" "Set V remote build variant path"
update_remote_config "$BUILD_REMOTE_PATH_W_KEY" "Set W remote build variant path"

ensure_bash_config_section_exists() {
  if ! grep -q "^#===== Moto Build Tool Setup" "$BASHRC_FILE"; then
    echo -e "\n#===== Moto Build Tool Setup =====" >> "$BASHRC_FILE"
    echo "source \"$FLASH_TOOL_FILE\"" >> "$BASHRC_FILE"
    echo "export MOTO_BUILD_TOOL_VERSION=\"$VERSION\"" >> "$BASHRC_FILE"
    echo "#==============================" >> "$BASHRC_FILE"
  fi
}

update_bash_config() {
  local section_start section_end
  ensure_bash_config_section_exists

  section_start=$(grep -n "^#===== Moto Build Tool Setup" "$BASHRC_FILE" | cut -d':' -f1)
  section_end=$(awk -v start="$section_start" 'NR > start && /^#==============================/{print NR; exit}' "$BASHRC_FILE")
  [[ -z "$section_end" ]] && section_end=$(wc -l < "$BASHRC_FILE")

  # Atualiza o source do script se necessário
  if ! grep -q "source \"$FLASH_TOOL_FILE\"" "$BASHRC_FILE"; then
    sed -i "${section_start}a\\source \"$FLASH_TOOL_FILE\"" "$BASHRC_FILE"
  fi

  # Sempre atualiza a versão
  if grep -q "export MOTO_BUILD_TOOL_VERSION=" "$BASHRC_FILE"; then
    sed -i "s/export MOTO_BUILD_TOOL_VERSION=.*/export MOTO_BUILD_TOOL_VERSION=\"$VERSION\"/" "$BASHRC_FILE"
  else
    sed -i "${section_start}a\\export MOTO_BUILD_TOOL_VERSION=\"$VERSION\"" "$BASHRC_FILE"
  fi
}

update_bash_config

echo -e "✅ ${GREEN_BOLD}Remote config updated in: ${RED}$CONFIG_FILE${NC}"
echo -e "✅ ${GREEN_BOLD}Build tool configuration updated in $BASHRC_FILE${NC}"
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