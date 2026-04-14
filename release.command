#!/bin/bash
# KID COMM 3000 — Release script
# Vollautomatisch: Doppelklick, fertig.
# 1) Räumt stale sandbox locks und das alte commit_v3.command auf
# 2) Bumpt den SW-Cache automatisch, wenn sw.js oder index.html geändert
# 3) Erzeugt eine Commit-Message aus Zeitstempel + geänderten Dateien
# 4) git add -A, commit, push
# Idempotent: bei "nichts zu tun" läuft das Skript sauber durch.

set -eu

cd "$(dirname "$0")"

echo "================================================="
echo "  KID COMM 3000 — Release"
echo "================================================="
echo ""

# ---------------------------------------------------------------
# 0) Sandbox-Altlasten entfernen.
# ---------------------------------------------------------------
if [ -f .git/index.lock ]; then
    echo "• Entferne veraltete .git/index.lock"
    rm -f .git/index.lock
fi
if [ -f commit_v3.command ]; then
    rm -f commit_v3.command
    echo "• Entferne altes commit_v3.command (umbenannt zu release.command)"
fi

# ---------------------------------------------------------------
# 1) Bestandsaufnahme.
# ---------------------------------------------------------------
CHANGES=$(git status --porcelain)

if [ -z "$CHANGES" ]; then
    echo "Keine lokalen Änderungen zum Committen."
    # Lokale Commits, die noch nicht gepusht sind?
    if ! git diff --quiet @{u}..HEAD 2>/dev/null; then
        echo "Ungepushte Commits vorhanden — pushe jetzt."
        git push
    else
        echo "Alles bereits gepusht. Nichts zu tun."
    fi
    echo ""
    read -p "Enter zum Beenden..." _
    exit 0
fi

echo "Änderungen, die committet werden:"
git status --short
echo ""

# ---------------------------------------------------------------
# 2) SW-Cache-Bump, falls sw.js oder index.html geändert.
#    Installierte PWAs erkennen so das Update.
# ---------------------------------------------------------------
if echo "$CHANGES" | grep -qE '(^| )(sw\.js|index\.html)$'; then
    CURRENT=$(grep -oE "kidcomm-v[0-9]+" sw.js | grep -oE '[0-9]+$' | head -1)
    if [ -n "$CURRENT" ]; then
        NEXT=$((CURRENT + 1))
        sed -i '' "s/kidcomm-v${CURRENT}/kidcomm-v${NEXT}/" sw.js
        echo "• Service Worker Cache: kidcomm-v${CURRENT} → kidcomm-v${NEXT}"
    fi
fi

# ---------------------------------------------------------------
# 3) Stagen. Danach die gestageten Dateien für die Message abfragen.
# ---------------------------------------------------------------
git add -A

STAMP=$(date +'%Y-%m-%d %H:%M')
# Liste der geänderten Dateien (max 5, Rest als "+N more"), in einer Zeile
STAGED=$(git diff --cached --name-only)
COUNT=$(echo "$STAGED" | wc -l | tr -d ' ')
FILES=$(echo "$STAGED" | head -5 | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')
if [ "$COUNT" -gt 5 ]; then
    FILES="$FILES, +$((COUNT - 5)) more"
fi

MSG="Update $STAMP — $FILES"

echo ""
echo "Commit-Message: $MSG"
echo ""
git commit -m "$MSG"

# ---------------------------------------------------------------
# 4) Push.
# ---------------------------------------------------------------
echo "Pushe zu GitHub..."
git push

echo ""
echo "================================================="
echo "  Fertig. Änderungen sind live."
echo "================================================="
echo ""
read -p "Enter zum Beenden..." _
