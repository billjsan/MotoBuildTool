#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
flashMotoApk() {
  RED='\e[31m'
  GREEN_BOLD='\e[1;32m'
  YELLOW_BOLD='\e[1;33m'
  NC='\e[0m'

  TAG="MotoBuildTool:"
  EXIT="exit"
  CUSTOM_FLAVOR="Custom"
  FLAVORS=("arcfox_g-userdebug" "boston_g-userdebug" "bronco_g-userdebug" "ctwo_g-userdebug" "cusco_g-userdebug" "fogo_g-userdebug" "fogos_g-userdebug" "lynkco_g-userdebug" "malmo_g-userdebug" "msi-userdebug" "paros_g-userdebug" "pnangn_g-userdebug" "rtwo_g-userdebug" "zeekr_g-userdebug" "$CUSTOM_FLAVOR" "$EXIT")

  CONFIG_FILE="$HOME/.moto_build_tool.config"
  touch "$CONFIG_FILE"
  SSH_HOST_KEY="SSH_HOST"
  BUILD_REMOTE_PATH_V_KEY="BUILD_REMOTE_PATH_V"
  BUILD_REMOTE_PATH_W_KEY="BUILD_REMOTE_PATH_W"

  echo -e "${GREEN_BOLD}========== Welcome to MotoBuildTool $MOTO_BUILD_TOOL_VERSION ==========${NC}"
  echo -e "⚠️ ${RED} This version only supports Qcom builds yet ${NC}⚠️"

  if grep -q "^${SSH_HOST_KEY}=" "$CONFIG_FILE"; then
    SSH_HOST=$(grep "^${SSH_HOST_KEY}=" "$CONFIG_FILE" | cut -d'=' -f2)
  else
    echo -e "❌ ${RED}Could not find $SSH_HOST_KEY value in config file. Please try reinstall Build Tool${NC}"
    echo -e "\a"
    return
  fi

  if grep -q "^${BUILD_REMOTE_PATH_V_KEY}=" "$CONFIG_FILE"; then
    BUILD_REMOTE_PATH_V=$(grep "^${BUILD_REMOTE_PATH_V_KEY}=" "$CONFIG_FILE" | cut -d'=' -f2)
  else
    echo -e "❌ ${RED}Could not find $BUILD_REMOTE_PATH_V_KEY value in config file. Please try reinstall Build Tool${NC}"
    echo -e "\a"
    return
  fi

  if grep -q "^${BUILD_REMOTE_PATH_W_KEY}=" "$CONFIG_FILE"; then
    BUILD_REMOTE_PATH_W=$(grep "^${BUILD_REMOTE_PATH_W_KEY}=" "$CONFIG_FILE" | cut -d'=' -f2)
  else
    echo -e "❌ ${RED}Could not find $BUILD_REMOTE_PATH_W_KEY value in config file. Please try reinstall Build Tool${NC}"
    echo -e "\a"
    return
  fi

  echo -e "📱 ${YELLOW_BOLD}Select a device:${NC}"
  select DEVICE in "${FLAVORS[@]}"; do
      [[ $DEVICE == "$EXIT" ]] && echo -e "🚫 ${RED}Cancelled.${NC}" && return
      [[ $DEVICE == "$CUSTOM_FLAVOR" ]] && echo -e "${YELLOW_BOLD}Enter custom device name:${NC}" && read -r DEVICE && echo -e "${YELLOW_BOLD}Device chose:""${RED}$DEVICE${NC}"
      [[ -n $DEVICE ]] && break
      echo -e "🚫 ${RED} Invalid option.${NC}"
  done

  echo -e "⚙️ ${YELLOW_BOLD} Select build variant:${NC}"
  select VERSION in "v_continous" "w_continous" "exit"; do
      [[ $VERSION == "exit" ]] && echo -e "🚫 ${RED} Cancelled." && return
      [[ -n $VERSION ]] && break
      echo -e "🚫 ${RED} Invalid option.${NC}"
  done

  echo -e "🤖 ${YELLOW_BOLD}Select APK:${NC}"
  select APK in "Settings" "TrafficStatsProvider" "TrafficStatsTests" "exit"; do
    [[ $APK == "exit" ]] && echo "Cancelled." && return
    [[ $APK == "Settings" || $APK == "TrafficStatsProvider" || $APK == "TrafficStatsTests" ]] && break
    echo -e "🚫 ${RED} Invalid option.${NC}"
  done

  echo -e "❓ ${YELLOW_BOLD}Do you want to include a patch before building the apk? (Y/n)${NC}"
  read -r INCLUDE_PATCH

  if [[ "$INCLUDE_PATCH" =~ ^[Yy]$ ]]; then
    read -rp "⚠️ Enter full cherry-pick command (e.g. git fetch ... && git cherry-pick FETCH_HEAD):" CHERRY_COMMAND
    echo -e "❓ ${YELLOW_BOLD} Reset HEAD before cherry-pick? (Y/n)${NC}"
    read -r RESET_BEFORE
  fi

  if [[ "$INCLUDE_PATCH" =~ ^[Nn]$ ]]; then
    echo -e "❓ ${YELLOW_BOLD}Update repo before building? (e.g. git pull origin bv/bw): (Y/n)${NC}"
    read -r FETCH_BEFORE
  fi

  if [[ "$FETCH_BEFORE" == "Y" || "$FETCH_BEFORE" == "y" ]]; then
    case "$VERSION" in
      "v_continous")
          FETCH_COMMAND="git fetch origin bv && git checkout bv && git pull origin bv"
          ;;
      "w_continous")
          FETCH_COMMAND="git fetch origin bw && git checkout bw && git pull origin bw"
          ;;
      *)
          echo -e "🚫 ${RED} Unknown version to fetch${NC}"
          exit 1
          ;;
    esac
  fi

  echo -e "▶️ ${YELLOW_BOLD} Start building: [${RED}$APK.apk${YELLOW_BOLD}] for: [${RED}$DEVICE ${YELLOW_BOLD}(${RED}$VERSION${YELLOW_BOLD})]${NC}"
  DEVICE_BASE=$(echo "$DEVICE" | cut -d'-' -f1 | cut -d'_' -f1)
  case "$APK" in
      "Settings")
          APK_REMOTE_RELATIVE_PATH="system/system_ext/priv-app/Settings"
          ;;
      "TrafficStatsProvider")
          APK_REMOTE_RELATIVE_PATH="product/priv-app/TrafficStatsProvider"
          ;;
      "TrafficStatsTests")
          APK_REMOTE_RELATIVE_PATH="testcases/TrafficStatsTests/arm64"
          ;;
      *)
          echo -e "🚫 ${RED} Unknown APK: $APK ${NC}"
          return
          ;;
  esac

  if [[ "$VERSION" == "v_continous" ]]; then
      BUILD_REMOTE_PATH="$BUILD_REMOTE_PATH_V"
  else
      BUILD_REMOTE_PATH="$BUILD_REMOTE_PATH_W"
  fi

  APK_REMOTE_PATH="${BUILD_REMOTE_PATH}/out/target/product/${DEVICE_BASE}/${APK_REMOTE_RELATIVE_PATH}/${APK}.apk"

  TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
  LOG_FILE="$SCRIPT_DIR/out/log/build_${APK}_${DEVICE}_${TIMESTAMP}.log"
  echo -e "🛠️ ${YELLOW_BOLD} Output will be logged to: ${GREEN_BOLD}$LOG_FILE ${NC}"

  ssh "$SSH_HOST" bash <<EOF > "$LOG_FILE" 2>&1
    cd "$BUILD_REMOTE_PATH"
    source build/envsetup.sh
    echo "${TAG}lunching:${DEVICE}"
    lunch "$DEVICE"
    if [[ "$INCLUDE_PATCH" == "Y" || "$INCLUDE_PATCH" == "y" ]]; then
      echo "${TAG}including a patch:${CHERRY_COMMAND}"
      case "$APK" in
        "Settings")
          cd packages/apps/Settings
        ;;
        "TrafficStatsProvider" | "TrafficStatsTests")
          cd motorola/cbs/tmo/packages/apps/EchoLocate
        ;;
        *)
        echo "${TAG}Unknown repo path for cherry-pick"
        exit 1
        ;;
      esac
      if [[ "$RESET_BEFORE" == "Y" || "$RESET_BEFORE" == "y" ]]; then
        echo "${TAG}removing top commit: git reset --hard HEAD~1"
        git reset --hard HEAD~1
      fi
      eval "$CHERRY_COMMAND"
      croot
    fi
    if [[ "$INCLUDE_PATCH" == "N" || "$INCLUDE_PATCH" == "n" ]]; then
      echo "${TAG} not including a patch"
      if [[ "$FETCH_BEFORE" == "Y" || "$FETCH_BEFORE" == "y" ]]; then
        case "$APK" in
          "Settings")
            cd packages/apps/Settings
          ;;
          "TrafficStatsProvider" | "TrafficStatsTests")
            cd motorola/cbs/tmo/packages/apps/EchoLocate
          ;;
          *)
          echo "${TAG}Unknown APK path for cherry-pick"
          exit 1
          ;;
        esac
        echo "${TAG}fetching before building:$FETCH_COMMAND"
        eval "$FETCH_COMMAND && croot"
      fi
    fi
  make "$APK"
  exit \$?
EOF
BUILD_RESULT=$?
if [[ $BUILD_RESULT -eq 0 ]]; then
    CONFIG_KEY="${VERSION}_${DEVICE}_${APK}"
    APK_PATH_RELATIVE=$(grep -oE "Install: .*${APK}.*\.apk" "$LOG_FILE" | tail -n 1 | cut -d' ' -f2)
    SECTION_HEADER="# apks outputs remote path"
    if [[ -z "$APK_PATH_RELATIVE" ]]; then
      echo -e "⚠️ ${YELLOW_BOLD} APK path not found in logs. Trying from config file...${NC}"
      if grep -q "^${CONFIG_KEY}=" "$CONFIG_FILE"; then
        APK_PATH_RELATIVE=$(grep "^${CONFIG_KEY}=" "$CONFIG_FILE" | cut -d'=' -f2)
        echo -e "📦 ${YELLOW_BOLD}APK path loaded from config:${GREEN_BOLD} $APK_PATH_RELATIVE ${NC}"
      else
        echo -e "❌ ${RED}Could not find APK path in log or config file.${NC}"
        echo -e "\a"
        return
      fi
    else
      echo "${TAG}APK path detected from log:$APK_PATH_RELATIVE" >> "$LOG_FILE" 2>&1
      if ! grep -q "^$SECTION_HEADER" "$CONFIG_FILE"; then
          echo -e "\n$SECTION_HEADER" >> "$CONFIG_FILE"
      fi
      sed -i "/^$CONFIG_KEY=/d" "$CONFIG_FILE"
      awk -v header="$SECTION_HEADER" -v key="$CONFIG_KEY" -v value="$APK_PATH_RELATIVE" '
          $0 == header {
              print
              print key "=" value
              next
          }
          { print }
      ' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    fi
    APK_REMOTE_PATH="${BUILD_REMOTE_PATH}/${APK_PATH_RELATIVE}"
    echo -e "✅ ${GREEN_BOLD}Build successful. Downloading apk to ${RED}$SCRIPT_DIR/out/ ${NC}"

    if scp "$SSH_HOST:$APK_REMOTE_PATH" "$SCRIPT_DIR/out/${APK}.apk" >> "$LOG_FILE" 2>&1 && \
    echo -e "✅ ${GREEN_BOLD}Download complete, flashing apk on attached device...${NC}" && \
    adb root >> "$LOG_FILE" 2>&1 && \
    adb remount >> "$LOG_FILE" 2>&1 && \
    adb install -r "$SCRIPT_DIR/out/${APK}.apk" >> "$LOG_FILE" 2>&1 && \
    adb reboot >> "$LOG_FILE" 2>&1; then
      echo -e '\a'
      echo -e "✅ ${GREEN_BOLD}Done!!!${NC}"
    else
      echo -e "❌ ${RED}An error occurred while downloading or flashing the apk${NC}"
      echo -e "📄 ${RED}Check the log file for details: ${GREEN_BOLD}$LOG_FILE${NC}"
      echo -e '\a'
    fi
else
  echo -e '\a'
  echo -e "❌ ${RED}Build failed!!! See details on log file:$LOG_FILE${NC}"
fi
}