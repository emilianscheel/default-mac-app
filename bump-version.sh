#!/usr/bin/env bash
set -euo pipefail

PROJECT_FILE="DefaultAppManager.xcodeproj/project.pbxproj"

usage() {
  echo "Usage: ./bump-version.sh --major|--minor|--patch" >&2
}

if [[ "$#" -ne 1 ]]; then
  usage
  exit 1
fi

case "$1" in
  --major|--minor|--patch)
    BUMP_TYPE="$1"
    ;;
  *)
    usage
    exit 1
    ;;
esac

cd "$(dirname "$0")"

if [[ ! -f "${PROJECT_FILE}" ]]; then
  echo "Project file not found: ${PROJECT_FILE}" >&2
  exit 1
fi

CURRENT_VERSION="$(sed -nE 's/^[[:space:]]*MARKETING_VERSION = ([0-9]+(\.[0-9]+){1,2});$/\1/p' "${PROJECT_FILE}" | sort -u)"

if [[ -z "${CURRENT_VERSION}" ]]; then
  echo "No MARKETING_VERSION value found in ${PROJECT_FILE}" >&2
  exit 1
fi

if [[ "$(printf '%s\n' "${CURRENT_VERSION}" | wc -l | tr -d ' ')" -ne 1 ]]; then
  echo "Expected one unique MARKETING_VERSION, found:" >&2
  printf '%s\n' "${CURRENT_VERSION}" >&2
  exit 1
fi

IFS='.' read -r MAJOR MINOR PATCH <<< "${CURRENT_VERSION}"
PATCH="${PATCH:-0}"

case "${BUMP_TYPE}" in
  --major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  --minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  --patch)
    PATCH=$((PATCH + 1))
    ;;
esac

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"

sed -i '' -E "s/(MARKETING_VERSION = )[0-9]+(\\.[0-9]+){1,2};/\\1${NEW_VERSION};/g" "${PROJECT_FILE}"

echo "Bumped version: ${CURRENT_VERSION} -> ${NEW_VERSION}"
