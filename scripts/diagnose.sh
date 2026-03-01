#!/bin/bash
# ScreenMind — Diagnostic Script
# Verifies every stage of the pipeline is working.
# Usage: ./scripts/diagnose.sh

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
DIM='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m'

VAULT_PATH="$HOME/Desktop/pkmdev-notes"
SCREENMIND_DIR="$VAULT_PATH/ScreenMind"
TODAY=$(date +%Y-%m-%d)
DAILY_DIR="$SCREENMIND_DIR/$TODAY"

pass() { echo -e "  ${GREEN}PASS${NC}  $1"; }
fail() { echo -e "  ${RED}FAIL${NC}  $1"; }
warn() { echo -e "  ${YELLOW}WARN${NC}  $1"; }
info() { echo -e "  ${CYAN}INFO${NC}  $1"; }

echo ""
echo -e "${BOLD}============================================${NC}"
echo -e "${BOLD}  ScreenMind — Diagnostic Report${NC}"
echo -e "${BOLD}============================================${NC}"
echo -e "  ${DIM}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo ""

# ─────────────────────────────────────────
echo -e "${BOLD}[1/7] App Installation${NC}"
# ─────────────────────────────────────────
if [ -d "/Applications/ScreenMind.app" ]; then
    pass "ScreenMind.app in /Applications"
else
    fail "ScreenMind.app NOT found in /Applications"
fi

BINARY="/Applications/ScreenMind.app/Contents/MacOS/ScreenMind"
if [ -x "$BINARY" ]; then
    SIZE=$(ls -lh "$BINARY" | awk '{print $5}')
    pass "Binary exists ($SIZE)"
else
    fail "Binary missing or not executable"
fi

if codesign --verify --quiet /Applications/ScreenMind.app 2>/dev/null; then
    pass "Code signature valid"
else
    fail "Code signature INVALID — Screen Recording won't work"
fi
echo ""

# ─────────────────────────────────────────
echo -e "${BOLD}[2/7] Process Status${NC}"
# ─────────────────────────────────────────
PID=$(pgrep -f "ScreenMind.app/Contents/MacOS/ScreenMind" 2>/dev/null || echo "")
if [ -n "$PID" ]; then
    RSS=$(ps -o rss= -p $PID 2>/dev/null | tr -d ' ')
    RSS_MB=$((RSS / 1024))
    CPU=$(ps -o %cpu= -p $PID 2>/dev/null | tr -d ' ')
    pass "Running (PID $PID, ${RSS_MB}MB RAM, ${CPU}% CPU)"
else
    fail "NOT running — launch with: open /Applications/ScreenMind.app"
fi
echo ""

# ─────────────────────────────────────────
echo -e "${BOLD}[3/7] API Key (Keychain)${NC}"
# ─────────────────────────────────────────
KEY=$(security find-generic-password -s "com.screenmind" -a "com.screenmind.anthropic-api-key" -w 2>/dev/null || echo "")
if [ -n "$KEY" ]; then
    MASKED="${KEY:0:12}...${KEY: -4}"
    pass "API key found: $MASKED"

    # Quick API validation
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST "https://api.anthropic.com/v1/messages" \
        -H "content-type: application/json" \
        -H "x-api-key: $KEY" \
        -H "anthropic-version: 2023-06-01" \
        -d '{"model":"claude-sonnet-4-6-20250514","max_tokens":5,"messages":[{"role":"user","content":"hi"}]}' 2>/dev/null || echo "000")

    if [ "$HTTP_CODE" = "200" ]; then
        pass "Claude API responds (HTTP 200)"
    elif [ "$HTTP_CODE" = "401" ]; then
        fail "API key INVALID (HTTP 401 Unauthorized)"
    elif [ "$HTTP_CODE" = "000" ]; then
        warn "Could not reach API (network issue?)"
    else
        warn "API returned HTTP $HTTP_CODE"
    fi
else
    fail "No API key in Keychain"
    info "Store with: security add-generic-password -s com.screenmind -a com.screenmind.anthropic-api-key -w YOUR_KEY"
fi
echo ""

# ─────────────────────────────────────────
echo -e "${BOLD}[4/7] Screen Recording Permission${NC}"
# ─────────────────────────────────────────
if [ -n "$PID" ]; then
    # Check recent logs for TCC status
    TCC_ERROR=$(bash -c 'log show --predicate "process == \"ScreenMind\" AND subsystem BEGINSWITH \"com.screenmind\"" --last 2m --info --no-pager 2>&1 | grep -i "declined\|SCShareableContent failed" | tail -1' 2>/dev/null || echo "")
    CAPTURE_OK=$(bash -c 'log show --predicate "process == \"ScreenMind\" AND subsystem BEGINSWITH \"com.screenmind\"" --last 2m --info --no-pager 2>&1 | grep -i "Screen capture started\|Got .* displays" | tail -1' 2>/dev/null || echo "")

    if [ -n "$CAPTURE_OK" ]; then
        pass "Screen capture working"
        info "$CAPTURE_OK"
    elif [ -n "$TCC_ERROR" ]; then
        fail "Screen Recording DENIED by macOS"
        info "Fix: System Settings > Privacy & Security > Screen Recording"
        info "Remove ScreenMind, then re-add /Applications/ScreenMind.app"
    else
        warn "Cannot determine — check logs manually"
        info "Run: log stream --predicate 'subsystem BEGINSWITH \"com.screenmind\"' --info"
    fi
else
    warn "App not running — cannot check permission"
fi
echo ""

# ─────────────────────────────────────────
echo -e "${BOLD}[5/7] Pipeline Stages${NC}"
# ─────────────────────────────────────────
if [ -n "$PID" ]; then
    LOGS=$(bash -c 'log show --predicate "process == \"ScreenMind\" AND subsystem BEGINSWITH \"com.screenmind\"" --last 5m --info --debug --no-pager 2>&1' 2>/dev/null || echo "")

    echo "$LOGS" | grep -qi "Pipeline configured" && pass "Pipeline configured" || fail "Pipeline NOT configured"
    echo "$LOGS" | grep -qi "Pipeline starting" && pass "Pipeline started" || fail "Pipeline NOT started"
    echo "$LOGS" | grep -qi "Activity monitoring started" && pass "Activity monitor running" || warn "Activity monitor not detected"
    echo "$LOGS" | grep -qi "Screen capture started" && pass "Screen capture streaming" || fail "Screen capture NOT streaming"

    FRAME_COUNT=$(echo "$LOGS" | grep -ci "process.*frame\|handleFrame\|change.*detect\|significant" 2>/dev/null || echo "0")
    if [ "$FRAME_COUNT" -gt 0 ]; then
        pass "Frames being processed ($FRAME_COUNT events)"
    else
        warn "No frame processing events in last 5 min"
    fi

    OCR_COUNT=$(echo "$LOGS" | grep -ci "ocr\|recognized" 2>/dev/null || echo "0")
    [ "$OCR_COUNT" -gt 0 ] && pass "OCR processing ($OCR_COUNT events)" || warn "No OCR events yet"

    AI_COUNT=$(echo "$LOGS" | grep -ci "note.*generat\|ai.*process\|claude" 2>/dev/null || echo "0")
    [ "$AI_COUNT" -gt 0 ] && pass "AI note generation ($AI_COUNT events)" || warn "No AI events yet"

    STORAGE_COUNT=$(echo "$LOGS" | grep -ci "note.*saved\|obsidian.*written\|storage" 2>/dev/null || echo "0")
    [ "$STORAGE_COUNT" -gt 0 ] && pass "Storage writes ($STORAGE_COUNT events)" || warn "No storage events yet"
else
    warn "App not running — skipping pipeline check"
fi
echo ""

# ─────────────────────────────────────────
echo -e "${BOLD}[6/7] Obsidian Vault${NC}"
# ─────────────────────────────────────────
if [ -d "$VAULT_PATH" ]; then
    pass "Vault exists: $VAULT_PATH"
else
    fail "Vault NOT found: $VAULT_PATH"
fi

if [ -d "$SCREENMIND_DIR" ]; then
    pass "ScreenMind folder exists"
else
    warn "ScreenMind subfolder not yet created (created on first note)"
    mkdir -p "$SCREENMIND_DIR"
    info "Created: $SCREENMIND_DIR"
fi

if [ -d "$DAILY_DIR" ]; then
    NOTE_COUNT=$(find "$DAILY_DIR" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    pass "Today's folder exists: $TODAY ($NOTE_COUNT notes)"

    if [ "$NOTE_COUNT" -gt 0 ]; then
        echo ""
        echo -e "  ${CYAN}Latest notes:${NC}"
        find "$DAILY_DIR" -name "*.md" -type f -exec ls -lt {} + 2>/dev/null | head -5 | while read -r line; do
            FNAME=$(echo "$line" | awk '{print $NF}' | xargs basename)
            echo -e "    ${DIM}$FNAME${NC}"
        done
    fi
else
    warn "No notes today yet ($TODAY)"
fi
echo ""

# ─────────────────────────────────────────
echo -e "${BOLD}[7/7] Recent Errors${NC}"
# ─────────────────────────────────────────
if [ -n "$PID" ]; then
    ERRORS=$(bash -c 'log show --predicate "process == \"ScreenMind\" AND subsystem BEGINSWITH \"com.screenmind\" AND messageType == 16" --last 5m --info --no-pager 2>&1 | grep -v "^Timestamp" | head -5' 2>/dev/null || echo "")
    if [ -n "$ERRORS" ]; then
        fail "Errors in last 5 minutes:"
        echo "$ERRORS" | while IFS= read -r line; do
            echo -e "    ${RED}$line${NC}"
        done
    else
        pass "No errors in last 5 minutes"
    fi
else
    warn "App not running — no errors to check"
fi

echo ""
echo -e "${BOLD}============================================${NC}"
echo -e "${BOLD}  Quick Reference${NC}"
echo -e "${BOLD}============================================${NC}"
echo ""
echo -e "  ${CYAN}Live logs:${NC}"
echo -e "    log stream --predicate 'subsystem BEGINSWITH \"com.screenmind\"' --info"
echo ""
echo -e "  ${CYAN}Watch for new notes:${NC}"
echo -e "    fswatch ~/Desktop/pkmdev-notes/ScreenMind/"
echo -e "    ${DIM}(install: brew install fswatch)${NC}"
echo ""
echo -e "  ${CYAN}Grant Screen Recording:${NC}"
echo -e "    System Settings > Privacy & Security > Screen Recording"
echo -e "    Remove + re-add /Applications/ScreenMind.app"
echo ""
echo -e "  ${CYAN}Re-store API key:${NC}"
echo -e "    security add-generic-password -s com.screenmind -a com.screenmind.anthropic-api-key -w YOUR_KEY"
echo ""
echo -e "${BOLD}============================================${NC}"
