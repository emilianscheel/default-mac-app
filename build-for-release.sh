#!/usr/bin/env bash
set -euo pipefail

PROJECT="DefaultAppManager.xcodeproj"
SCHEME="DefaultAppManager"
CONFIGURATION="Release"
PRODUCT_NAME="Default Mac App"
DERIVED_DATA_PATH=".build/ReleaseDerivedData"
RELEASE_DIR=".build/release"
STAGING_DIR="${RELEASE_DIR}/staging"
APP_BUNDLE="${DERIVED_DATA_PATH}/Build/Products/${CONFIGURATION}/${PRODUCT_NAME}.app"
STAGED_APP="${STAGING_DIR}/${PRODUCT_NAME}.app"

cd "$(dirname "$0")"

echo "Preparing release output..."
rm -rf "${RELEASE_DIR}"
mkdir -p "${STAGING_DIR}"

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

echo "Staging app bundle..."
ditto "${APP_BUNDLE}" "${STAGED_APP}"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${STAGED_APP}/Contents/Info.plist" 2>/dev/null || true)"
if [[ -z "${VERSION}" ]]; then
  VERSION="1.0"
fi

DMG_NAME="${PRODUCT_NAME// /-}-${VERSION}.dmg"
DMG_PATH="${RELEASE_DIR}/${DMG_NAME}"

echo "Creating ${DMG_PATH}..."
hdiutil create \
  -volname "${PRODUCT_NAME}" \
  -srcfolder "${STAGING_DIR}" \
  -ov \
  -format UDZO \
  "${DMG_PATH}"

echo "Release DMG created: ${DMG_PATH}"

