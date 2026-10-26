#!/usr/bin/env bash
set -Eeuo pipefail
BASE_URL="${BASE_URL:-http://127.0.0.1}"
curl --fail --silent --show-error --max-time 15 "${BASE_URL}/actuator/health" >/dev/null
curl --fail --silent --show-error --max-time 15 "${BASE_URL}/" >/dev/null
echo "Mentify health checks passed."
