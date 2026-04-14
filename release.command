#!/bin/bash
# KID COMM 3000 — Release script
# Prompts for a commit message, auto-bumps the Service Worker cache
# version (so installed PWAs pick up the new shell on next launch),
# then commits and pushes. Idempotent: safe to run when there are no
# changes — git will just report "nothing to commit".
# Double-click in Finder to run.

set -eu

cd "$(dirname "$0")"

echo "================================================="
echo "  KID COMM 3000 — Release"
echo "================================================="
echo ""

# ---------------------------------------------------------------
# 0) Clean up stale sandbox lock files, and migrate away from the
#    old V3-named release script if it's still lying around.
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
# 1) Show pending changes BEFORE anything else so the user knows
#    what will be committed.
# ---------------------------------------------------------------
CHANGES=$(git status --porcelain)
if [ -z "$CHANGES" ]; then
    echo "Keine lokalen Änderungen zum Committen."
    echo "Prüfe, ob der Push noch aussteht..."
    if git diff --quiet @{u}..HEAD 2>/dev/null; then
        echo "Alles bereits gepusht. Nichts zu tun."
        echo ""
        read -p "Enter drücken zum Beenden..." _
        exit 0
    fi
    echo "Lokale Commits noch nicht gepusht — pushe jetzt."
    git push
    echo ""
    read -p "Enter drücken zum Beenden..." _
    exit 0
fi

echo "Änderungen, die committet werden:"
git status --short
echo ""

# ---------------------------------------------------------------
# 2) Auto-bump Service Worker cache so installed PWAs update.
#    Skipped if sw.js hasn't actually changed.
# ---------------------------------------------------------------
if echo "$CHANGES" | grep -qE '^[ AM]M? sw\.js$|^[ AM]M? index\.html$'; then
    CURRENT=$(grep -oE "kidcomm-v[0-9]+" sw.js | grep -oE '[0-9]+$' | head -1)
    if [ -n "$CURRENT" ]; then
        NEXT=$((CURRENT + 1))
        sed -i '' "s/kidcomm-v${CURRENT}/kidcomm-v${NEXT}/" sw.js
        echo "• Service Worker Cache: kidcomm-v${CURRENT} → kidcomm-v${NEXT}"
    fi
fi

# ---------------------------------------------------------------
# 3) Ask for a meaningful commit message.
# ---------------------------------------------------------------
echo ""
echo "Commit-Nachricht eingeben (was hat sich geändert?)"
echo "Leer lassen für Editor, Ctrl-C zum Abbrechen:"
echo ""
read -r MSG

# ---------------------------------------------------------------
# 4) Stage + commit + push.
# ---------------------------------------------------------------
git add -A

if [ -z "$MSG" ]; then
    # Fall back to interactive editor if the user wants a longer message
    git commit
else
    git commit -m "$MSG"
fi

echo ""
echo "Pushe zu GitHub..."
git push

echo ""
echo "================================================="
echo "  Fertig. Änderungen sind live."
echo "================================================="
echo ""
read -p "Enter drücken zum Beenden..." _
