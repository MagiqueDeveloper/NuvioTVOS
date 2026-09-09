#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
PACKAGE="$ROOT_DIR/Packages/NuvioTVKit"
PROJECT="$ROOT_DIR/tvosApp/NuvioTV.xcodeproj"

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

[[ -f "$PACKAGE/Package.swift" ]] || fail "missing Packages/NuvioTVKit/Package.swift"
[[ -f "$PROJECT/project.pbxproj" ]] || fail "missing Xcode project"
[[ -f "$ROOT_DIR/tvosApp/NuvioTV/Sources/NuvioTVApp.swift" ]] || fail "missing app composition root"
[[ -f "$ROOT_DIR/tvosApp/TopShelf/TopShelfContentProvider.swift" ]] || fail "missing Top Shelf source"
[[ -f "$ROOT_DIR/tvosApp/NuvioTVTests/NuvioTVTests.swift" ]] || fail "missing unit test source"

for target in NuvioDomain NuvioData NuvioPlayback NuvioUI NuvioFeatures; do
  [[ -d "$PACKAGE/Sources/$target" ]] || fail "missing package target $target"
done
pass "package module graph exists"

if find "$ROOT_DIR/tvosApp" -type f -name '*.swift' \
    ! -path "$ROOT_DIR/tvosApp/NuvioTV/Sources/*" \
    ! -path "$ROOT_DIR/tvosApp/TopShelf/TopShelfContentProvider.swift" \
    ! -path "$ROOT_DIR/tvosApp/NuvioTVTests/*" \
    ! -path "$ROOT_DIR/tvosApp/Pods/*" | grep -q .; then
  fail "unowned tvOS Swift source remains outside the active source roots"
fi
pass "tvOS source files have an owned location"

if rg -n 'import (AetherEngine|MPVKit)|URLSession|UserDefaults|NSPersistent|CoreData' \
    "$PACKAGE/Sources/NuvioFeatures" "$PACKAGE/Sources/NuvioUI" \
    "$ROOT_DIR/tvosApp/NuvioTV/Sources" >/dev/null; then
  fail "feature/UI/composition-root code leaks playback, networking, or persistence implementations"
fi
pass "feature/UI/composition-root code depends only on shared interfaces"

if rg -n 'NuvioTV/Sources/(Core|Data|DomainModels|Models|UI|ViewModels)|../src/NuvioTVKit|tvosApp/NuvioTV.xcworkspace' \
    "$PROJECT/project.pbxproj" >/dev/null; then
  fail "stale monolithic source or workspace references remain in the Xcode project"
fi
pass "Xcode project references the package and active app sources"

xcodebuild -list -project "$PROJECT" >/dev/null
pass "Xcode project and Swift package graph resolve"

echo "Static layout verification complete. Tests are intentionally not run by this script."
