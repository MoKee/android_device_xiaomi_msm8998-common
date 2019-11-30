#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

MK_ROOT="${MY_DIR}"/../../..

HELPER="${MK_ROOT}/vendor/mokee/build/tools/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
    vendor/etc/init/vendor.xiaomi.hardware.mtdservice@1.2-service.rc)
        sed -i '/group/ i\    user system' "${2}"
        ;;
    vendor/etc/permissions/qti_libpermissions.xml)
        sed -i 's|name=\"android.hidl.manager-V1.0-java|name=\"android.hidl.manager@1.0-java|g' "${2}"
        ;;
    vendor/lib/libMiCameraHal.so)
        sed -i 's/libicuuc.so/libicuuQ.so/g' "${2}"
        sed -i 's/libminikin.so/libminikiQ.so/g' "${2}"
        ;;
    vendor/lib/libminikiQ.so)
        sed -i 's/libminikin.so/libminikiQ.so/g' "${2}"
        ;;
    vendor/lib/libicuuQ.so)
        sed -i 's/libicuuc.so/libicuuQ.so/g' "${2}"
        ;;
    vendor/lib/libFaceGrade.so)
        patchelf --remove-needed "libandroid.so" "${2}"
        ;;
    vendor/lib/libarcsoft_beauty_shot.so)
        patchelf --remove-needed "libandroid.so" "${2}"
        ;;
    vendor/lib/libmmcamera2_stats_modules.so)
        patchelf --remove-needed "libandroid.so" "${2}"
        ;;
    vendor/lib/libmpbase.so)
        patchelf --remove-needed "libandroid.so" "${2}"
        ;;
    esac
}

# Initialize the helper for common device
setup_vendor "${DEVICE_COMMON}" "${VENDOR}" "${MK_ROOT}" true "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" \
        "${KANG}" --section "${SECTION}"

if [ -s "${MY_DIR}/../${DEVICE}/proprietary-files.txt" ]; then
    # Reinitialize the helper for device
    source "${MY_DIR}/../${DEVICE}/extract-files.sh"
    setup_vendor "${DEVICE}" "${VENDOR}" "${MK_ROOT}" false "${CLEAN_VENDOR}"

    extract "${MY_DIR}/../${DEVICE}/proprietary-files.txt" "${SRC}" \
            "${KANG}" --section "${SECTION}"
fi

"${MY_DIR}/setup-makefiles.sh"
