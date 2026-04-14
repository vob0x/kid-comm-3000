#!/bin/bash
# KID COMM 3000 — Release script
# Makes V3 the canonical version: renames V3 files to index.html/sw.js,
# removes legacy V1/V2 files from the repo, commits and pushes.
# Idempotent: safe to run again if V3 has already been released.
# Double-click to execute.

set -eu

cd "$(dirname "$0")"

echo "=== KID COMM 3000 — Release ==="
echo ""

# Stale git lock from a crashed process (e.g. sandbox)
if [ -f .git/index.lock ]; then
    echo "Removing stale .git/index.lock..."
    rm -f .git/index.lock
fi

# 1) Promote V3 → canonical filenames (overwriting V1)
if [ -f index_v3.html ]; then
    echo "Promoting index_v3.html → index.html"
    mv -f index_v3.html index.html
fi
if [ -f sw_v3.js ]; then
    echo "Promoting sw_v3.js → sw.js"
    mv -f sw_v3.js sw.js
fi

# 2) Remove legacy V2 files if still present
for f in index_v2.html sw_v2.js; do
    if [ -f "$f" ]; then
        echo "Removing legacy file: $f"
        rm -f "$f"
    fi
done

echo ""
echo "Status after promotion:"
git status --short
echo ""

# 3) Stage everything (rename + deletions + new content)
git add -A

echo "Commit..."
git commit -m "Release: promote V3 to canonical index.html / sw.js

- index_v3.html -> index.html (same content, V3 is now the main app)
- sw_v3.js      -> sw.js      (cache bumped to kidcomm-v100)
- Removed V1 original index.html / sw.js (replaced by V3 content)
- Removed V2 files (index_v2.html, sw_v2.js) from repo
- Single canonical entry point; PWA update path is clean

Active release content includes:
- Complete V3 JS rewrite (clean architecture, no patchwork)
- Background-resume reconnect fix (10 unavailable-id retries, 90s window,
  unified resumeFromBackground flow)
- OpenRelay TURN fallback in BASE_ICE for reliable WLAN<->cellular
- createPeer() helper with iceCandidatePoolSize=4
- refreshTurnIfNeeded returns bool -> forces peer reinit on TURN change
- reportIceDiagnostics helper (logs nominated candidate pair, warns
  when no relay candidates gathered)
- New mode 'BAHNHOF' (SBB Es-B-B / C-F-F / F-F-Es vibraphone chime,
  station theme with animated rails and platform)
- 21 ghost state declarations removed from S; 17 TIMING fields all used
- No V3 FIX / V2: comments anywhere in the source" || {
    echo "Nothing to commit (already up to date)."
}

echo ""
echo "Push..."
git push

echo ""
echo "=== FERTIG ==="
echo ""
echo "Die App lädt jetzt automatisch V3 unter der normalen URL."
echo "Bei installierten PWAs aktualisiert der Service Worker beim nächsten Öffnen."
echo ""
read -p "Enter drücken zum Beenden..."
