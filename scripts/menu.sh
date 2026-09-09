#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

declare -a LABELS=(
  "Run tvOS app in a simulator"
  "Build tvOS app"
  "Build unsigned IPA"
  "Check project layout"
  "Deploy Trakt function"
  "Thin Aether simulator frameworks"
  "Generate Xcode project"
)
declare -a COMMANDS=(
  "$SCRIPT_DIR/run-tvos.sh"
  "$SCRIPT_DIR/build-tvos.sh"
  "$SCRIPT_DIR/build-ipa.sh"
  "$SCRIPT_DIR/check-layout.sh"
  "$SCRIPT_DIR/deploy_trakt_function.sh"
  "$SCRIPT_DIR/thin-aether-simulator-frameworks.sh"
  "$SCRIPT_DIR/generate-xcode-project.sh"
)

usage() {
  cat <<EOF
Usage: ./scripts/menu.sh

Select a repository command to run. Any arguments entered after the selection
are passed to that command.
EOF
}

[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && { usage; exit 0; }

while :; do
  echo
  echo "NuvioTVOS commands"
  select label in "${LABELS[@]}" "Exit"; do
    [[ -n "${label:-}" ]] || { echo "Choose a number from 1 to $((${#LABELS[@]} + 1))." >&2; continue; }
    (( REPLY == ${#LABELS[@]} + 1 )) && exit 0
    command="${COMMANDS[$((REPLY - 1))]}"
    shift_args=()
    if [[ -n "${*:-}" ]]; then shift_args=("$@"); fi
    if ((${#shift_args[@]})); then
      "$command" "${shift_args[@]}"
    else
      "$command"
    fi
    break
  done
done
