#!/usr/bin/env bash
# Polls the API health endpoint of a running container until it returns HTTP 200.
# The URL is derived from the container's published port, so no compose or .env knowledge is needed.
# The container is expected to publish a single port.
# Exits 0 on HTTP 200, 1 if any other status (or no response) is still returned after all attempts,
# and 2 on invalid usage.
#
# Usage: api-health-check.sh [options] <container-name>
#
# Options:
#   --attempts <n>        number of attempts (default 30)
#   --delay <seconds>     seconds between attempts (default 2)
#   --timeout <seconds>   seconds per request (default 5)
#   --path <path>         health endpoint path (default /health)

set -euo pipefail

usage() {
  sed -n 's/^# \{0,1\}//; 8,14p' "$0" >&2
  exit 2
}

attempts=30
delay=2
timeout=5
path=/health
container=""

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --attempts) attempts="${2:?--attempts needs a value}"; shift 2 ;;
    --delay) delay="${2:?--delay needs a value}"; shift 2 ;;
    --timeout) timeout="${2:?--timeout needs a value}"; shift 2 ;;
    --path) path="${2:?--path needs a value}"; shift 2 ;;
    -h | --help) usage ;;
    -*) echo "Unknown option: $1" >&2; usage ;;
    *)
      if [[ -n "$container" ]]; then
        echo "Only one container name can be given" >&2
        usage
      fi
      container="$1"
      shift
      ;;
  esac
done

if [[ -z "$container" ]]; then
  usage
fi

# Lines look like "8080/tcp -> 0.0.0.0:49153" (and again for [::]); the host port is after the last colon.
if ! mappings=$(docker port "$container" 2>&1); then
  echo "::error::Could not read published ports of container $container: $mappings"
  exit 1
fi

host_port=$(printf '%s\n' "$mappings" | sed -n 's/.*:\([0-9][0-9]*\)$/\1/p' | sort -u | head -n 1)
if [[ -z "$host_port" ]]; then
  echo "::error::Container $container doesn't publish any port to the host"
  exit 1
fi

url="http://localhost:${host_port}${path}"
echo "Checking $url (container $container)"

# The container is running before the app listens, so retry until it answers 200 or attempts run out
status=""
body=""
for attempt in $(seq 1 "$attempts"); do
  # The status code is appended on its own last line, then split off from the body
  response=$(curl --silent --max-time "$timeout" \
    --write-out '\n%{http_code}' \
    "$url" || true)
  status="${response##*$'\n'}"
  body="${response%$'\n'*}"
  if [[ "$status" = "200" ]]; then
    echo "API is healthy (HTTP $status)"
    echo "$body"
    exit 0
  fi
  echo "Attempt $attempt/$attempts: $url returned HTTP $status"
  sleep "$delay"
done

echo "::error::API health check failed: $url returned HTTP $status"
echo "$body"
exit 1
