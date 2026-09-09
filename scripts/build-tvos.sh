#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
PROJECT="$ROOT_DIR/tvosApp/NuvioTV.xcodeproj"
SCHEME="NuvioTV"
CONFIGURATION="${CONFIGURATION:-Debug}"
DESTINATION="${DESTINATION:-generic/platform=tvOS Simulator}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$ROOT_DIR/build/tvos-derived/compile}"
BUILD_ARCHS="${BUILD_ARCHS:-$(uname -m)}"
ONLY_ACTIVE_ARCH="${ONLY_ACTIVE_ARCH:-YES}"

usage() {
  cat <<'EOF'
Usage: ./scripts/build-tvos.sh [--release] [--device <destination>]

Compile the tvOS app without running tests. The default destination is the
generic tvOS Simulator and the default configuration is Debug.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --release) CONFIGURATION=Release; shift ;;
    --device)
      [[ $# -ge 2 ]] || { usage >&2; exit 1; }
      DESTINATION="$2"
      shift 2
      ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
done

xcodebuild build \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  ARCHS="$BUILD_ARCHS" \
  ONLY_ACTIVE_ARCH="$ONLY_ACTIVE_ARCH" \
  CODE_SIGNING_ALLOWED=NO
