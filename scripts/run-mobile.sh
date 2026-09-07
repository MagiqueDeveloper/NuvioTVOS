#!/usr/bin/env bash
# Compatibility wrapper for older docs. Prefer ./scripts/run-tvos.sh.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
case "${1:-}" in
  tvos)
    shift
    exec "$ROOT/run-tvos.sh" "${1:-s}"
    ;;
  -h|--help|help|"")
    exec "$ROOT/run-tvos.sh" --help
    ;;
  *)
    echo "This repository is tvOS-only. Use: ./scripts/run-tvos.sh" >&2
    echo "Legacy form still accepted: ./scripts/run-mobile.sh tvos s" >&2
    exit 1
    ;;
esac
