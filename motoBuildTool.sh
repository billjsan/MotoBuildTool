#!/bin/bash

flashMotoApk() {
    echo "select device:"
    devices=("msi-userdebug" "exit")
    select DEVICE in "${devices[@]}";
    	do
        case $DEVICE in
            "msi-userdebug") break ;;
            "exit") echo "canceled."; return ;;
            *) echo "invalid option." ;;
        esac
    done

    echo "select build variant:"
    versions=("v_continous" "w_continous" "exit")
    select VERSION in "${versions[@]}"; do
        case $VERSION in
            "v_continous"|"w_continous") break ;;
            "exit") echo "canceled."; return ;;
            *) echo "invalid option." ;;
        esac
    done

    echo "select APK:"
    apks=("Settings" "TrafficStatsProvider" "TrafficStatsTests" "exit")
    select APK in "${apks[@]}"; do
        case $APK in
            "Settings"|"TrafficStatsProvider"|"TrafficStatsTests") break ;;
            "exit") echo "canceled."; return ;;
            *) echo "invalid option." ;;
        esac
    done

    echo "Start building: [$APK] for: [$DEVICE ($VERSION)]"

    DEVICE_BASE=$(echo "$DEVICE" | cut -d'-' -f1 | cut -d'_' -f1)

    case "$APK" in
        "Settings")
            APK_REMOTE_RELATIVE_PATH="system/system_ext/priv-app/Settings"
            APK_DEVICE_PATH="system/system_ext/priv-app/Settings"
            ;;
        "TrafficStatsProvider")
            APK_REMOTE_RELATIVE_PATH="product/priv-app/TrafficStatsProvider"
            APK_DEVICE_PATH="product/priv-app/TrafficStatsProvider"
            ;;
        "TrafficStatsTests")
            APK_REMOTE_RELATIVE_PATH="testcases/TrafficStatsTests/arm64"
            APK_DEVICE_PATH="tmp"
            ;;
        *)
            echo "Unknown APK: $APK"; return ;;
    esac

    case "$VERSION" in
        "v_continous") BUILD_ROOT="$BUILD_REMOTE_PATH_V" ;;
        "w_continous") BUILD_ROOT="$BUILD_REMOTE_PATH_W" ;;
        *) echo "Invalid build version"; return ;;
    esac

    APK_REMOTE_PATH="${BUILD_ROOT}/out/target/product/${DEVICE_BASE}/${APK_REMOTE_RELATIVE_PATH}/${APK}.apk"

    ssh "$SSH_HOST" "
        cd \"$BUILD_ROOT\" && \
        source build/envsetup.sh && \
        lunch ${DEVICE} && \
        make ${APK} && \
        echo 'Build Successful'
    " && \
    scp "$SSH_HOST":"${APK_REMOTE_PATH}" "./${APK}.apk" && \
    adb root && \
    adb remount && \
    adb install -r "${APK}.apk" && \
    adb reboot && \
    echo -e '\a'

    echo "Done."
}

