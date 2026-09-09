#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
require_command xcodegen

SPEC="$ROOT_DIR/tvosApp/project.yml"
[[ -f "$SPEC" ]] || { echo "Missing XcodeGen spec: $SPEC" >&2; exit 1; }

echo "Generating tvOS Xcode project from $SPEC..."
xcodegen generate --spec "$SPEC" --project "$ROOT_DIR/tvosApp"
echo "Generated $ROOT_DIR/tvosApp/NuvioTV.xcodeproj/project.pbxproj"
