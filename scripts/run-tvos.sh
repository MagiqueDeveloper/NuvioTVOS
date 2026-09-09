#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TVOS_PROJECT="$ROOT_DIR/tvosApp/NuvioTV.xcodeproj"
TVOS_SCHEME="NuvioTV"
DERIVED_DATA_BASE="$ROOT_DIR/build/tvos-derived"
APP_NAME="NuvioTV.app"
BUNDLE_ID="com.pyksel.nuviotvos"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/run-tvos.sh
  ./scripts/run-tvos.sh --device <simulator-id>

Builds the tvOS app from the Xcode project, installs it on a booted Apple TV
simulator, and launches it. The local Swift package resolves automatically;
CocoaPods is not required.
EOF
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

first_booted_tvos_simulator() {
  xcrun simctl list devices booted \
    | awk '/^-- tvOS/{is_tvos=1; next} /^-- /{is_tvos=0} is_tvos && /Booted/ { print; exit }' \
    | sed -E 's/.*\(([A-F0-9-]+)\) \(Booted\).*/\1/'
}

run_tvos_simulator() {
  local simulator_id="${1:-$(first_booted_tvos_simulator)}"
  if [[ -z "$simulator_id" ]]; then
    echo "No booted Apple TV simulator found." >&2
    echo "Boot one in Simulator, then rerun this command." >&2
    exit 1
  fi

  local derived_data_path="$DERIVED_DATA_BASE/simulator"
  local simulator_app_path="$derived_data_path/Build/Products/Debug-appletvsimulator/$APP_NAME"

  echo "Building tvOS debug app for simulator $simulator_id..."
  xcodebuild \
    -project "$TVOS_PROJECT" \
    -scheme "$TVOS_SCHEME" \
    -configuration Debug \
    -destination "id=$simulator_id" \
    -derivedDataPath "$derived_data_path" \
    CODE_SIGNING_ALLOWED=NO \
    build

  [[ -d "$simulator_app_path" ]] || {
    echo "Expected tvOS simulator app not found at: $simulator_app_path" >&2
    exit 1
  }

  echo "Installing on Apple TV simulator $simulator_id..."
  xcrun simctl install "$simulator_id" "$simulator_app_path"
  xcrun simctl terminate "$simulator_id" "$BUNDLE_ID" >/dev/null 2>&1 || true
  echo "Launching tvOS app..."
  xcrun simctl launch "$simulator_id" "$BUNDLE_ID"
}

main() {
  require_command xcodebuild
  require_command xcrun

  case "${1:-}" in
    "") run_tvos_simulator ;;
    --device)
      [[ $# -eq 2 ]] || { usage >&2; exit 1; }
      run_tvos_simulator "$2"
      ;;
    -h|--help|help) usage ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
}

main "$@"
