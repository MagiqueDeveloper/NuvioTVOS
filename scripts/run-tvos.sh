#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TVOS_APP_DIR="$ROOT_DIR/tvosApp"
TVOS_WORKSPACE="$TVOS_APP_DIR/NuvioTV.xcworkspace"
TVOS_SCHEME="NuvioTV"
TVOS_DERIVED_DATA_BASE="$ROOT_DIR/build/tvos-derived"
TVOS_APP_NAME="NuvioTV.app"
TVOS_BUNDLE_ID="com.nuvio.app.tv"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/run-tvos.sh
  ./scripts/run-tvos.sh s

Builds the native SwiftUI tvOS app from tvosApp/, installs it on a booted
Apple TV simulator, and launches it.
EOF
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

first_booted_tvos_simulator() {
  xcrun simctl list devices booted \
    | awk '/^-- tvOS/{is_tvos=1; next} /^-- /{is_tvos=0} is_tvos && /Booted/ { print; exit }' \
    | sed -E 's/.*\(([A-F0-9-]+)\) \(Booted\).*/\1/'
}

ensure_tvos_pods() {
  if [[ ! -f "$TVOS_APP_DIR/Pods/Manifest.lock" ]]; then
    require_command pod

    echo "Generating tvOS CocoaPods project..."
    (cd "$TVOS_APP_DIR" && pod install)
  fi
}

run_tvos_simulator() {
  require_command xcodebuild
  require_command xcrun
  ensure_tvos_pods

  local simulator_id
  simulator_id="$(first_booted_tvos_simulator)"

  if [[ -z "$simulator_id" ]]; then
    echo "No booted Apple TV simulator found." >&2
    echo "Boot an Apple TV simulator first, then rerun: ./scripts/run-tvos.sh s" >&2
    exit 1
  fi

  local derived_data_path
  derived_data_path="$TVOS_DERIVED_DATA_BASE/simulator"

  local simulator_app_path
  simulator_app_path="$derived_data_path/Build/Products/Debug-appletvsimulator/$TVOS_APP_NAME"

  echo "Building tvOS debug app for simulator $simulator_id..."
  xcodebuild \
    -workspace "$TVOS_WORKSPACE" \
    -scheme "$TVOS_SCHEME" \
    -configuration Debug \
    -destination "id=$simulator_id" \
    -derivedDataPath "$derived_data_path" \
    build

  if [[ ! -d "$simulator_app_path" ]]; then
    echo "Expected tvOS simulator app not found at: $simulator_app_path" >&2
    exit 1
  fi

  echo "Installing on Apple TV simulator $simulator_id..."
  xcrun simctl install "$simulator_id" "$simulator_app_path"

  echo "Launching tvOS app..."
  xcrun simctl terminate "$simulator_id" "$TVOS_BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl launch "$simulator_id" "$TVOS_BUNDLE_ID"
}

main() {
  case "${1:-s}" in
    s|"")
      run_tvos_simulator
      ;;
    -h|--help|help)
      usage
      ;;
    *)
      echo "Unknown argument: ${1:-}" >&2
      usage
      exit 1
      ;;
  esac
}

main "$@"
