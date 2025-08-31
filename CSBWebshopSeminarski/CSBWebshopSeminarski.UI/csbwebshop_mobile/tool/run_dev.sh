#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${SCRIPT_DIR}/.."
cd "$APP_DIR"
/workspace/flutter/flutter/bin/flutter run --dart-define=APP_ENV=dev "$@"

