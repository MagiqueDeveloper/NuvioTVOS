#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
TVOS_WORKSPACE="$ROOT_DIR/tvosApp/NuvioTV.xcworkspace"
TVOS_PROJECT="$ROOT_DIR/tvosApp/NuvioTV.xcodeproj"
TVOS_SCHEME="NuvioTV"
DERIVED_DATA_BASE="$ROOT_DIR/build/tvos-derived"
APP_NAME="NuvioTV.app"
BUNDLE_ID="com.pyksel.nuviotvos"
BUILD_ARCHS="${BUILD_ARCHS:-$(uname -m)}"
ONLY_ACTIVE_ARCH="${ONLY_ACTIVE_ARCH:-YES}"

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

run_tvos_simulator() {
  local simulator_id="${1:-$(select_tvos_simulator)}"
  if [[ -z "$simulator_id" ]]; then
    echo "No booted Apple TV simulator found." >&2
    echo "Boot one in Simulator, then rerun this command." >&2
    exit 1
  fi

  local derived_data_path="$DERIVED_DATA_BASE/simulator"
  local simulator_app_path="$derived_data_path/Build/Products/Debug-appletvsimulator/$APP_NAME"

  echo "Building tvOS debug app for simulator $simulator_id..."
  # Use workspace if it exists, otherwise fall back to project
  local build_type="-project"
  local build_path="$TVOS_PROJECT"
  if [[ -d "$TVOS_WORKSPACE" ]]; then
    build_type="-workspace"
    build_path="$TVOS_WORKSPACE"
  fi
  
  xcodebuild \
    $build_type "$build_path" \
    -scheme "$TVOS_SCHEME" \
    -configuration Debug \
    -destination "id=$simulator_id" \
    -derivedDataPath "$derived_data_path" \
    ARCHS="$BUILD_ARCHS" \
    ONLY_ACTIVE_ARCH="$ONLY_ACTIVE_ARCH" \
    MARKETING_VERSION=1.0 \
    CURRENT_PROJECT_VERSION=1 \
    CODE_SIGNING_ALLOWED=NO \
    build

  [[ -d "$simulator_app_path" ]] || {
    echo "Expected tvOS simulator app not found at: $simulator_app_path" >&2
    exit 1
  }

  # XcodeGen does not embed the prebuilt simulator FFmpeg frameworks by
  # default. Copy them into the app so dyld can resolve @rpath at launch.
  local frameworks_dir="$simulator_app_path/Frameworks"
  mkdir -p "$frameworks_dir"
  for framework in "$derived_data_path/Build/Products/Debug-appletvsimulator"/AetherLib*.framework; do
    [[ -d "$framework" ]] || continue
    local name="$(basename "$framework" .framework)"
    rm -rf "$frameworks_dir/$name.framework"
    ditto "$framework" "$frameworks_dir/$name.framework"
    if lipo -info "$frameworks_dir/$name.framework/$name" 2>/dev/null | grep -q 'Architectures in the fat file'; then
      lipo -thin "$BUILD_ARCHS" "$frameworks_dir/$name.framework/$name" -output "$frameworks_dir/$name.framework/$name.thin"
      mv "$frameworks_dir/$name.framework/$name.thin" "$frameworks_dir/$name.framework/$name"
    fi
    codesign --force --sign - --timestamp=none "$frameworks_dir/$name.framework" >/dev/null
  done

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
