#!/usr/bin/env bash
set -euo pipefail

PROJECT="DefaultAppManager.xcodeproj"
SCHEME="DefaultAppManager"
CONFIGURATION="Debug"
DERIVED_DATA_PATH=".build/DerivedData"
PRODUCT_NAME="Default Mac App"
APP_BUNDLE="${DERIVED_DATA_PATH}/Build/Products/${CONFIGURATION}/${PRODUCT_NAME}.app"
TARGET_BUILD_DIR="${DERIVED_DATA_PATH}/Build/Intermediates.noindex/${SCHEME}.build/${CONFIGURATION}/${SCHEME}.build"
BUNDLE_ID="com.local.DefaultAppManager"

cd "$(dirname "$0")"

echo "Clearing stale app bundle and asset catalog outputs..."
rm -rf "${APP_BUNDLE}"
rm -rf "${TARGET_BUILD_DIR}/assetcatalog_output"
rm -f "${TARGET_BUILD_DIR}"/assetcatalog_*

echo "Building ${PRODUCT_NAME} (${CONFIGURATION})..."
xcodebuild \
  -project "${PROJECT}" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -derivedDataPath "${DERIVED_DATA_PATH}" \
  build

if [[ ! -d "${APP_BUNDLE}" ]]; then
  echo "Build succeeded, but app bundle was not found at: ${APP_BUNDLE}" >&2
  exit 1
fi

echo "Stopping any running ${PRODUCT_NAME} instance..."
osascript -e "tell application id \"${BUNDLE_ID}\" to quit" >/dev/null 2>&1 || true

for _ in {1..20}; do
  if ! pgrep -x "${PRODUCT_NAME}" >/dev/null 2>&1; then
    break
  fi
  sleep 0.25
done

if pgrep -x "${PRODUCT_NAME}" >/dev/null 2>&1; then
  pkill -x "${PRODUCT_NAME}" || true
fi

echo "Launching ${APP_BUNDLE}..."
open "${APP_BUNDLE}"
