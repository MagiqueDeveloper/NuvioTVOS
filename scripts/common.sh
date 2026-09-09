#!/usr/bin/env bash

# Shared helpers for repository scripts. Source this file; do not execute it.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

require_command() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing required command: $1" >&2; exit 1; }
}

select_tvos_simulator() {
  local -a rows ids names
  while IFS=$'\t' read -r id name state; do
    [[ -n "$id" ]] || continue
    rows+=("$name [$state]"); ids+=("$id"); names+=("$name")
  done < <(xcrun simctl list devices available | awk '/^-- tvOS/{on=1; next} /^-- /{on=0} on && /Apple TV/ { line=$0; match(line, /[A-F0-9-]{36}/); id=substr(line, RSTART, RLENGTH); name=line; sub(/ \([A-F0-9-]+\).*/,"",name); state=(line ~ /Booted/ ? "Booted" : "Shutdown"); print id "\t" name "\t" state }')
  ((${#ids[@]})) || { echo "No available tvOS simulators found." >&2; exit 1; }
  echo "Select a tvOS simulator:" >&2
  select choice in "${rows[@]}"; do
    if [[ -n "${choice:-}" ]]; then printf '%s\n' "${ids[$((REPLY-1))]}"; return; fi
    echo "Choose a number from 1 to ${#ids[@]}." >&2
  done
}
