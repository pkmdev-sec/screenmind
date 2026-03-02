# ScreenMind Browser Extension

Chrome/Edge extension that sends browser context (URL, title, selected text) to ScreenMind for AI-powered note generation.

## Installation

1. Open Chrome and navigate to `chrome://extensions/`
2. Enable "Developer mode" (toggle in top-right)
3. Click "Load unpacked"
4. Select the `browser-extension` directory
5. Pin the extension to your toolbar

## Usage

1. Start ScreenMind desktop app (must be running for extension to work)
2. Click the ScreenMind extension icon in your browser
3. Click "Capture This Page" to send the current page context to ScreenMind
4. Or select text on any page and click "Capture Selection"
5. Right-click context menu: "Send to ScreenMind" also available

## Features

- Captures URL, page title, and selected text
- Extracts favicon and meta description
- Sends data to local ScreenMind API (port 9876)
- Connection status indicator
- Works offline (data stays local)

## Requirements

- ScreenMind desktop app running
- Chrome/Edge browser (Manifest V3)

## Icon Setup

Place icon files in the `icons/` directory:
- `icon16.png` (16x16)
- `icon48.png` (48x48)
- `icon128.png` (128x128)

You can generate these from the ScreenMind app icon or use a simple brain emoji/icon.
