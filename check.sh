#!/usr/bin/env bash
# check.sh — the check Checkly can't run, in ~40 lines of bash.
#
# Runs the two monitors side by side against a bot-walled page:
#   1. a naive HTTP GET (what uptime checkers do)  -> expect the wall
#   2. a navette session (system WebKit daemon)    -> expect the real page
#
# Usage:
#   ./check.sh [URL]          (default: vinted.fr catalog search)
#   NAVETTE=http://127.0.0.1:8766 ./check.sh
#
# Evidence on the landing page was produced with this script on 2026-10-27.
# A navette daemon must be running (`navette serve --port 8766`).

set -euo pipefail

URL="${1:-https://www.vinted.fr/catalog?search_text=nike}"
NAVETTE="${NAVETTE:-http://127.0.0.1:8766}"
SESSION="check-sh-$$"

echo "== 1/2 naive HTTP monitor =="
code=$(curl -s -o /dev/null -w "%{http_code}" -m 20 "$URL")
echo "GET $URL"
echo "-> HTTP $code"
if [ "$code" = "403" ] || [ "$code" = "503" ]; then
  echo "-> cf-mitigated/machine check likely: the monitor sees a wall, not the site"
else
  echo "-> this target answered the plain GET; pick a more walled one for the demo"
fi

echo
echo "== 2/2 navette check =="
echo "navigate (a fresh session may sit on a challenge for a few seconds)..."
curl -s -m 60 -X POST "$NAVETTE/navigate" -H 'Content-Type: application/json' \
  -d "{\"session\":\"$SESSION\",\"url\":\"$URL\"}" \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); print("->", d.get("ok"), d.get("title"))'

# give a managed challenge time to clear in the real engine, then read the page
sleep 6
read_json=$(curl -s -m 30 -X POST "$NAVETTE/read" -H 'Content-Type: application/json' \
  -d "{\"session\":\"$SESSION\",\"format\":\"text\"}")

echo "$read_json" | python3 -c '
import json,sys
d=json.load(sys.stdin)
c=d.get("content") or ""
print("-> page bytes:", len(c))
print("-> sample:", " ".join(c.split()[:12]))
'

# assert: the page must contain real content, not a challenge shell
echo "$read_json" | python3 -c '
import json,sys
c=(json.load(sys.stdin).get("content") or "").lower()
wall = ("enable javascript" in c) or ("un instant" in c) or len(c) < 2000
print("-> VERDICT:", "WALL — challenge still up" if wall else "PASS — real page rendered")
'

curl -s -m 10 -X POST "$NAVETTE/sessions/close" -H 'Content-Type: application/json' \
  -d "{\"session\":\"$SESSION\"}" >/dev/null || true
