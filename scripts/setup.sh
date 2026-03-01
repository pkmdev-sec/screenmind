#!/bin/bash
set -euo pipefail

# ScreenMind — First-time Setup
# Stores your Anthropic API key in macOS Keychain and verifies vault access.

KEYCHAIN_SERVICE="com.screenmind.anthropic-api-key"
VAULT_PATH="$HOME/Desktop/pkmdev-notes"

echo "============================================"
echo "  ScreenMind — Setup"
echo "============================================"
echo ""

# Step 1: API Key
echo "[1/3] Anthropic API Key"
echo ""

# Check if key already exists
EXISTING_KEY=$(security find-generic-password -s "$KEYCHAIN_SERVICE" -w 2>/dev/null || echo "")
if [ -n "$EXISTING_KEY" ]; then
    MASKED="${EXISTING_KEY:0:10}...${EXISTING_KEY: -4}"
    echo "  Found existing key: $MASKED"
    read -p "  Replace it? (y/N): " REPLACE
    if [[ "$REPLACE" != "y" && "$REPLACE" != "Y" ]]; then
        echo "  Keeping existing key."
    else
        read -sp "  Enter your Anthropic API key: " API_KEY
        echo ""
        security delete-generic-password -s "$KEYCHAIN_SERVICE" 2>/dev/null || true
        security add-generic-password -s "$KEYCHAIN_SERVICE" -a "ScreenMind" -w "$API_KEY"
        echo "  Saved to Keychain."
    fi
else
    read -sp "  Enter your Anthropic API key: " API_KEY
    echo ""
    if [ -z "$API_KEY" ]; then
        echo "  ERROR: No key entered. Pipeline will not work without an API key."
        echo "  You can add it later via Settings > AI in the app."
    else
        security add-generic-password -s "$KEYCHAIN_SERVICE" -a "ScreenMind" -w "$API_KEY"
        echo "  Saved to Keychain."
    fi
fi
echo ""

# Step 2: Obsidian Vault
echo "[2/3] Obsidian Vault"
if [ -d "$VAULT_PATH" ]; then
    echo "  Vault found: $VAULT_PATH"
    # Create ScreenMind subfolder
    mkdir -p "$VAULT_PATH/ScreenMind"
    echo "  ScreenMind folder: $VAULT_PATH/ScreenMind/"
else
    echo "  WARNING: Vault not found at $VAULT_PATH"
    echo "  Notes will be saved to SwiftData only (no Obsidian export)."
fi
echo ""

# Step 3: Screen Recording Permission
echo "[3/3] Screen Recording Permission"
echo "  macOS will prompt you for Screen Recording access"
echo "  when ScreenMind first tries to capture your screen."
echo ""
echo "  To pre-grant access:"
echo "    System Settings > Privacy & Security > Screen Recording"
echo "    Toggle ON for ScreenMind"
echo ""

# Verify
echo "============================================"
echo "  Setup Complete!"
echo "============================================"
echo ""
echo "  API Key:    $(security find-generic-password -s "$KEYCHAIN_SERVICE" -w >/dev/null 2>&1 && echo "Stored in Keychain" || echo "NOT SET")"
echo "  Vault:      $([ -d "$VAULT_PATH/ScreenMind" ] && echo "$VAULT_PATH/ScreenMind/" || echo "NOT FOUND")"
echo "  Permission: Check System Settings > Privacy > Screen Recording"
echo ""
echo "  Next: Launch ScreenMind and click Start Monitoring!"
echo "============================================"
