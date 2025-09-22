#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/job-date.log"

# Arguments:
#   1) script file path or '-' for built-in job
#   2) Healthchecks ping URL
#   3) simulate fail flag (0|1), optional
SCRIPT_ARG="${1:-}"
PING_URL="${2:-}"
SIMULATE_FLAG="${3:-0}"

if [[ -z "$SCRIPT_ARG" || -z "$PING_URL" ]]; then
  echo "Usage: $0 <script_path|-> <hc_ping_url> [simulate_fail(0|1)]" >&2
  exit 2
fi

START_URL="$PING_URL/start"
FAIL_URL="$PING_URL/fail"

# Start ping
curl -fsS --retry 3 "$START_URL" >/dev/null

# On any error after this point, send fail signal
trap 'curl -fsS --retry 3 "$FAIL_URL" >/dev/null || true' ERR

if [[ "$SCRIPT_ARG" == "-" ]]; then
  date '+%Y-%m-%d %H:%M:%S %z' >> "$LOG_FILE"
  sleep 3
else
  if [[ -f "$SCRIPT_ARG" ]]; then
    export LOG_FILE
    export SIMULATE_FAIL="$SIMULATE_FLAG"
    if [[ -x "$SCRIPT_ARG" ]]; then
      "$SCRIPT_ARG"
    else
      bash "$SCRIPT_ARG"
    fi
  else
    echo "Error: script file not found: $SCRIPT_ARG" >&2
    exit 3
  fi
fi

# If simulate flag is set, force failure now (triggers trap and non-zero exit)
if [[ "$SIMULATE_FLAG" == "1" ]]; then
  echo "Simulating failure via third argument" >&2
  false
fi

# Success ping
curl -fsS --retry 3 "$PING_URL" >/dev/null

exit 0


