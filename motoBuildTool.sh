#!/bin/bash

flashMotoApk() {
    echo "select device:"
    devices=("msi-userdebug" "exit")
    select DEVICE in "${devices[@]}"; do
        case $DEVICE in
            "msi-userdebug")
                break
                ;;
            "exit")
                echo "canceled."
                return
                ;;
            *)
                echo "invalid option."
                ;;
        esac
    done

    echo "select build variant:"
    versions=("v_continous" "w_continous" "exit")
    select VERSION in "${versions[@]}"; do
        case $VERSION in
            "v_continous"|"w_continous")
                break
                ;;
            "exit")
                echo "canceled."
                return
                ;;
            *)
                echo "invalid option."
                ;;
        esac
    done

    echo "select APK:"
    apks=("Settings" "TrafficStatsProvider" "TrafficStatsTests" "exit")
    select APK in "${apks[@]}"; do
        case $APK in
            "Settings"|"TrafficStatsProvider"|"TrafficStatsTests")
                break
                ;;
            "exit")
                echo "canceled."
                return
                ;;
            *)
                echo "invalid option."
                ;;
        esac
    done

    echo "Start building: [$APK] for: [$DEVICE ($VERSION)]"

    # Extrai o nome-base do device (sem o sufixo)
    DEVICE_BASE=$(echo "$DEVICE" | cut -d'-' -f1 | cut -d'_' -f1)

    # Define os caminhos com base no APK escolhido
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
            echo "Unknown APK: $APK"
            return
            ;;
    esac

    APK_REMOTE_PATH="/localrepo/willjsan/${VERSION}/out/target/product/${DEVICE_BASE}/${APK_REMOTE_RELATIVE_PATH}/${APK}.apk"
    
    ssh reston "
        cd /localrepo/willjsan/${VERSION} && \
        source build/envsetup.sh && \
        lunch ${DEVICE} && \
        make ${APK} && \
        echo 'Build Successful'
    " && \
    scp reston:"${APK_REMOTE_PATH}" "./${APK}.apk" && \
    adb root && \
    adb remount && \
    adb install -r "${APK}.apk" && \
    adb reboot && \
    echo -e '\a'

    echo "Done."
}

buldMSI() {
    echo "select a build version:"
        builds=("v_continous" "w_continous" "exit")
        select BUILD in "${builds[@]}"; do
            case $BUILD in
                "v_continous")
                    break
                    ;;
                "w_continous")
                    break
                    ;;
                "exit")
                    echo "canceled."
                    return
                    ;;
                *)
                    echo "invalid option."
                    ;;
            esac
    done
        
    echo "Start building: [$BUILD]]"
    ssh reston "
        cd /localrepo/willjsan/${BUILD} && \
        source build/envsetup.sh && \
        motorola/build/bin/build_device.bash -b release -p msi -g -j48 && \
        echo 'Build Successful'
    " && \
    scp reston:"/localrepo/willjsan/${BUILD}/release/" "./fastboot*.gz" && \
    echo -e '\a'

    echo "Done."

}
