#!/usr/bin/env bash
# CALCIOS public endpoint healthcheck — no credentials.
set -euo pipefail

RPC_URL="${RPC_URL:-https://rpc.mainnet.chain.robinhood.com}"
STOCKKIT_URL="${STOCKKIT_URL:-https://api.stockkit.dev/v1/assets}"
MORPHO_URL="${MORPHO_URL:-https://blue-api.morpho.org/graphql}"
SITE_URL="${SITE_URL:-https://calcios.xyz}"

WATCH=0
STRICT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --watch) WATCH="${2:-30}"; shift 2 ;;
    --strict) STRICT=1; shift ;;
    -h|--help)
      echo "Usage: $0 [--watch SECONDS] [--strict]"
      exit 0
      ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

check_http() {
  local name="$1" url="$2" method="${3:-GET}" body="${4:-}"
  local start end ms code
  start=$(date +%s%N 2>/dev/null || date +%s)
  if [[ "$method" == "POST" ]]; then
    code=$(curl -sS -o /tmp/calcios_hc_body -w "%{http_code}" \
      -X POST -H "content-type: application/json" -d "$body" \
      --connect-timeout 10 --max-time 20 "$url" || echo "000")
  else
    code=$(curl -sS -o /tmp/calcios_hc_body -w "%{http_code}" \
      --connect-timeout 10 --max-time 20 "$url" || echo "000")
  fi
  end=$(date +%s%N 2>/dev/null || date +%s)
  if [[ ${#start} -gt 10 ]]; then
    ms=$(( (end - start) / 1000000 ))
  else
    ms=$(( (end - start) * 1000 ))
  fi
  local status="OK"
  if [[ "$code" != "200" && "$code" != "301" && "$code" != "302" ]]; then
    status="FAIL"
  fi
  printf "%-12s  %-4s  %5sms  %s\n" "$name" "$code" "$ms" "$status"
  if [[ "$status" == "FAIL" ]]; then
    return 1
  fi
  return 0
}

run_once() {
  local failed=0
  echo "=== CALCIOS Healthcheck $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="
  check_http "website" "$SITE_URL" || failed=1
  check_http "rpc" "$RPC_URL" "POST" '{"jsonrpc":"2.0","id":1,"method":"eth_chainId","params":[]}' || failed=1
  check_http "stockkit" "$STOCKKIT_URL" || failed=1
  check_http "morpho" "$MORPHO_URL" "POST" '{"query":"{ __typename }"}' || failed=1
  echo "----------------------------------------"
  if [[ $failed -ne 0 ]]; then
    echo "RESULT: DEGRADED"
    return 1
  fi
  echo "RESULT: ALL OK"
  return 0
}

if [[ "$WATCH" -gt 0 ]]; then
  while true; do
    run_once || true
    sleep "$WATCH"
  done
else
  if run_once; then
    exit 0
  else
    [[ "$STRICT" -eq 1 ]] && exit 1
    exit 0
  fi
fi
