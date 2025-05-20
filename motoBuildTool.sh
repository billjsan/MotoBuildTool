#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
flashMotoApk() {
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
NC='\e[0m'

    echo -e "📱 ${YELLOW}Select device:${NC}"
    select DEVICE in "msi-userdebug" "exit"; do
        [[ $DEVICE == "exit" ]] && echo "Cancelled." && return
        [[ -n $DEVICE ]] && break
        echo -e "🚫 ${RED}Invalid option.${NC}"
    done

    echo -e "⚙️ ${YELLOW}Select build variant:${NC}"
    select VERSION in "v_continous" "w_continous" "exit"; do
        [[ $VERSION == "exit" ]] && echo "Cancelled." && return
        [[ -n $VERSION ]] && break
        echo -e "🚫 ${RED}Invalid option.${NC}"
    done

    echo -e "🤖 ${YELLOW}Select APK:${NC}"
    select APK in "Settings" "TrafficStatsProvider" "TrafficStatsTests" "exit"; do
        [[ $APK == "exit" ]] && echo "Cancelled." && return
        [[ $APK == "Settings" || $APK == "TrafficStatsProvider" || $APK == "TrafficStatsTests" ]] && break
        echo -e "🚫 ${RED}Invalid option.${NC}"
    done

    echo -e "❓ ${YELLOW}Do you want to include a patch before building the apk? (Y/n)${NC}"
    read -r INCLUDE_PATCH

    if [[ "$INCLUDE_PATCH" =~ ^[Yy]$ ]]; then
        read -rp "⚠️ ${YELLOW}Enter full cherry-pick command (e.g. git fetch ... && git cherry-pick FETCH_HEAD): ${NC}" CHERRY_COMMAND
        echo -e "❓ ${YELLOW}Reset HEAD before cherry-pick? (Y/n)${NC}"
        read -r RESET_BEFORE
    fi
    
    if [[ "$INCLUDE_PATCH" =~ ^[Nn]$ ]]; then
        echo -e "❓ ${YELLOW}Update repo before building? (e.g. git pull origin bv/bw): (Y/n)${NC}"
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
                echo -e "🚫 ${RED}Unknown version to fetch${NC}"
                exit 1
                ;;
        esac

    fi
    

    echo -e "▶️ ${YELLOW}Start building: [$APK] for: [$DEVICE ($VERSION)]${NC}"

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
            echo -e "🚫 ${RED}Unknown APK: $APK ${NC}"
            return
            ;;
    esac

    if [[ "$VERSION" == "v_continous" ]]; then
        BUILD_REMOTE_PATH="$BUILD_REMOTE_PATH_V"
    else
        BUILD_REMOTE_PATH="$BUILD_REMOTE_PATH_W"
    fi

    APK_REMOTE_PATH="${BUILD_REMOTE_PATH}/out/target/product/${DEVICE_BASE}/${APK_REMOTE_RELATIVE_PATH}/${APK}.apk"

    ssh "$SSH_HOST" bash <<EOF
cd "$BUILD_REMOTE_PATH"
source build/envsetup.sh
echo -e "🤖 ${YELLOW}lunching:$DEVICE${NC}"
lunch "$DEVICE"

if [[ "$INCLUDE_PATCH" == "Y" || "$INCLUDE_PATCH" == "y" ]]; then
    echo -e "ℹ️ ${YELLOW}including a patch${NC}"
    case "$APK" in
        "Settings")
            cd packages/apps/Settings
            ;;
        "TrafficStatsProvider" | "TrafficStatsTests")
            cd motorola/cbs/tmo/packages/apps/EchoLocate
            ;;
        *)
            echo -e "🚫 ${RED}Unknown APK path for cherry-pick ${NC}"
            exit 1
            ;;
    esac

    if [[ "$RESET_BEFORE" == "Y" || "$RESET_BEFORE" == "y" ]]; then
        echo -e "ℹ️ ${YELLOW}reseting before building: git reset --hard HEAD~1${NC}"
        git reset --hard HEAD~1
    fi

    eval "$CHERRY_COMMAND"
    croot
fi


if [[ "$INCLUDE_PATCH" == "N" || "$INCLUDE_PATCH" == "n" ]]; then
    echo -e "ℹ️ ${YELLOW}not including a patch ${NC}"
    if [[ "$FETCH_BEFORE" == "Y" || "$FETCH_BEFORE" == "y" ]]; then
        case "$APK" in
        "Settings")
            cd packages/apps/Settings
            ;;
        "TrafficStatsProvider" | "TrafficStatsTests")
            cd motorola/cbs/tmo/packages/apps/EchoLocate
            ;;
        *)
            echo -e "🚫 ${RED}Unknown APK path for cherry-pick ${NC}"
            exit 1
            ;;
    esac
        echo -e "ℹ️ ${YELLOW}fetching before building: $FETCH_COMMAND ${NC}"
        eval "$FETCH_COMMAND && croot"
    fi

fi

make "$APK"
EOF

    if [[ $? -eq 0 ]]; then
        echo -e "✅ ${GREEN}Build successful. Pulling APK... to $SCRIPT_DIR/out/ ${NC}"
        scp "$SSH_HOST:$APK_REMOTE_PATH" "$SCRIPT_DIR/out/${APK}.apk" && \
        adb root && \
        adb remount && \
        adb install -r "$SCRIPT_DIR/out/${APK}.apk" && \
        adb reboot && \
        echo -e '\a'
        echo -e "✅ ${GREEN}Done.${NC}"
    else
        echo -e '\a'
        echo -e "❌ ${RED}Build failed.${NC}"
    fi
}

