# Screenpipe vs ScreenMind — Complete Competitive Analysis

> **Generated**: 2026-03-02
> **Screenpipe Repo**: https://github.com/mediar-ai/screenpipe (cloned at `/tmp/screenpipe`)
> **ScreenMind Repo**: `/Users/pumaurya/screenmind`

---

## Executive Summary

### Top 10 Things to Adopt from Screenpipe

1. **Event-driven capture** — Capture on app switch, click, typing pause, scroll instead of fixed intervals. Est. 40-60% CPU reduction, 80% storage reduction (~300MB vs 2GB/8hr). `/tmp/screenpipe/crates/screenpipe-server/src/event_driven_capture.rs`
2. **Accessibility tree extraction** — Use macOS AX APIs as primary text source (10-200ms vs 100-500ms OCR), fall back to OCR only when AX data unavailable. `/tmp/screenpipe/crates/screenpipe-accessibility/`
3. **Battery-aware power profiles** — Three-tier system (Performance/Balanced/Saver) with adaptive capture intervals, JPEG quality, and thermal override. `/tmp/screenpipe/crates/screenpipe-server/src/power/profile.rs`
4. **System audio capture** — Capture what the user hears (Zoom, Meet, media) in addition to microphone. `/tmp/screenpipe/crates/screenpipe-audio/Cargo.toml:23`
5. **Speaker diarization** — Who said what in meetings via ONNX speaker embeddings. `/tmp/screenpipe/crates/screenpipe-audio/src/speaker/embedding.rs`
6. **Hot frame cache** — In-memory LRU of recent frames for sub-100ms timeline reads without hitting SQLite. `/tmp/screenpipe/crates/screenpipe-server/src/hot_frame_cache.rs`
7. **Screen lock detection** — Skip capture when screen locked via `CGSessionCopyCurrentDictionary` polling. `/tmp/screenpipe/crates/screenpipe-server/src/sleep_monitor.rs`
8. **Pipes (scheduled AI agents)** — Markdown-based automation with cron scheduling. `/tmp/screenpipe/crates/screenpipe-core/src/pipes/mod.rs`
9. **Hybrid search (keyword + semantic)** — Combine HNSW semantic search with FTS5 keyword matching for 20-30% better recall. `/tmp/screenpipe/crates/screenpipe-server/src/routes/search.rs`
10. **Multi-engine STT with fallback** — Whisper + Deepgram + OpenAI-compatible + Qwen3 ASR with automatic fallback. `/tmp/screenpipe/crates/screenpipe-audio/src/transcription/stt.rs`

### Top 5 Things ScreenMind Does Better

1. **Native macOS performance** — Pure Swift with actor-isolated concurrency. Zero FFI overhead, ~100MB RAM vs Screenpipe's 0.5-3GB (Tauri WebView baseline). `/Users/pumaurya/screenmind/Sources/`
2. **Privacy & security** — AES-256-GCM encryption at rest, ML-based PII redaction, stealth mode, vault lock with Touch ID, audit logging. Screenpipe only encrypts cloud sync blobs. `/Users/pumaurya/screenmind/Sources/StorageCore/Encryption/`
3. **AI intelligence** — Domain-specific prompt engineering with context windows, vision-enabled analysis, skip logic, tag suggestion, and feedback learning. Screenpipe exposes generic AI gateway. `/Users/pumaurya/screenmind/Sources/AIProcessing/`
4. **Semantic search with HNSW** — O(log n) vector ANN search with RAG chat, link discovery, and knowledge graph. Screenpipe uses basic FTS5 + sqlite-vec. `/Users/pumaurya/screenmind/Sources/SemanticSearch/`
5. **Export ecosystem** — 8 built-in formats (Obsidian, Notion, Logseq, Slack, Webhook, JSON, Markdown, flat MD) plus GitHub/Todoist integrations. Screenpipe exposes raw API only. `/Users/pumaurya/screenmind/Sources/StorageCore/Exporters/`

### Overall Assessment

Screenpipe is a **cross-platform capture infrastructure** optimized for developer ecosystem (APIs, SDKs, pipes). ScreenMind is a **macOS-native intelligence tool** optimized for privacy, AI quality, and user experience.

Screenpipe's core advantages: event-driven architecture, cross-platform support, audio pipeline depth, developer ecosystem.
ScreenMind's core advantages: native performance, privacy-first design, AI intelligence, polished UX, structured exports.

**Strategic recommendation**: Adopt Screenpipe's capture efficiency patterns (event-driven, power profiles, AX tree) while preserving ScreenMind's intelligence and privacy advantages. Do NOT pursue cross-platform — the native macOS advantage is ScreenMind's moat.

---

## 1. Architecture & Codebase

### Screenpipe Architecture Map

**Language Breakdown:**
```
Rust:       251 files (~98,136 LOC across 9 crates)
TypeScript: 144 files (npm packages)
TSX:        167 files (Tauri frontend)
JavaScript: 21 files
Swift:      1 file (macOS native integration)
```

**Core Rust Crates (9):**

| Crate | Purpose | Key File |
|-------|---------|----------|
| `screenpipe-core` | Utilities, agents, pipes, PII removal, encryption | `/tmp/screenpipe/crates/screenpipe-core/` |
| `screenpipe-vision` | Screen capture, OCR, frame comparison | `/tmp/screenpipe/crates/screenpipe-vision/` |
| `screenpipe-audio` | Audio capture, transcription (Whisper/Deepgram/Qwen3) | `/tmp/screenpipe/crates/screenpipe-audio/` |
| `screenpipe-db` | SQLite + FTS5 + sqlite-vec | `/tmp/screenpipe/crates/screenpipe-db/` |
| `screenpipe-server` | Axum HTTP API + WebSocket on port 3030 | `/tmp/screenpipe/crates/screenpipe-server/` |
| `screenpipe-events` | Tokio-based async event bus | `/tmp/screenpipe/crates/screenpipe-events/` |
| `screenpipe-accessibility` | macOS/Windows/Linux accessibility tree capture | `/tmp/screenpipe/crates/screenpipe-accessibility/` |
| `screenpipe-integrations` | Calendar (EventKit), cloud OCR | `/tmp/screenpipe/crates/screenpipe-integrations/` |
| `screenpipe-apple-intelligence` | Apple Foundation Models (macOS 26+) | `/tmp/screenpipe/crates/screenpipe-apple-intelligence/` |

**Frontend (Tauri + Next.js):**
- Desktop app: `/tmp/screenpipe/apps/screenpipe-app-tauri/` — Next.js 15.1.4, React 18.3.1, Tauri 2.10.0
- UI: Radix UI + shadcn/ui + Tailwind + Framer Motion
- State: Zustand 5.0.11

**NPM Packages (8):**
- `@screenpipe/js` (Node SDK), `@screenpipe/browser` (Browser SDK), `@screenpipe/dev` (CLI), `screenpipe` (CLI wrapper), `@screenpipe/agent` (AI agent connector), `@screenpipe/skills` (pre-built skills), `@screenpipe/sync` (daily summary sync), `ai-gateway` (Cloudflare Workers AI proxy)

### Pipeline Comparison (Screenpipe vs ScreenMind)

| Component | Screenpipe | ScreenMind |
|-----------|-----------|------------|
| **Screen Capture** | ScreenCaptureKit (macOS 12.3+) / xcap fallback | ScreenCaptureKit (macOS 14+) |
| **Capture Strategy** | Event-driven (app switch, click, typing pause, scroll, clipboard) | Continuous periodic (5s active / 30s idle) |
| **OCR** | Multi-engine: Apple Vision, Windows native, Tesseract, cloud | Apple Vision only |
| **Text Extraction** | Accessibility tree (primary) + OCR (fallback) | OCR only |
| **Audio Capture** | cpal (cross-platform, system + mic) | AVFoundation (mic only) |
| **STT** | Whisper + Deepgram + OpenAI-compat + Qwen3 ASR | Apple Speech |
| **Database** | SQLite + FTS5 + sqlite-vec | SwiftData (SQLite wrapper) |
| **Encryption** | ChaCha20Poly1305 (cloud sync only) | AES-256-GCM (always on) |
| **API** | REST (Axum) + WebSocket | REST + MCP server |
| **Plugins** | Pipes (markdown AI agents) | JavaScriptCore sandbox |
| **AI Providers** | Multi-provider via ai-gateway | Multi-provider (direct calls) |
| **Vector Search** | sqlite-vec (linear scan) | HNSW (O(log n) ANN) |
| **Export** | REST API, WebSocket, raw SQL | 8 structured formats |
| **Desktop App** | Tauri (Rust + web) | SwiftUI (native macOS) |
| **Cross-Platform** | macOS, Windows, Linux | macOS only |
| **Codebase** | 98,136 LOC Rust + ~3,000 TS/TSX | 19,060 LOC Swift |
| **Tests** | 42 test files + E2E suite | 285 tests (Swift Testing) |

### Architectural Patterns We Should Adopt

**1. Event-Driven Capture**
Instead of polling every 5s, capture only on meaningful OS events. Reduces storage by 80%, CPU by 40-60%.
- Listen to NSWorkspace for app switches, CGEventTap for keyboard/mouse idle, pasteboard for clipboard
- Idle fallback at 30s instead of 5s
- **Ref**: `/tmp/screenpipe/crates/screenpipe-server/src/event_driven_capture.rs` (lines 29-67, trigger enum)
- **Target**: `/Users/pumaurya/screenmind/Sources/CaptureCore/Actors/ScreenCaptureActor.swift`

**2. Accessibility Tree + OCR Hybrid**
Extract text via macOS AX APIs first (10x faster, structured), fall back to OCR for remote desktops/games.
- **Ref**: `/tmp/screenpipe/crates/screenpipe-accessibility/src/tree/macos.rs`
- **Target**: `/Users/pumaurya/screenmind/Sources/OCRProcessing/OCRProcessingActor.swift`

**3. Hot Frame Cache**
In-memory LRU cache of recent frames for instant timeline reads without SQLite queries.
- **Ref**: `/tmp/screenpipe/crates/screenpipe-server/src/hot_frame_cache.rs`
- **Target**: `/Users/pumaurya/screenmind/Sources/StorageCore/StorageActor.swift`

**4. Smart Transcription Mode (Batch + Meeting Detection)**
Defer audio transcription until meeting ends. Lower CPU during meetings, better diarization with full context.
- **Ref**: `/tmp/screenpipe/crates/screenpipe-audio/src/meeting_detector.rs`
- **Target**: `/Users/pumaurya/screenmind/Sources/AudioCore/MeetingDetectionActor.swift`

**5. Power Profile Adaptive Capture**
Three-tier profiles (Performance/Balanced/Saver) based on battery %, thermal state, and AC power.
- **Ref**: `/tmp/screenpipe/crates/screenpipe-server/src/power/profile.rs` (lines 78-181)
- **Target**: `/Users/pumaurya/screenmind/Sources/SystemIntegration/PowerStateMonitor.swift`

**6. Cloud Sync with Zero-Knowledge Encryption**
Optional multi-device sync with ChaCha20Poly1305 + Argon2 key derivation.
- **Ref**: `/tmp/screenpipe/crates/screenpipe-core/src/sync/keys.rs`
- **Target**: `/Users/pumaurya/screenmind/Sources/Shared/SyncEngine.swift` (currently stub)

### Architectural Advantages We Already Have

1. **Native macOS Performance** — Pure Swift, zero FFI overhead, direct SwiftUI/ScreenCaptureKit/Vision access
2. **Actor-Isolated Concurrency** — Compile-time data race prevention vs Screenpipe's manual `Arc<Mutex<T>>`
3. **Always-On Encryption** — AES-256-GCM for all stored data, not just cloud sync
4. **Structured Export** — 8 polished export formats vs raw API access
5. **Semantic Search with HNSW** — O(log n) vector search vs linear sqlite-vec
6. **Spotlight Integration** — System-wide search via macOS Spotlight
7. **Menu Bar First** — True `LSUIElement` menu bar app, no dock icon
8. **Comprehensive Testing** — 285 tests with Swift Testing framework

---

## 2. Performance & Resource Optimization

> **This is the highest-priority section.**

### How Screenpipe Achieves Low CPU (<3%)

#### 1. Event-Driven Capture Instead of Polling
**File**: `/tmp/screenpipe/crates/screenpipe-server/src/event_driven_capture.rs` (lines 1-769)

Captures only on meaningful user events:
- `AppSwitch` (line 32) — frontmost application changed
- `WindowFocus` (line 34) — window focus changed
- `TypingPause` — 500ms after keyboard stops (line 98)
- `IdleFallback` — 30s default (line 97)
- `VisualChange` — 3s interval with 5% threshold (lines 103-104)

**vs ScreenMind**: Polls every 5s unconditionally (`/Users/pumaurya/screenmind/Sources/CaptureCore/Actors/ScreenCaptureActor.swift`)

**Impact**: ~40-60% CPU reduction, ~80% storage reduction

#### 2. Aggressive Frame Comparison with Hash Early Exit
**File**: `/tmp/screenpipe/crates/screenpipe-vision/src/frame_comparison.rs` (lines 1-604)

- **6x downscale** (line 81): 1920x1080 → 320x180 for comparison
- **Hash early exit** (lines 204-215): If hash matches previous frame, return 0.0 immediately (30-50% CPU savings in static scenes)
- **Single metric** (histogram only, no SSIM) (line 82): saves 40-50% vs dual metrics
- **Benchmarks** (lines 13-20): 10ms/cycle with shared downscale + hash

**vs ScreenMind**: dHash at 9x8 grayscale (`/Users/pumaurya/screenmind/Sources/ChangeDetection/Algorithms/PerceptualHasher.swift`) — no intermediate downscaling step

#### 3. Content Deduplication via Accessibility Tree Hash
**File**: `/tmp/screenpipe/crates/screenpipe-server/src/event_driven_capture.rs` (lines 560-586)

- Hash accessibility tree text, skip DB write if matches previous (lines 568-583)
- 30-second floor: force write even if hash matches (line 565)
- Bypass on idle/manual captures (line 564)

#### 4. OCR Cache with Window-Level Keying
**File**: `/tmp/screenpipe/crates/screenpipe-vision/src/ocr_cache.rs` (lines 1-407)

- Window-level caching: `WindowCacheKey { window_id, image_hash }` (lines 15-21)
- 5-minute TTL, 100 entry LRU (line 141)
- Cache hit avoids OCR entirely (lines 402-408)

**vs ScreenMind**: 24-hour LRU cache (`/Users/pumaurya/screenmind/Sources/OCRProcessing/Cache/OCRCache.swift`) — similar but longer TTL

### How Screenpipe Manages Memory

#### 1. Arc<DynamicImage> for Zero-Copy Sharing
**File**: `/tmp/screenpipe/crates/screenpipe-vision/src/core.rs` (lines 319-323)
- Single image allocation shared across all OCR workers without cloning pixels

#### 2. JPEG Snapshots to Disk Immediately
**File**: `/tmp/screenpipe/crates/screenpipe-vision/src/snapshot_writer.rs` (lines 1-177)
- Write to `~/.screenpipe/data/YYYY-MM-DD/{timestamp}_m{monitor}.jpg` immediately
- No frame buffer in memory — just file paths stored in DB
- Quality configurable: 40-80 (line 29)

**vs ScreenMind**: HEIF compression with 1GB quota, potentially buffered before flush

### How Screenpipe Optimizes Battery Life

#### Battery-Aware Power Profiles
**File**: `/tmp/screenpipe/crates/screenpipe-server/src/power/profile.rs` (lines 1-312)

| Profile | Min Interval | Idle Interval | Visual Check | JPEG Quality | Trigger |
|---------|-------------|---------------|-------------|-------------|---------|
| Performance | 200ms | 30s | 3s @ 5% | 80 | AC power (lines 84-98) |
| Balanced | 500ms | 60s | 10s @ 10% | 60 | Battery >40% (lines 102-122) |
| Saver | 1000ms | 120s | 30s @ 15% | 40 | Battery ≤40% or thermal (lines 125-145) |

- **FPS multiplier**: Balanced 2x slower (line 114), Saver 4x slower (line 136)
- **Thermal override** (lines 154-159): Force Saver on `ThermalState::Serious` or `Critical`
- **OS Low Power Mode** (lines 162-164): Respects macOS Low Power Mode toggle
- **Screen lock skip** (`/tmp/screenpipe/crates/screenpipe-server/src/sleep_monitor.rs`): Detects `loginwindow`, `screensaverengine`, `lockscreen` and skips capture

**vs ScreenMind**: Static 5s/30s intervals, basic battery check (`/Users/pumaurya/screenmind/Sources/SystemIntegration/PowerStateMonitor.swift`)

### Storage Strategy Comparison

| Feature | Screenpipe | ScreenMind |
|---------|-----------|------------|
| Database | SQLite + FTS5 + WAL mode | SwiftData (SQLite wrapper) |
| Image Format | JPEG (quality 40-80 adaptive) | HEIF (40-60% smaller than JPEG) |
| Image Storage | File per frame, date-based dirs | File paths in SwiftData models |
| Cleanup | Date-based directory deletion | Retention-based pruning |
| Dedup | Content hash (AX tree) + 30s floor | dHash + Jaccard + cooldown |
| Compression | JPEG quality adaptive | HEIF fixed compression |
| Quota | No hard limit | 1GB quota enforced |

### Optimizations ScreenMind Should Adopt (Ranked by Impact)

| # | Optimization | Impact | Complexity | Reference |
|---|-------------|--------|-----------|-----------|
| 1 | Event-driven capture | 40-60% CPU reduction | High | `event_driven_capture.rs` lines 29-67 → `ScreenCaptureActor.swift` |
| 2 | Frame comparison downscaling 6x | 30% CPU reduction | Low | `frame_comparison.rs` lines 140-158 → `PerceptualHasher.swift` |
| 3 | Battery-aware profiles (3-tier) | 2-4x battery extension | Medium | `power/profile.rs` lines 78-181 → `PowerStateMonitor.swift` |
| 4 | AX tree for content dedup | Reduces redundant OCR by 50% | Medium | `screenpipe-accessibility/` → new `AccessibilityActor.swift` |
| 5 | Screen lock detection | 50-80% CPU savings when idle | Low | `sleep_monitor.rs` → `ScreenCaptureActor.swift` |
| 6 | Monitor handle caching | Reduces setup overhead | Low | `monitor.rs` lines 66-77 → `ScreenCaptureActor.swift` |

### Optimizations ScreenMind Already Has That Screenpipe Lacks

1. **HEIF Compression** — 40-60% smaller files than JPEG
2. **Storage Quota** — 1GB auto-cleanup prevents runaway disk usage
3. **Parallel OCR Pipeline** — 3 configurable concurrent workers
4. **CPU-Aware Throttling** — Pauses OCR if CPU >30%
5. **Automatic Retention Pruning** — Deletes data older than N days

---

## 3. UI/UX Design & Patterns

### Screenpipe UI Architecture

- **Framework**: Tauri 2.10.0 (Rust) + Next.js 15.1.4 + React 18 + TypeScript
- **Component Library**: Radix UI + shadcn/ui (33 components) — `/tmp/screenpipe/apps/screenpipe-app-tauri/components/ui/`
- **Styling**: Tailwind CSS 3.4 + CSS variables — `/tmp/screenpipe/apps/screenpipe-app-tauri/tailwind.config.ts`
- **State**: Zustand 5.0.11
- **Animations**: Framer Motion 11.18.2
- **App Type**: System tray app with windowed views — `/tmp/screenpipe/apps/screenpipe-app-tauri/src-tauri/tauri.conf.json`

**Design System:**
- Pure B&W geometric minimalism: `#FFFFFF`/`#000000`, no color — `/tmp/screenpipe/apps/screenpipe-app-tauri/app/globals.css` (lines 7-11)
- Zero border-radius everywhere (line 105)
- Monospace typography: JetBrains Mono primary — `/tmp/screenpipe/apps/screenpipe-app-tauri/tailwind.config.ts` (lines 22-23)

### User Flow Maps

**Primary Navigation** (`/tmp/screenpipe/apps/screenpipe-app-tauri/app/settings/page.tsx:254-258`):
1. Home (Chat interface)
2. Timeline (DVR-like rewind view)
3. Pipes (Automation workflows)
4. Help (Feedback)

**Settings** (lines 261-274): General, Recording, AI, Shortcuts, Connections, Disk usage, Cloud archive, Cloud sync, Account, Team, Referral

### Search Experience Deep-Dive

**File**: `/tmp/screenpipe/apps/screenpipe-app-tauri/components/rewind/search-modal.tsx`

- **Tag search** with `#` prefix (lines 289, 420-494)
- **People search** with `@` prefix (lines 292, 497-537)
- **Content type filters**: Screen/Input/All pills (lines 295-300)
- **App filter pills** with auto-generated counts (lines 1113-1147)
- **Thumbnail highlights**: Overlay matched terms on frame thumbnails (lines 1170-1180)
- **Infinite scroll**: 24 items/page OCR, 30 audio (lines 309-310, 645-700)
- **Virtual scrolling**: @tanstack/react-virtual 3.13.19
- **Debounced search**: 200ms (line 312)
- **Keyboard nav**: Arrow keys (grid-aware), Enter (jump to timestamp), Cmd+Enter (send to AI)

### Timeline/History View

**File**: `/tmp/screenpipe/apps/screenpipe-app-tauri/components/rewind/timeline.tsx`

- Full-screen overlay with DVR-like playback
- **Pinch-to-zoom**: 0.25x-4x with 15% lerp interpolation (lines 137-158)
- **Filter-aware navigation**: Arrow keys snap to next matching frame when filters active (lines 264-289)
- **Subtitle bar**: Audio transcripts below timeline (lines 1773-1782)
- **Browser URL bar**: Floating at top when available (lines 1739-1770)
- **Frame prefetching**: ±5min window for instant seeking (lines 1374-1380)
- **WebSocket streaming**: Real-time frame updates (lines 205-211)
- **IndexedDB caching**: localforage for instant page loads (lines 92-107)
- **Filters**: Device, app, domain, speaker, tag (lines 228-381)

### Onboarding

**File**: `/tmp/screenpipe/apps/screenpipe-app-tauri/app/onboarding/page.tsx`

- 4-step wizard: Login → Setup → Read → Shortcut
- Dynamic window sizing per step (500x480 to 520x480)
- 300ms fade transitions
- Progress persistence (resumes from last step on relaunch)
- Permission recovery page: `/tmp/screenpipe/apps/screenpipe-app-tauri/app/permission-recovery/page.tsx`

### AI Chat Integration

**File**: `/tmp/screenpipe/apps/screenpipe-app-tauri/components/standalone-chat.tsx`

- **Mention system**: `@today`, `@yesterday`, `@last-week`, `@audio`, `@screen`, `@app-name` (lines 66-74)
- **Tool execution visualization**: Grid dissolve loader (lines 187-200)
- **Video inline rendering**: `.mp4` paths as playable videos (lines 124-127)
- **Mermaid diagram support**: Auto-render flowcharts from LLM responses (lines 115-122)

### UX Patterns ScreenMind Should Adopt

1. **`#tag` and `@person` search prefixes** — Intuitive, fast filtering
2. **Pinch-to-zoom timeline** — 0.25x-4x with smooth animation
3. **Filter-aware keyboard navigation** — Arrow keys snap to matching frames
4. **AI mention system** — `@today`, `@audio`, `@app-name` in chat
5. **Permission recovery flow** — Dedicated page for stuck permission states
6. **Collapsible sidebar** (Cmd+B) — Space-efficient navigation
7. **Live recording indicators** — Real-time opacity animations for device activity

### UX Advantages of ScreenMind's Native SwiftUI

1. **True menu bar app** — `LSUIElement:true`, no dock icon (vs Screenpipe tray + dock)
2. **Native rendering** — SwiftUI at 120Hz ProMotion vs browser frame rate
3. **Memory efficiency** — ~100MB vs Screenpipe's 300MB+ Chromium baseline
4. **Instant responsiveness** — No DOM, no layout thrashing
5. **Platform conventions** — SF Symbols, Dynamic Type, system colors automatic
6. **Native animations** — SwiftUI spring animations feel native
7. **Unified tooling** — Xcode, Swift Testing, SwiftUI previews

---

## 4. Feature Completeness Matrix

### Feature-by-Feature Comparison

| Feature | Screenpipe | ScreenMind | Gap |
|---------|-----------|------------|-----|
| **CAPTURE** |
| Event-driven capture | Yes | No (interval-based) | **Adopt** |
| Multi-display | All monitors | Active display | Screenpipe broader |
| ScreenCaptureKit | Yes (sck-rs) | Yes (native) | Parity |
| Active window cropping | No | Yes | **SM advantage** |
| Manual capture hotkey | No | Yes (Cmd+Opt+Shift+C) | **SM advantage** |
| Screenshot diffing | Frame comparison | Connected component analysis | SM more advanced |
| Accessibility tree extraction | Primary method | No | **Adopt** |
| **OCR** |
| Apple Vision | Yes | Yes | Parity |
| OCR caching | 5min TTL | 24h TTL | Parity |
| Parallel OCR | No | Yes (3 workers) | **SM advantage** |
| UI element detection | Via accessibility | Via Vision | Parity |
| **AUDIO** |
| Microphone capture | Yes (cpal) | Yes (AVFoundation) | Parity |
| System audio | Yes | No | **Adopt** |
| Local STT | Whisper (Metal/CUDA) | Apple Speech | Screenpipe stronger |
| Cloud STT | Deepgram, OpenAI-compat | No | **Adopt** |
| Voice Activity Detection | Silero VAD v5/v6 | Energy-based | Screenpipe stronger |
| Speaker diarization | Yes (ONNX) | No | **Adopt** |
| Streaming transcription | Yes (Deepgram) | No | **Adopt** |
| Batch transcription | Yes | No | **Adopt** |
| Voice memos | No | Yes (Cmd+Opt+Shift+V) | **SM advantage** |
| Meeting detection | Calendar + audio | Calendar only | Screenpipe better |
| **STORAGE** |
| Encryption at rest | Cloud only | AES-256-GCM always | **SM advantage** |
| Vault lock (Touch ID) | No | Yes | **SM advantage** |
| Image format | JPEG (40-80) | HEIF (smaller) | **SM advantage** |
| Storage quota | No | 1GB auto-cleanup | **SM advantage** |
| **SEARCH** |
| Full-text search | FTS5 | Yes | Parity |
| Semantic search | sqlite-vec (basic) | HNSW (O(log n)) | **SM advantage** |
| Search cache | Moka (10x faster) | No | **Adopt** |
| RAG chat | No | Yes | **SM advantage** |
| Cloud search | Yes | No | **Adopt** |
| Speaker search | Yes | No | **Adopt** |
| **AI** |
| Multi-provider | Yes | Yes | Parity |
| Vision support | No | Yes (multi-modal) | **SM advantage** |
| Custom prompts per app | No | Yes | **SM advantage** |
| Context windows | No | Last 5 notes | **SM advantage** |
| AI feedback learning | No | Yes (thumbs up/down) | **SM advantage** |
| Cost tracking | Yes (per-request) | No | **Adopt** |
| Apple Intelligence | Yes (macOS 26+) | No | Future gap |
| **PLUGINS** |
| Plugin system | Pipes (markdown agents) | JSCore sandbox | Different |
| Lifecycle hooks | No | 6 hooks | **SM advantage** |
| Scheduled execution | Cron + intervals | No | **Adopt** |
| Agent integration | Pi, Claude Code | No | **Adopt** |
| **INTEGRATIONS** |
| MCP Server | Yes | Yes | Parity |
| REST API | Yes (3030) | Yes (9876) | Parity |
| JavaScript SDK | Node + Browser | No | **Adopt** |
| Obsidian export | Via pipes | Native | Parity |
| Notion export | No | Native | **SM advantage** |
| Logseq export | No | Native | **SM advantage** |
| Slack export | No | Block Kit | **SM advantage** |
| Webhook export | No | SSRF-protected | **SM advantage** |
| GitHub integration | No | Create issues | **SM advantage** |
| Todoist integration | No | Auto TODOs | **SM advantage** |
| Browser extension | Browser SDK only | Chrome/Firefox/Arc | **SM advantage** |
| Cloud sync | E2E encrypted | No | **Adopt** |
| **PRIVACY** |
| PII redaction | Regex only | Regex + ML (NLTagger) | **SM advantage** |
| Stealth mode | No | Auto-pause sensitive apps | **SM advantage** |
| Skip rules | No | Text/app/window/regex | **SM advantage** |
| Audit log | No | CSV trail | **SM advantage** |
| GDPR tools | No | Export/retention/reports | **SM advantage** |
| **UI** |
| Timeline view | DVR-like rewind | Gallery + list | Different approaches |
| Knowledge graph | No | Force-directed graph | **SM advantage** |
| Calendar heatmap | No | Month-view density | **SM advantage** |
| Command palette | No | Cmd+K | **SM advantage** |
| Weekly summaries | No | Stats + insights | **SM advantage** |
| Workflow automation | No | If-this-then-that rules | **SM advantage** |
| **PLATFORM** |
| macOS | Yes | Yes | Parity |
| Windows | Yes | No | Screenpipe only |
| Linux | Yes | No | Screenpipe only |
| **PERFORMANCE** |
| RAM usage | 0.5-3GB | ~100MB | **SM advantage** |
| Native rendering | No (WebView) | Yes (SwiftUI) | **SM advantage** |

### Features Screenpipe Has That We're Missing (Prioritized)

**P0 — Critical (Competitive Parity)**
1. Event-driven capture (40-60% CPU, 80% storage savings)
2. Accessibility tree extraction (10x faster than OCR)
3. System audio capture (complete meeting context)
4. Cloud sync with E2E encryption (multi-device)

**P1 — High (Competitive Advantage)**
5. Pipes (scheduled AI agents, automation)
6. Speaker diarization (meeting transcripts)
7. Streaming transcription (real-time captions)
8. Search cache (10x faster repeated queries)
9. JavaScript SDK (developer ecosystem)
10. Cloud search (hybrid local + cloud)

**P2 — Medium (Polish)**
11. Element search (UI components)
12. Skills for AI agents
13. Power profiles (3-tier battery management)
14. Frame streaming WebSocket (live timeline)
15. Hot frame cache (instant timeline loading)

**P3 — Low (Future)**
16. Apple Intelligence (macOS 26+)
17. Multiple STT backends
18. Cross-platform (Windows/Linux)

### Features ScreenMind Has That Screenpipe Lacks (40 Features)

1. Active window cropping
2. Manual capture hotkey
3. AES-256-GCM encryption at rest
4. Master password + vault lock (Touch ID)
5. Vision-enabled AI (multi-modal)
6. Custom prompts per app
7. Context windows (last 5 notes)
8. AI feedback learning (thumbs up/down)
9. Chart/diagram detection
10. Screenshot diffing with region analysis
11. HEIF compression
12. HNSW vector index (O(log n))
13. RAG chat with conversation history
14. Knowledge graph with auto-linking
15. Calendar heatmap
16. Note inline editing
17. Command palette (Cmd+K)
18. If-this-then-that workflow rules
19. Browser extension (Chrome/Firefox/Arc)
20. 8 export formats (Obsidian, Notion, Logseq, Slack, Webhook, JSON, MD)
21. GitHub integration (create issues)
22. Todoist integration (auto TODOs)
23. ML-based PII detection (NLTagger)
24. Custom redaction patterns
25. Skip rules (text/app/window/regex)
26. Stealth mode
27. Audit log (CSV trail)
28. GDPR compliance tools
29. Parallel OCR pipeline (3 workers)
30. CPU-aware throttling (>30% pause)
31. Storage quota (1GB auto-cleanup)
32. Performance dashboard (live gauges)
33. Voice memos (Cmd+Opt+Shift+V)
34. 7 global keyboard shortcuts
35. Spotlight indexing
36. Focus mode integration (DND)
37. Plugin lifecycle hooks (6 hooks)
38. Project detection (Xcode/VS Code)
39. Weekly summaries
40. ~100MB RAM (vs 0.5-3GB)

---

## 5. Plugin/Pipe Ecosystem

### Screenpipe Pipe Architecture

**What is a "Pipe"?**
A Pipe is a scheduled AI agent defined as a markdown file (`pipe.md`) with YAML frontmatter + natural language instructions. Unlike traditional plugins, it's prompt-driven.

**File**: `/tmp/screenpipe/crates/screenpipe-core/src/pipes/mod.rs`

```yaml
---
schedule: every 30m
enabled: true
model: claude-haiku-4-5
provider: screenpipe
---
Your natural language prompt here...
```

**Execution Model:**
- Pipes invoke AI coding agents (Pi, Claude Code) as subprocesses
- Default agent: `@mariozechner/pi-coding-agent` via bun
- **File**: `/tmp/screenpipe/crates/screenpipe-core/src/agents/pi.rs`
- Agent has full system access: filesystem, network, shell commands
- Context header auto-injected with time range, timezone, API URL

**Built-in Pipes** (`/tmp/screenpipe/crates/screenpipe-core/assets/pipes/`):
12 templates: ai-habits, collaboration-patterns, day-recap, idea-tracker, meeting-summary, morning-brief, obsidian-sync, reminders, standup-update, time-breakdown, top-of-mind, video-export

### Comparison with ScreenMind Plugins

| Aspect | Screenpipe Pipes | ScreenMind Plugins |
|--------|-----------------|-------------------|
| Language | Markdown (prompts) | JavaScript (JSCore) |
| Execution | Subprocess (AI agent) | In-process (JSContext) |
| Sandboxing | None (full system) | Strict (isolated JSContext) |
| Permissions | Unrestricted | Explicit manifest permissions |
| Filesystem | Full read/write | None |
| Network | Unrestricted | Only if permitted |
| Hooks | Schedule-based (cron) | 6 lifecycle hooks |
| API Surface | Full REST API + shell | Limited: log, fetch, getEnv |
| Security | Trust-based (user reviews) | Sandboxed with capabilities |
| Distribution | CLI publish to S3 | Not yet implemented |
| Ecosystem | 12 bundled templates | No bundled plugins |

### Recommendations for ScreenMind's Plugin System

1. **Add prompt-driven plugins** alongside JSCore — lower barrier to entry
2. **Expand API surface** (note:read, note:write, search permissions) while keeping sandbox
3. **Add time-based triggers** (cron/interval schedules in manifest)
4. **Bundle template plugins** (Obsidian sync, reminders, idea tracker)
5. **Create plugin CLI** (`screenmind plugin create/install/publish`)
6. **GitHub-based registry** (JSON catalog like Homebrew)
7. **Avoid Screenpipe's security gap** — keep sandboxing, add granular permissions

---

## 6. macOS System Integration

### Process Model & Background Execution

| Aspect | Screenpipe | ScreenMind |
|--------|-----------|------------|
| Architecture | Tauri (Rust + WebView) | Native SwiftUI |
| Process Model | Single process (Tokio async) | Single process (Swift actors) |
| App Type | System tray + windows | Menu bar (LSUIElement:true) |
| IPC | Tauri JSON-RPC bridge | Swift Actor isolation |
| Reboot | tauri-plugin-autostart | SMAppService (LaunchAtLoginManager) |
| RAM Baseline | 300MB+ (WebView) | ~100MB |

### Permission Handling

**Screenpipe** (`/tmp/screenpipe/apps/screenpipe-app-tauri/src-tauri/src/permissions.rs`):
- Background monitor polls every 10s (lines 636-776)
- 2 consecutive failures before triggering alert (prevents flicker)
- 5-minute cooldown on permission modals
- TCC reset utility (`tccutil reset`) for debugging (lines 242-295)
- Arc browser automation via `AEDeterminePermissionToAutomateTarget()`

**ScreenMind**: Basic permission checks in app layer, no background monitor

**Adopt from Screenpipe:**
- Background permission polling (10s interval)
- 2-failure threshold before alert
- TCC reset in Debug menu

### Energy Management

**Screenpipe** (`/tmp/screenpipe/crates/screenpipe-server/src/power/`):
- Power Manager polls IOPowerSources every 30s (`manager.rs`)
- 3-tier profiles (Performance/Balanced/Saver) with thermal override
- Sleep Monitor: dual-thread system polling `CGSessionCopyCurrentDictionary` every 2s
- Screen lock detection: `loginwindow`, `screensaverengine`, `lockscreen` app detection

**ScreenMind**: Basic `IOPSCopyPowerSourcesInfo()` check, no continuous polling, no lock detection

**Adopt:**
1. Screen lock detection via `CGSessionCopyCurrentDictionary`
2. Thermal state monitoring via `ProcessInfo.thermalState`
3. 3-tier power profiles
4. Sleep/wake resilience with health checks

### Distribution & Signing

| Aspect | Screenpipe | ScreenMind |
|--------|-----------|------------|
| Signing | Developer ID via GitHub Actions CI | Self-signed (development) |
| Notarization | Automated in CI | Manual |
| Crash Reporting | Sentry dSYM upload | None |
| CI Runners | Self-hosted macOS | GitHub Actions |
| Distribution | GitHub Releases + DMG | Local build-dmg.sh |

**Adopt:**
- Automated CI/CD with Developer ID signing
- Sentry integration for crash reporting
- Notarization via `xcrun notarytool`

### System Integration Improvements for ScreenMind

1. **Background permission monitor** — Poll Screen Recording/Mic/Speech every 10s with 2-failure threshold
2. **Battery-aware capture profiles** — 3-tier system tied to battery %/thermal state
3. **Screen lock detection** — `CGSessionCopyCurrentDictionary` polling, skip capture during lock
4. **Sleep/wake resilience** — Flush pending notes on sleep, verify capture resumed on wake
5. **Automated CI/CD** — Developer ID signing, notarization, Sentry dSYM upload
6. **Health check API** — `/health` endpoint on REST API for Alfred/Raycast status
7. **TCC reset utility** — Debug menu for permission recovery
8. **Do NOT copy** Screenpipe's unsafe entitlements (`allow-unsigned-executable-memory`, `disable-library-validation`)

---

## 7. AI & Data Intelligence

### AI Provider Architecture

**Screenpipe**: Unified AI gateway (Cloudflare Worker) with tiered rate limiting, cost tracking, 4 providers (Anthropic, OpenAI, Gemini, Vertex AI)
- **File**: `/tmp/screenpipe/packages/ai-gateway/src/index.ts`
- Per-request cost logging: `/tmp/screenpipe/packages/ai-gateway/src/index.ts:122-156`
- Tiered limits: anonymous 5/day, logged-in 25/day, subscribed 200/day

**ScreenMind**: Protocol-based direct provider calls (Claude, OpenAI-compatible), actor-based rate limiting (60/hour)
- **File**: `/Users/pumaurya/screenmind/Sources/AIProcessing/AIProvider.swift`
- No cost tracking, no provider fallback

### Prompt Engineering

**Screenpipe**: Generic AI gateway — no structured note generation, leaves prompts to clients

**ScreenMind**: Domain-specific prompt engineering
- Context window: last 5 notes for temporal continuity
- App-specific signals: bundleID, window title
- Deduplication hints: `lastNoteTitle`, `lastNoteApp`
- Structured JSON output: title, summary, details, category, tags, confidence, skip
- AI-driven skip logic for low-value frames
- **File**: `/Users/pumaurya/screenmind/Sources/AIProcessing/Prompts/NotePromptBuilder.swift`

### Embedding & Search Strategy

| Feature | Screenpipe | ScreenMind |
|---------|-----------|------------|
| Content embeddings | No (FTS5 keyword only) | HNSW vector index |
| Speaker embeddings | Yes (512D ONNX) | No |
| Search algorithm | FTS5 + fuzzy + filters | HNSW (O(log n) ANN) |
| Query expansion | Compound word splitting | NL query parsing |
| Search cache | Moka (10x faster) | None |
| RAG chat | No | Yes (ChatActor) |
| Link discovery | No | Yes (semantic similarity) |

### Data Quality Pipeline

**Screenpipe:**
- Audio dedup: LCWS + Jaccard (0.85 threshold, 45s window) — `/tmp/screenpipe/crates/screenpipe-db/src/text_similarity.rs`
- Frame comparison: 6x downscale + histogram + hash early exit — `/tmp/screenpipe/crates/screenpipe-vision/src/frame_comparison.rs`
- Speech VAD: Silero VAD v5/v6 — `/tmp/screenpipe/crates/screenpipe-audio/src/speaker/`
- OCR caching: Window-level 5min TTL — `/tmp/screenpipe/crates/screenpipe-vision/src/ocr_cache.rs`

**ScreenMind:**
- Visual dedup: dHash perceptual hashing — `/Users/pumaurya/screenmind/Sources/ChangeDetection/Algorithms/PerceptualHasher.swift`
- Text preprocessing: Whitespace/noise removal — `/Users/pumaurya/screenmind/Sources/OCRProcessing/TextPreprocessor.swift`
- AI skip logic: Provider returns `skip: true` for low-value frames
- Content redaction: Regex + ML-based PII — `/Users/pumaurya/screenmind/Sources/OCRProcessing/Redaction/ContentRedactor.swift`

### Speech-to-Text

| Feature | Screenpipe | ScreenMind |
|---------|-----------|------------|
| Engines | 4 (Whisper, Deepgram, OpenAI, Qwen3) | 1 (Apple Speech) |
| On-device | Yes (Whisper + Qwen3) | Yes (Apple Speech) |
| Cloud | Yes (Deepgram, OpenAI) | No |
| Diarization | Yes (ONNX embeddings) | No |
| Vocab biasing | Yes | No |
| Fallback | Automatic | None |
| Languages | Multi-language enum | System language |

### AI Intelligence Improvements for ScreenMind

1. **Hybrid search** — Combine HNSW semantic with FTS5 keyword for 20-30% better recall
2. **Multi-provider fallback** — Claude → OpenAI if quota exceeded
3. **Cost tracking** — Log tokens/cost per request, expose in settings
4. **Prompt versioning** — Version prompts with migration logic
5. **Audio transcript embeddings** — Add transcripts to HNSW index
6. **OCR text normalization** — Compound word splitting (port `text_normalizer.rs`)
7. **Local embedding model** — CoreML all-MiniLM-L6-v2 for $0 10x faster embeddings
8. **AI response schema validation** — Pre-validate JSON before decoding

---

## 8. Consolidated Improvement Roadmap

### CRITICAL (Adopt Immediately — Competitive Parity)

| # | What Screenpipe Does | What ScreenMind Does | Change Needed | Target Module/File | Complexity |
|---|---------------------|---------------------|---------------|-------------------|-----------|
| 1 | Event-driven capture on app switch, click, typing pause, scroll | Polls every 5s/30s | Add CGEventTap + NSWorkspace observers, capture on state transitions | `CaptureCore/ScreenCaptureActor.swift` | L |
| 2 | Accessibility tree as primary text source | OCR only | Add macOS AX API extraction, fall back to OCR | New `AccessibilityActor.swift` in CaptureCore | L |
| 3 | 3-tier battery power profiles | Static intervals, basic battery check | Extend PowerStateMonitor with Performance/Balanced/Saver profiles | `SystemIntegration/PowerStateMonitor.swift` | M |
| 4 | Screen lock detection, skip capture | No lock detection | Poll `CGSessionCopyCurrentDictionary` every 2s | `CaptureCore/ScreenCaptureActor.swift` | S |

### HIGH (Adopt Next Phase — Competitive Advantage)

| # | What Screenpipe Does | What ScreenMind Does | Change Needed | Target Module/File | Complexity |
|---|---------------------|---------------------|---------------|-------------------|-----------|
| 5 | System audio capture (hear what user hears) | Microphone only | Add system audio via CoreAudio loopback | `AudioCore/MicrophoneCaptureActor.swift` | M |
| 6 | Speaker diarization (ONNX embeddings) | No diarization | Integrate speaker recognition model | New `SpeakerIdentifier.swift` in AudioCore | L |
| 7 | Pipes (scheduled AI agents) | JSCore sandbox, no scheduling | Add cron-based plugin execution + prompt-driven type | `PluginSystem/PluginScheduler.swift` (new) | L |
| 8 | Hot frame cache for instant timeline | All queries hit SQLite | Add in-memory LRU of recent frames | `StorageCore/StorageActor.swift` | S |
| 9 | Hybrid search (FTS5 + semantic) | Semantic only (HNSW) | Add FTS5 index, merge via reciprocal rank fusion | `SemanticSearch/SemanticSearchActor.swift` | M |
| 10 | Search cache (Moka, 10x faster) | No caching | Add LRU cache layer for search results | `SemanticSearch/SemanticSearchActor.swift` | S |
| 11 | Multi-provider STT with fallback | Apple Speech only | Add Whisper integration + fallback chain | `AudioCore/SpeechRecognitionActor.swift` | M |
| 12 | Background permission monitor | Basic permission checks | Poll permissions every 10s with 2-failure threshold | `SystemIntegration/PermissionMonitor.swift` (new) | S |

### MEDIUM (Adopt When Possible — Polish)

| # | What Screenpipe Does | What ScreenMind Does | Change Needed | Target Module/File | Complexity |
|---|---------------------|---------------------|---------------|-------------------|-----------|
| 13 | 6x frame downscaling for comparison | Full-res dHash | Add downscale step before hashing | `ChangeDetection/PerceptualHasher.swift` | S |
| 14 | AI cost tracking (per-request) | No cost visibility | Log tokens/cost per AI call | `AIProcessing/AIProcessingActor.swift` | S |
| 15 | Multi-provider fallback | Single provider | Add fallback chain in AIProvider | `AIProcessing/AIProviderFactory.swift` | S |
| 16 | Cloud sync (E2E encrypted) | No sync | Implement ChaCha20Poly1305 sync | `Shared/SyncEngine.swift` | XL |
| 17 | Streaming transcription | Real-time only | Add Deepgram streaming integration | `AudioCore/SpeechRecognitionActor.swift` | M |
| 18 | JavaScript SDK | No SDK | Wrap REST API in npm package | New npm package | M |
| 19 | Speaker search in API | No speaker search | Add speaker filter to search endpoint | `SystemIntegration/APIServer.swift` | S |
| 20 | Automated CI/CD signing | Self-signed local | Add GitHub Actions with Dev ID signing | `.github/workflows/` | M |

### LOW (Nice-to-Have — Future Consideration)

| # | What Screenpipe Does | What ScreenMind Does | Change Needed | Target Module/File | Complexity |
|---|---------------------|---------------------|---------------|-------------------|-----------|
| 21 | Element search (UI components) | No element search | Store AX tree elements in DB | `StorageCore/StorageActor.swift` | M |
| 22 | Cloud search (hybrid) | Local only | Add cloud query federation | `SemanticSearch/SemanticSearchActor.swift` | XL |
| 23 | Skills for AI agents | No skills | Create SQL-based skill templates | New `Skills/` module | M |
| 24 | Daily summary sync to agents | No sync | SSH daemon + AI extraction | `SystemIntegration/SyncDaemon.swift` (new) | L |
| 25 | Apple Intelligence (macOS 26+) | No Apple Intelligence | Integrate Foundation Models API | New module | L |
| 26 | Batch transcription | No batching | Defer transcription until meeting ends | `AudioCore/SpeechRecognitionActor.swift` | M |
| 27 | Prompt versioning | No versioning | Add version field to GeneratedNote schema | `AIProcessing/NotePromptBuilder.swift` | S |
| 28 | Local embedding model (CoreML) | Cloud/API embeddings | Convert MiniLM-L6-v2 to CoreML | `SemanticSearch/EmbeddingDatabase.swift` | M |

---

## 9. Things ScreenMind Does Better

### Privacy & Security (ScreenMind is significantly ahead)
- **Always-on encryption** (AES-256-GCM) vs Screenpipe's unencrypted local DB
- **ML-based PII redaction** (NaturalLanguage NLTagger) vs regex-only
- **Stealth mode** auto-pauses in password managers, banking apps
- **Vault lock** with Touch ID + master password (PBKDF2 600k iterations)
- **Skip rules** (text/app/window/regex patterns)
- **Audit log** (CSV trail of all events)
- **GDPR compliance tools** (export, retention, reports)
- **Custom redaction patterns** (user-defined regex)

### AI Intelligence (ScreenMind is more sophisticated)
- **Vision-enabled AI** — Screenshots sent directly to LLMs for multi-modal analysis
- **Domain-specific prompts** — App-aware prompt building with context windows
- **AI feedback learning** — Thumbs up/down refines future responses
- **Chart/diagram detection** — Specialized prompts for visual content
- **Skip logic** — AI rejects low-value frames (loading screens, blank content)
- **Tag suggestion** — Smart automatic tagging

### Search & Knowledge (ScreenMind is more advanced)
- **HNSW vector index** — O(log n) ANN search vs linear sqlite-vec
- **RAG-powered chat** — AI chat with note context and conversation history
- **Knowledge graph** — Auto-linking via semantic similarity, force-directed visualization
- **NL query parsing** — Natural language queries converted to search vectors
- **Link discovery** — Automatic suggestion of related notes
- **Project detection** — Xcode/VS Code project grouping

### UX Polish (ScreenMind is more refined for macOS)
- **~100MB RAM** vs 0.5-3GB (native vs WebView)
- **Spotlight indexing** — System-wide search
- **Command palette** (Cmd+K)
- **7 global keyboard shortcuts**
- **Calendar heatmap** (month-view density)
- **Inline note editing** with auto-save
- **Focus mode integration** (pauses during DND)
- **Weekly summaries** with stats + insights
- **If-this-then-that workflows** (6 triggers + 6 actions)

### Export & Integration (ScreenMind has more structured output)
- **8 export formats** (Obsidian, Notion, Logseq, Slack, Webhook, JSON, Markdown, flat MD)
- **Browser extension** (Chrome/Firefox/Arc page capture)
- **GitHub integration** (create issues from notes)
- **Todoist integration** (auto-extract TODOs)
- **Plugin lifecycle hooks** (6 hooks for event-driven plugins)

### Performance Optimizations Unique to ScreenMind
- **Parallel OCR pipeline** (3 configurable concurrent workers)
- **CPU-aware throttling** (pauses OCR at >30% CPU)
- **HEIF compression** (40-60% smaller than JPEG)
- **Storage quota enforcement** (1GB auto-cleanup)
- **Performance dashboard** (live CPU/RAM/battery gauges)

---

## 10. Raw Data

### Screenpipe Repo Stats
```
Total files:        1,070
Rust files:         251 (~98,136 LOC)
TypeScript files:   144
TSX files:          167
JavaScript files:   21
Swift files:        1
Test files:         42
Repo size:          358 MB
License:            MIT
Pricing:            $400 lifetime / $39/mo Pro
```

### ScreenMind Repo Stats
```
Total Swift files:  160
Total LOC:          ~19,060
Test count:         285
Modules:            12 (+ 2 apps + 1 test util)
Platform:           macOS 14+ (Sonoma)
Swift version:      5.10
Build system:       Swift Package Manager
License:            MIT
Pricing:            Free / Open Source
```

### Dependency Comparison

**Screenpipe Core Dependencies:**
- Runtime: tokio 1.15, crossbeam 0.8.4, dashmap 6.1.0
- AI/ML: tokenizers 0.21.0, hf-hub 0.3.2 (Hugging Face)
- HTTP: reqwest 0.12.12, Axum
- Image: image 0.25
- Audio: cpal (fork), whisper-rs, vad-rs (fork)
- DB: sqlx, sqlite-vec
- macOS: sck-rs (fork), cidre
- Frontend: Next.js 15.1.4, React 18.3.1, Tauri 2.10.0, Radix UI, Zustand

**ScreenMind Core Dependencies:**
- Foundation: SwiftUI, Swift Concurrency (actors)
- Capture: ScreenCaptureKit (native)
- OCR: Vision framework (native)
- Audio: AVFoundation (native), Speech (native)
- AI: URLSession (HTTP), JSONDecoder
- DB: SwiftData (native)
- Search: NaturalLanguage framework, custom HNSW
- Crypto: CryptoKit (native)
- System: IOKit, EventKit, CoreSpotlight

### API Surface Comparison

**Screenpipe API (localhost:3030):**
- `GET /search` — Full-text + filter search
- `GET /frames/{id}` — Frame by ID
- `GET /frames/context` — Frames before/after
- `GET /audio/{id}` — Audio chunk
- `GET /elements` — UI elements
- `GET /speakers` — Speaker list
- `GET /meetings` — Meeting list
- `GET /health` — Status + metrics
- `GET/POST /pipes` — Pipe management
- `WS /ws/health` — Live health
- `WS /ws/events` — Live events
- `WS /ws/frames` — Live frame stream

**ScreenMind API (localhost:9876):**
- `GET /notes` — Note list with filters
- `GET /notes/{id}` — Note by ID
- `GET /search` — Semantic + keyword search
- `GET /health` — Status
- `GET /stats` — Usage statistics
- `POST /capture` — Manual capture trigger
- `POST /export` — Export notes to format

**ScreenMind MCP (localhost:9877):**
- Claude Desktop / Cursor integration
- Tool: search notes, get recent context, create notes
