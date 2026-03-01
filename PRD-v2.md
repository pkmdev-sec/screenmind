# ScreenMind PRD v2.0 — The World's Best Open-Source Screen Memory Platform

**Version:** 2.0
**Date:** 2026-03-02
**Status:** Master Roadmap (Phases 7-14)
**Author:** ScreenMind Development Team

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Competitive Positioning](#2-competitive-positioning)
3. [What Makes ScreenMind Unique](#3-what-makes-screenmind-unique)
4. [Phased Roadmap (Phases 7-14)](#4-phased-roadmap-phases-7-14)
   - [Phase 7: Audio Intelligence](#phase-7-audio-intelligence)
   - [Phase 8: Semantic Search & AI Chat](#phase-8-semantic-search--ai-chat)
   - [Phase 9: Knowledge Graph & Connections](#phase-9-knowledge-graph--connections)
   - [Phase 10: Plugin System & Developer Platform](#phase-10-plugin-system--developer-platform)
   - [Phase 11: Cross-Platform Foundation](#phase-11-cross-platform-foundation)
   - [Phase 12: Distribution & Growth](#phase-12-distribution--growth)
   - [Phase 13: Advanced UX](#phase-13-advanced-ux)
   - [Phase 14: Frontier Features](#phase-14-frontier-features)
5. [Technical Architecture Evolution](#5-technical-architecture-evolution)
6. [Success Metrics](#6-success-metrics)
7. [Risk Assessment](#7-risk-assessment)
8. [Prioritization Matrix](#8-prioritization-matrix)

---

## 1. Executive Summary

### Vision

ScreenMind is the **private, hackable, AI-native screen memory platform** — your second brain that captures, understands, and connects everything you see and hear on your computer. We're building the #1 open-source alternative to Rewind AI, Screenpipe, and Microsoft Recall.

### Current State (Phases 1-6 Complete)

ScreenMind has shipped 6 phases covering:
- **Phase 1:** UX (Timeline, Search, Settings, Onboarding)
- **Phase 2:** Multi-Provider AI (Claude, OpenAI, Ollama, Gemini, Custom) + Multi-Format Export
- **Phase 3:** Privacy (Redaction, Skip Rules, Encryption, Audit Log)
- **Phase 4:** Performance (Resource Monitor, OCR Cache, Quota Enforcement)
- **Phase 5:** Innovation (Multi-Display, Manual Capture, Smart Tags)
- **Phase 6:** Developer Tools (CLI, REST API)

**Current capabilities:** 70+ source files, 9 Swift modules, 100+ features, 30+ settings, 5 AI providers, 4 export formats, CLI + REST API, Obsidian-native integration.

### What's Missing vs. Competitors

To become the **#1 open-source screen memory tool**, we need:

1. **Audio capture + speech-to-text** (Screenpipe has this)
2. **Semantic/vector search** (currently keyword-only)
3. **Plugin system** (Screenpipe has Pipes + App Store)
4. **Cross-platform** (Windows, Linux)
5. **AI chat over notes** (Mem.ai's killer feature)
6. **Natural language queries** ("what was I working on yesterday at 3pm?")
7. **Knowledge graph** (visualize connections between notes)
8. **Meeting detection + transcription**
9. **Browser extension** (URL + page title enrichment)
10. **Homebrew formula + auto-updates** (distribution)

### Strategic Goals (2026-2027)

By end of 2026:
- **10,000+ GitHub stars** (currently ~200)
- **Cross-platform** (macOS + Windows + Linux)
- **Plugin ecosystem** (15+ community plugins)
- **Semantic search + AI chat** operational
- **Product Hunt Top 5** launch

By mid-2027:
- **50,000+ active installs**
- **Knowledge graph** with visual UI
- **iOS companion app** (read-only)
- **Established as Screenpipe/Rewind alternative**

---

## 2. Competitive Positioning

### Feature Comparison Matrix

| Feature | ScreenMind v2.0 (target) | Screenpipe | Rewind AI | Microsoft Recall | Mem.ai | LiveRecall |
|---------|-------------------------|------------|-----------|------------------|---------|-----------|
| **Screen capture** | ✅ Multi-display, active window | ✅ 24/7 | ✅ Cloud | ✅ NPU-accelerated | ❌ | ✅ Basic |
| **Audio capture** | ✅ **Phase 7** | ✅ 24/7 | ✅ Cloud | ❌ | ✅ Voice memos | ❌ |
| **Speech-to-text** | ✅ **Phase 7** | ✅ Whisper | ✅ Cloud | ❌ | ✅ Proprietary | ❌ |
| **Meeting detection** | ✅ **Phase 7** | ❌ | ✅ | ❌ | ✅ | ❌ |
| **Semantic search** | ✅ **Phase 8** | ❌ Keyword only | ✅ | ✅ | ✅ Deep Search | ✅ Embeddings |
| **AI chat (RAG)** | ✅ **Phase 8** | ❌ | ✅ Cloud | ❌ | ✅ | ❌ |
| **Natural language queries** | ✅ **Phase 8** | ❌ | ✅ | ✅ | ✅ | ❌ |
| **Knowledge graph** | ✅ **Phase 9** | ❌ | ❌ | ❌ | ✅ Implicit | ❌ |
| **Plugin system** | ✅ **Phase 10** | ✅ Pipes (App Store) | ❌ Closed | ❌ Closed | ❌ Closed | ❌ |
| **Developer API** | ✅ REST + CLI | ✅ TypeScript/Rust SDK | ❌ | ❌ | ❌ | ❌ |
| **MCP server** | ✅ **Phase 10** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Cross-platform** | ✅ **Phase 11** (macOS/Win/Linux) | ✅ macOS/Win/Linux | ✅ (was) macOS/Win | ❌ Windows only | ✅ Cloud | ✅ macOS/Win/Linux |
| **Privacy (local-first)** | ✅ 100% local | ✅ Local + optional cloud | ❌ Cloud-only | ✅ Local | ❌ Cloud | ✅ Local |
| **Encryption** | ✅ AES-256-GCM | ❌ | ✅ Cloud | ✅ | ✅ Cloud | ❌ |
| **Multi-provider AI** | ✅ 5 providers | ❌ OpenAI only | ✅ Proprietary | ✅ Azure/OpenAI | ✅ Proprietary | ❌ Local models |
| **Obsidian integration** | ✅ Native export | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Redaction + skip rules** | ✅ Pre-AI | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Open source** | ✅ MIT | ✅ MIT | ❌ Closed | ❌ Closed | ❌ Closed | ✅ GPL |
| **Cost** | Free / API costs | $400 lifetime | $20/mo | Free (Win11+) | $15/mo | Free |

### Competitive Advantages (Post-Phase 14)

1. **Obsidian-native** — No competitor exports to Obsidian with full frontmatter + daily summaries + wiki-links
2. **Multi-provider AI** — Only solution supporting Claude, OpenAI, Ollama (offline), Gemini, and custom endpoints
3. **Privacy-first architecture** — Content redaction BEFORE AI (competitors don't have this)
4. **Hackable plugin system** — Open-source JS/TS plugins with sandboxed execution
5. **Local semantic search** — On-device embeddings via MLX (no cloud dependency)
6. **Modular Swift architecture** — Clean 9-module design, actor-isolated, testable
7. **True cross-platform** — Shared core, native UIs (vs Electron wrappers)

### Strategic Differentiation

**ScreenMind is positioned as:**
- The **developer-friendly** alternative to Rewind (hackable, API-first, open)
- The **privacy-conscious** alternative to cloud tools (local-first, encrypted, auditable)
- The **power user's** choice (Obsidian, CLI, REST API, plugins, semantic search)
- The **affordable** option (free app + bring-your-own-API-key vs $20-400)

---

## 3. What Makes ScreenMind Unique

### Unfair Advantages

1. **Obsidian Ecosystem Integration**
   - Only screen memory tool that writes Obsidian-compatible Markdown
   - Daily summaries, frontmatter, wiki-links, tags
   - Leverages 1M+ Obsidian user base

2. **Multi-Provider AI Strategy**
   - Only tool supporting 5+ AI providers with unified prompts
   - Offline mode via Ollama (no internet required)
   - Provider-agnostic note quality

3. **Privacy-First Pipeline**
   - Pre-AI redaction (credit cards, API keys, passwords removed BEFORE cloud)
   - Skip rules save API costs
   - AES-256-GCM encryption at rest
   - Audit logs for compliance

4. **Actor-Isolated Swift Architecture**
   - Thread-safe by design
   - Modular, testable, maintainable
   - 100x more performant than Electron competitors

5. **Developer Platform**
   - REST API + CLI + Plugin SDK
   - MCP server for Claude Desktop / Cursor integration
   - Webhook export for workflow automation

6. **Open-Source Trust**
   - MIT license
   - Community-driven roadmap
   - Auditable codebase (no telemetry, no tracking)

### User Personas

**Persona 1: The Knowledge Worker**
- Uses Obsidian for personal knowledge management
- Wants automatic capture of research, articles, meetings
- Values privacy (local-first, no cloud)
- Willing to pay for API keys ($2-5/month)

**Persona 2: The Developer**
- Needs to recall code snippets, Stack Overflow answers, docs
- Wants CLI access for scripting
- Prefers open-source, hackable tools
- Uses Ollama for offline inference

**Persona 3: The Creator**
- Writers, designers, researchers
- Captures inspiration, references, mood boards
- Uses semantic search to find "that thing I saw last week"
- Wants visual timeline + knowledge graph

**Persona 4: The Enterprise User**
- Compliance requirements (audit logs, encryption)
- Self-hosted, air-gapped deployments
- Needs Windows/Linux support
- Custom AI endpoints (internal LLMs)

---

## 4. Phased Roadmap (Phases 7-14)

---

## Phase 7: Audio Intelligence

**Goal:** Capture audio (system + microphone) and transcribe speech to text, making ScreenMind a true multimodal memory tool.

**Why it matters:** Screenpipe's killer feature is 24/7 audio capture. We need parity to compete. Audio captures conversations, meetings, videos — things OCR misses.

### Features

#### 7.1 System Audio Capture
**Requirements:**
- Capture system audio output (videos, calls, music)
- Use macOS **AVAudioEngine** + **BlackHole** virtual audio driver
- Sample rate: 48kHz, 16-bit PCM
- Circular buffer (30s rolling window to avoid huge files)
- VAD (Voice Activity Detection) to skip silence/music-only segments

**Technical Approach:**
```swift
// New module: AudioCore
import AVFoundation

actor AudioCaptureActor {
    private var engine: AVAudioEngine
    private var tapNode: AVAudioNode
    private var vadDetector: VoiceActivityDetector

    func start() async throws {
        // Install tap on system audio (via BlackHole or Loopback)
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, time in
            Task { await self.processAudioBuffer(buffer) }
        }

        try engine.start()
    }

    func processAudioBuffer(_ buffer: AVAudioPCMBuffer) async {
        // VAD: detect if buffer contains speech vs silence/music
        guard await vadDetector.containsSpeech(buffer) else { return }

        // Save to circular buffer (30s window)
        await audioBuffer.append(buffer)
    }
}
```

**Dependencies:**
- **BlackHole** (open-source virtual audio driver) — user installs via Homebrew
- Or **Loopback** (paid, $99) for easier setup

**Success Criteria:**
- ✅ System audio captured at 48kHz
- ✅ VAD filters silence (>90% accuracy)
- ✅ Circular buffer prevents disk overflow
- ✅ <1% CPU overhead

**Complexity:** **M** (Medium) — AVAudioEngine is well-documented, VAD adds complexity

---

#### 7.2 Microphone Capture
**Requirements:**
- Capture microphone input (user's voice)
- Toggle on/off in Settings > Capture > Audio
- Privacy warning (macOS Microphone permission)
- Separate stream from system audio

**Technical Approach:**
```swift
actor MicrophoneCaptureActor {
    private var audioEngine: AVAudioEngine

    func start() async throws {
        let inputNode = audioEngine.inputNode
        let format = inputNode.inputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, time in
            Task { await self.processMicBuffer(buffer) }
        }

        try audioEngine.start()
    }
}
```

**macOS Permissions:**
- Add `NSMicrophoneUsageDescription` to Info.plist
- Request permission via `AVCaptureDevice.requestAccess(for: .audio)`

**Success Criteria:**
- ✅ Microphone audio captured
- ✅ Toggle in Settings (default: off)
- ✅ Permission prompt shown on first enable

**Complexity:** **S** (Small) — Similar to system audio, simpler (no BlackHole)

---

#### 7.3 Speech-to-Text (On-Device)
**Requirements:**
- Transcribe audio to text using **Apple Speech framework**
- On-device (no cloud), supports 50+ languages
- Real-time transcription (streaming)
- Fallback: **Whisper.cpp** (offline Whisper via MLX)

**Technical Approach:**
```swift
import Speech

actor SpeechRecognitionActor {
    private let recognizer = SFSpeechRecognizer()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func transcribe(_ audioBuffer: AVAudioPCMBuffer) async -> String? {
        guard let recognizer, recognizer.isAvailable else {
            // Fallback to Whisper.cpp
            return await whisperTranscribe(audioBuffer)
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.append(audioBuffer)
        request.endAudio()

        return await withCheckedContinuation { continuation in
            task = recognizer.recognitionTask(with: request) { result, error in
                if let result {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    func whisperTranscribe(_ buffer: AVAudioPCMBuffer) async -> String? {
        // Use whisper.cpp Swift bindings or MLX Whisper
        // https://github.com/ggerganov/whisper.cpp
        // https://github.com/ml-explore/mlx-examples/tree/main/whisper
    }
}
```

**Why Apple Speech First:**
- Built-in, no dependencies
- On-device (private)
- 50+ languages
- Real-time streaming

**Why Whisper.cpp Fallback:**
- Better accuracy for technical terms
- Offline (works in airplane mode)
- Smaller model footprint (MLX-optimized for Apple Silicon)

**Success Criteria:**
- ✅ Apple Speech transcribes with <5s latency
- ✅ Whisper fallback works offline
- ✅ Accuracy >90% for English
- ✅ Multi-language support (user selects in Settings)

**Complexity:** **M** (Medium) — Apple Speech is easy, Whisper.cpp integration adds complexity

---

#### 7.4 Meeting Detection
**Requirements:**
- Auto-detect when user is in a meeting (Zoom, Teams, Google Meet, Slack)
- Calendar integration via **EventKit** (read upcoming meetings)
- Audio activity heuristic (2+ people talking)
- Generate special "Meeting" notes with attendees, duration, transcript

**Technical Approach:**
```swift
import EventKit

actor MeetingDetectionActor {
    private let eventStore = EKEventStore()

    func detectCurrentMeeting() async -> Meeting? {
        // Check if current time overlaps with calendar event
        let now = Date()
        let calendars = eventStore.calendars(for: .event)

        let predicate = eventStore.predicateForEvents(
            withStart: now.addingTimeInterval(-300), // 5 min before
            end: now.addingTimeInterval(300), // 5 min after
            calendars: calendars
        )

        let events = eventStore.events(matching: predicate)
        guard let event = events.first else { return nil }

        return Meeting(
            title: event.title,
            attendees: event.attendees?.map { $0.name } ?? [],
            startTime: event.startDate,
            endTime: event.endDate
        )
    }

    func detectByAudio() async -> Bool {
        // Heuristic: If audio contains multiple speakers (speaker diarization)
        // Return true
    }
}
```

**macOS Permissions:**
- Add `NSCalendarsUsageDescription` to Info.plist
- Request EventKit access

**Success Criteria:**
- ✅ Calendar events detected (5 min before/after tolerance)
- ✅ Audio-based detection (heuristic: >1 speaker)
- ✅ Meeting notes include: title, attendees, duration, transcript, action items
- ✅ Privacy: user can disable calendar access

**Complexity:** **M** (Medium) — EventKit is easy, audio detection harder

---

#### 7.5 Speaker Diarization
**Requirements:**
- Identify "who said what" in multi-speaker audio
- Label speakers as Speaker 1, Speaker 2, etc.
- Use **pyannote.audio** (Python library) via MLX or subprocess

**Technical Approach:**
```swift
actor SpeakerDiarizationActor {
    func diarize(audioPath: String) async -> [Segment] {
        // Call Python script with pyannote.audio
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [
            "diarization.py",
            audioPath
        ]

        let pipe = Pipe()
        process.standardOutput = pipe
        try? process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let json = try? JSONDecoder().decode([Segment].self, from: data)
        return json ?? []
    }
}

struct Segment: Codable {
    let speaker: String // "SPEAKER_00"
    let start: Double
    let end: Double
    let text: String
}
```

**Alternative: MLX-based diarization** (longer-term)
- Port pyannote to MLX Swift
- Fully on-device, no Python dependency

**Success Criteria:**
- ✅ 2+ speakers identified in meetings
- ✅ Transcript shows "Speaker 1: ...", "Speaker 2: ..."
- ✅ <10s processing time for 30-min meeting

**Complexity:** **L** (Large) — Requires Python bridge or MLX port

---

#### 7.6 Voice Memos
**Requirements:**
- Quick spoken notes via keyboard shortcut (⌘⌥⇧V)
- Records microphone for 30s (or until user stops)
- Transcribes instantly
- Saves as "Voice Memo" note in ScreenMind

**Technical Approach:**
```swift
actor VoiceMemoRecorder {
    private var isRecording = false
    private var audioBuffer: [AVAudioPCMBuffer] = []

    func startRecording() async {
        isRecording = true
        // Capture microphone for 30s or until stopRecording()
    }

    func stopRecording() async -> String? {
        isRecording = false
        let audioData = mergeBuffers(audioBuffer)
        return await transcribe(audioData)
    }
}
```

**UI:**
- Floating recording indicator (red dot)
- Keyboard shortcut: ⌘⌥⇧V (starts recording), press again to stop
- Notification on save: "Voice memo saved: 'Reminder to...'"

**Success Criteria:**
- ✅ Recording starts/stops with shortcut
- ✅ Transcription completes in <3s
- ✅ Note saved with "voice-memo" tag

**Complexity:** **S** (Small) — Reuses existing microphone + transcription

---

### Phase 7 Architecture Changes

**New Module: AudioCore**
```
AudioCore/
├── Actors/
│   ├── AudioCaptureActor.swift      (system audio)
│   ├── MicrophoneCaptureActor.swift (mic input)
│   ├── SpeechRecognitionActor.swift (Apple Speech + Whisper)
│   └── SpeakerDiarizationActor.swift
├── Models/
│   ├── AudioFrame.swift
│   ├── Transcript.swift
│   └── Meeting.swift
├── VAD/
│   └── VoiceActivityDetector.swift
└── Utilities/
    └── AudioBufferManager.swift
```

**Integration with PipelineCoordinator:**
```swift
// New stage in pipeline
// Stage 0c: Audio Processing (parallel to screen capture)
Task {
    for await audioFrame in audioCapture.frames() {
        guard let transcript = await speechRecognition.transcribe(audioFrame) else { continue }

        // Merge with OCR text
        let combinedText = ocrText + "\n\n[AUDIO]\n" + transcript

        // Send to AI for note generation
        await aiProcessor.generateNote(from: combinedText)
    }
}
```

**Settings UI:**
```swift
// Settings > Capture > Audio
Toggle("Enable System Audio Capture", isOn: $settings.audioSystemEnabled)
Toggle("Enable Microphone Capture", isOn: $settings.audioMicEnabled)
Picker("Speech Recognition", selection: $settings.speechEngine) {
    Text("Apple Speech").tag("apple")
    Text("Whisper (Offline)").tag("whisper")
}
Toggle("Meeting Detection", isOn: $settings.meetingDetectionEnabled)
Toggle("Speaker Diarization", isOn: $settings.speakerDiarizationEnabled)
```

### Phase 7 Success Metrics

| Metric | Target |
|--------|--------|
| Audio capture uptime | >95% (no crashes) |
| Transcription accuracy (English) | >90% |
| Meeting detection rate | >80% (for calendar events) |
| Voice memo turnaround | <3s (record → transcribe → save) |
| CPU overhead | <3% (audio processing) |
| User adoption (audio enabled) | >40% of users |

### Phase 7 Risks

| Risk | Mitigation |
|------|------------|
| **BlackHole setup complexity** | Provide Homebrew one-liner, video tutorial |
| **Apple Speech offline limits** | Fallback to Whisper.cpp |
| **Speaker diarization accuracy** | Start with simple 2-speaker, improve over time |
| **Privacy concerns (audio recording)** | Prominent settings, audit log, encryption |
| **macOS permission fatigue** | Bundle all permissions in onboarding |

**Estimated Timeline:** 6-8 weeks
**Estimated Complexity:** **L** (Large)

---

## Phase 8: Semantic Search & AI Chat

**Goal:** Replace keyword search with semantic/vector search and add "chat with your notes" RAG system — matching Mem.ai's killer feature.

**Why it matters:** Keyword search misses conceptual matches. "Find when I was debugging that auth issue" fails with keywords. Semantic search + AI chat unlocks natural language queries.

### Features

#### 8.1 Vector Embeddings (On-Device)
**Requirements:**
- Generate embeddings for all notes (title + summary + details)
- Use **MLX** (Apple's ML framework) with on-device models
- Model: **BAAI/bge-small-en-v1.5** (384-dim, 33MB, fast)
- Store embeddings in **SQLite** (SwiftData doesn't support vector types)

**Technical Approach:**
```swift
import MLX
import MLXFast

actor EmbeddingActor {
    private var model: EmbeddingModel

    init() async throws {
        // Load bge-small-en-v1.5 model via MLX
        self.model = try await EmbeddingModel.load(
            modelPath: Bundle.main.path(forResource: "bge-small-en-v1.5", ofType: "mlx")!
        )
    }

    func embed(_ text: String) async throws -> [Float] {
        // Tokenize + encode
        let tokens = tokenize(text)
        let embedding = try await model.encode(tokens)
        return embedding // 384-dim vector
    }
}
```

**Storage Schema:**
```sql
-- New table: note_embeddings
CREATE TABLE note_embeddings (
    note_id TEXT PRIMARY KEY,
    embedding BLOB NOT NULL, -- 384 floats = 1536 bytes
    created_at INTEGER NOT NULL
);

-- Index for fast lookups
CREATE INDEX idx_note_id ON note_embeddings(note_id);
```

**Embedding Pipeline:**
```swift
// After note saved in StorageActor
let embedding = try await embeddingActor.embed(note.title + " " + note.summary)
try await embeddingDB.save(noteID: note.id, embedding: embedding)
```

**Success Criteria:**
- ✅ Embeddings generated in <100ms per note
- ✅ 384-dim vectors stored efficiently
- ✅ Embeddings auto-generated on note save
- ✅ Backfill existing notes on first launch

**Complexity:** **M** (Medium) — MLX is new but well-documented

---

#### 8.2 Semantic Search
**Requirements:**
- Search by meaning, not keywords
- "Find when I was debugging that auth issue" → matches notes about authentication, errors, troubleshooting
- Use **cosine similarity** for vector search
- Hybrid search: semantic + keyword (best of both)

**Technical Approach:**
```swift
actor SemanticSearchActor {
    private let embeddingActor: EmbeddingActor
    private let embeddingDB: EmbeddingDatabase

    func search(query: String, limit: Int = 20) async throws -> [NoteMatch] {
        // 1. Generate query embedding
        let queryEmbedding = try await embeddingActor.embed(query)

        // 2. Compute cosine similarity with all note embeddings
        let allEmbeddings = try await embeddingDB.fetchAll()
        var scores: [(noteID: UUID, score: Float)] = []

        for (noteID, noteEmbedding) in allEmbeddings {
            let similarity = cosineSimilarity(queryEmbedding, noteEmbedding)
            scores.append((noteID, similarity))
        }

        // 3. Sort by similarity (descending)
        scores.sort { $0.score > $1.score }

        // 4. Fetch top N notes
        let topNotes = try await storageActor.fetchNotes(ids: scores.prefix(limit).map(\.noteID))

        return topNotes.map { note in
            NoteMatch(note: note, score: scores.first { $0.noteID == note.id }?.score ?? 0)
        }
    }

    func hybridSearch(query: String, limit: Int = 20) async throws -> [NoteMatch] {
        // Combine semantic + keyword results (weighted)
        let semanticResults = try await search(query: query, limit: limit * 2)
        let keywordResults = try await storageActor.searchNotes(query: query, limit: limit * 2)

        // Merge and re-rank (RRF: Reciprocal Rank Fusion)
        return mergeResults(semanticResults, keywordResults, limit: limit)
    }
}

func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
    let dot = zip(a, b).map(*).reduce(0, +)
    let normA = sqrt(a.map { $0 * $0 }.reduce(0, +))
    let normB = sqrt(b.map { $0 * $0 }.reduce(0, +))
    return dot / (normA * normB)
}
```

**UI Changes:**
```swift
// Timeline / Notes Browser search bar
TextField("Search notes (semantic)", text: $searchQuery)
    .onChange(of: searchQuery) {
        Task {
            notes = try await semanticSearch.hybridSearch(query: searchQuery)
        }
    }
```

**Success Criteria:**
- ✅ Semantic search finds conceptually similar notes (>80% relevance)
- ✅ Hybrid search outperforms keyword-only (user preference: 70%+)
- ✅ Search completes in <500ms for 10,000 notes
- ✅ Re-ranking improves top-5 accuracy by 30%

**Complexity:** **M** (Medium) — Cosine similarity is simple, RRF adds complexity

---

#### 8.3 Natural Language Queries
**Requirements:**
- Parse natural language queries into structured searches
- Examples:
  - "What was I working on yesterday at 3pm?" → Date filter + time range
  - "Show me coding notes from last week" → Category: coding, date: last 7 days
  - "Find all notes about Swift concurrency" → Semantic search: "Swift concurrency"
- Use lightweight NLP (pattern matching) or LLM (Claude/GPT) for parsing

**Technical Approach (Pattern Matching):**
```swift
actor NLQueryParser {
    func parse(_ query: String) -> SearchFilter {
        var filter = SearchFilter()

        // Date patterns
        if query.contains("yesterday") {
            filter.date = .yesterday
        } else if query.contains("last week") {
            filter.date = .lastWeek
        } else if query.contains("today") {
            filter.date = .today
        }

        // Category patterns
        if query.contains("coding") || query.contains("code") {
            filter.category = .coding
        } else if query.contains("meeting") {
            filter.category = .meeting
        }

        // Time patterns (regex for "3pm", "15:00", etc.)
        if let time = extractTime(from: query) {
            filter.timeRange = time
        }

        // Fallback: semantic search on remaining text
        filter.semanticQuery = query

        return filter
    }
}
```

**Alternative: LLM-Powered Parsing** (Phase 8.5)
```swift
// Send query to Claude: "Parse this search query into JSON"
let prompt = """
Parse this natural language search query into structured filters:
Query: "\(query)"

Output JSON:
{
  "date": "yesterday | last_week | today | ...",
  "category": "coding | meeting | research | ...",
  "time_range": { "start": "HH:mm", "end": "HH:mm" },
  "semantic_query": "remaining keywords"
}
"""
let response = try await claudeProvider.complete(prompt)
let filter = try JSONDecoder().decode(SearchFilter.self, from: response)
```

**UI:**
```swift
// Timeline / Notes Browser
TextField("Ask your notes...", text: $nlQuery)
    .onSubmit {
        Task {
            let filter = await nlParser.parse(nlQuery)
            notes = try await semanticSearch.search(filter: filter)
        }
    }
```

**Success Criteria:**
- ✅ 10+ date patterns recognized (yesterday, last week, Jan 15, etc.)
- ✅ 5+ category patterns recognized
- ✅ Time patterns extracted (3pm, 15:00, morning, afternoon)
- ✅ LLM fallback works for complex queries

**Complexity:** **M** (Medium) — Pattern matching is easy, LLM adds latency

---

#### 8.4 AI Chat Over Notes (RAG)
**Requirements:**
- Chat interface: "What did I learn about Swift actors?"
- RAG (Retrieval-Augmented Generation):
  1. Semantic search retrieves relevant notes
  2. Inject top 5 notes as context
  3. LLM generates answer
- Streaming responses (token-by-token)
- Chat history (multi-turn conversations)

**Technical Approach:**
```swift
actor ChatActor {
    private let semanticSearch: SemanticSearchActor
    private let aiProvider: any AIProvider
    private var chatHistory: [ChatMessage] = []

    func chat(query: String) async throws -> AsyncStream<String> {
        // 1. Retrieve relevant notes
        let notes = try await semanticSearch.search(query: query, limit: 5)

        // 2. Build context
        let context = notes.map { note in
            """
            [Note: \(note.title)]
            \(note.summary)
            \(note.details)
            """
        }.joined(separator: "\n\n")

        // 3. Build prompt
        let prompt = """
        You are a helpful assistant that answers questions based on the user's captured notes.

        Context (relevant notes):
        \(context)

        Chat history:
        \(chatHistory.map { "\($0.role): \($0.content)" }.joined(separator: "\n"))

        User: \(query)
        Assistant:
        """

        // 4. Stream response
        let stream = try await aiProvider.streamCompletion(prompt: prompt)

        // 5. Save to history
        chatHistory.append(ChatMessage(role: "user", content: query))

        return AsyncStream { continuation in
            Task {
                var fullResponse = ""
                for await token in stream {
                    fullResponse += token
                    continuation.yield(token)
                }
                chatHistory.append(ChatMessage(role: "assistant", content: fullResponse))
                continuation.finish()
            }
        }
    }
}

struct ChatMessage: Codable {
    let role: String // "user" | "assistant"
    let content: String
}
```

**UI:**
```swift
// New window: Chat with Notes (⌘⇧C)
struct ChatView: View {
    @State private var messages: [ChatMessage] = []
    @State private var input: String = ""

    var body: some View {
        VStack {
            ScrollView {
                ForEach(messages) { msg in
                    ChatBubble(message: msg)
                }
            }

            HStack {
                TextField("Ask your notes...", text: $input)
                    .onSubmit { sendMessage() }
                Button("Send") { sendMessage() }
            }
        }
    }

    func sendMessage() {
        messages.append(ChatMessage(role: "user", content: input))
        Task {
            for await token in try await chatActor.chat(query: input) {
                // Append tokens to last message
                messages[messages.count - 1].content += token
            }
        }
        input = ""
    }
}
```

**Success Criteria:**
- ✅ Chat responds in <3s (RAG retrieval + LLM generation)
- ✅ Top 5 notes provide sufficient context (>80% of queries)
- ✅ Multi-turn conversations work (history preserved)
- ✅ Streaming UI feels responsive (tokens appear instantly)

**Complexity:** **M** (Medium) — RAG is well-understood, streaming adds complexity

---

#### 8.5 Semantic Timeline Clustering
**Requirements:**
- Group notes by topic, not just time
- Visual clusters: "Here's everything about Swift concurrency from this week"
- Use **UMAP** (dimensionality reduction) to project 384-dim embeddings to 2D
- Render as scatter plot with clickable clusters

**Technical Approach:**
```swift
import Accelerate

actor TimelineClusteringActor {
    func cluster(notes: [NoteModel]) async throws -> [Cluster] {
        // 1. Fetch embeddings
        let embeddings = try await embeddingDB.fetch(noteIDs: notes.map(\.id))

        // 2. Reduce to 2D via UMAP (or t-SNE)
        let points2D = UMAP.reduce(embeddings, to: 2)

        // 3. Cluster via DBSCAN (density-based clustering)
        let clusters = DBSCAN.cluster(points2D, eps: 0.5, minPoints: 3)

        return clusters
    }
}
```

**UI:**
```swift
// Timeline > Semantic View (new tab)
ScatterPlotView(clusters: clusters) { cluster in
    // Click handler: show notes in cluster
    selectedNotes = cluster.notes
}
```

**Success Criteria:**
- ✅ Clusters are visually distinct (no overlap)
- ✅ Clicking cluster shows relevant notes
- ✅ Clusters update live as new notes arrive

**Complexity:** **L** (Large) — UMAP + DBSCAN are complex, visualization adds UI work

---

### Phase 8 Architecture Changes

**New Module: SemanticSearch**
```
SemanticSearch/
├── Actors/
│   ├── EmbeddingActor.swift
│   ├── SemanticSearchActor.swift
│   ├── NLQueryParser.swift
│   ├── ChatActor.swift
│   └── TimelineClusteringActor.swift
├── Models/
│   ├── Embedding.swift
│   ├── SearchFilter.swift
│   ├── NoteMatch.swift
│   └── Cluster.swift
├── Database/
│   └── EmbeddingDatabase.swift (SQLite wrapper)
└── ML/
    ├── EmbeddingModel.swift (MLX wrapper)
    └── UMAP.swift
```

**Dependencies:**
- **MLX Swift** (embeddings)
- **SQLite.swift** (vector storage)
- **Accelerate** (linear algebra for cosine similarity)

**Settings UI:**
```swift
// Settings > Search
Toggle("Enable Semantic Search", isOn: $settings.semanticSearchEnabled)
Picker("Embedding Model", selection: $settings.embeddingModel) {
    Text("bge-small-en-v1.5 (Fast, 33MB)").tag("bge-small")
    Text("bge-base-en-v1.5 (Accurate, 109MB)").tag("bge-base")
}
Toggle("Enable AI Chat", isOn: $settings.aiChatEnabled)
Slider("Search Results", value: $settings.searchLimit, in: 10...50)
```

### Phase 8 Success Metrics

| Metric | Target |
|--------|--------|
| Semantic search relevance | >80% (user rating) |
| Hybrid search adoption | >70% prefer over keyword |
| Chat response time | <3s (RAG + LLM) |
| Chat answer quality | >85% user satisfaction |
| Semantic timeline usage | >30% of timeline views |
| NL query parsing accuracy | >70% |

### Phase 8 Risks

| Risk | Mitigation |
|------|------------|
| **Embedding model size** | Use bge-small (33MB) by default, offer bge-base as upgrade |
| **Vector DB performance** | Index embeddings, use FAISS if SQLite too slow |
| **LLM costs (RAG)** | Cache frequent queries, use Ollama for offline |
| **UMAP complexity** | Start with simple 2D projection, defer full clustering |

**Estimated Timeline:** 8-10 weeks
**Estimated Complexity:** **XL** (Very Large)

---

## Phase 9: Knowledge Graph & Connections

**Goal:** Auto-discover relationships between notes and visualize as a knowledge graph — making ScreenMind a true "second brain" with network effects.

**Why it matters:** Notes in isolation are data. Connected notes are knowledge. Knowledge graphs unlock serendipity ("I forgot I wrote about this!").

### Features

#### 9.1 Auto-Link Related Notes
**Requirements:**
- Find notes that reference similar concepts (semantic similarity >0.7)
- Bi-directional links: Note A ↔ Note B
- Store in `note_links` table (many-to-many)
- Re-index on new note save

**Technical Approach:**
```swift
actor LinkDiscoveryActor {
    func discoverLinks(for note: NoteModel) async throws -> [UUID] {
        // 1. Get note embedding
        let embedding = try await embeddingDB.fetch(noteID: note.id)

        // 2. Find similar notes (cosine similarity >0.7)
        let allNotes = try await embeddingDB.fetchAll()
        var linkedNoteIDs: [UUID] = []

        for (otherNoteID, otherEmbedding) in allNotes where otherNoteID != note.id {
            let similarity = cosineSimilarity(embedding, otherEmbedding)
            if similarity > 0.7 {
                linkedNoteIDs.append(otherNoteID)
            }
        }

        // 3. Save links
        try await linkDB.save(from: note.id, to: linkedNoteIDs)

        return linkedNoteIDs
    }
}
```

**Storage Schema:**
```sql
CREATE TABLE note_links (
    from_note_id TEXT NOT NULL,
    to_note_id TEXT NOT NULL,
    similarity REAL NOT NULL,
    created_at INTEGER NOT NULL,
    PRIMARY KEY (from_note_id, to_note_id)
);

CREATE INDEX idx_from_note ON note_links(from_note_id);
CREATE INDEX idx_to_note ON note_links(to_note_id);
```

**Success Criteria:**
- ✅ Links discovered for 80%+ of notes
- ✅ Average 3-5 links per note
- ✅ Bi-directional navigation works in UI

**Complexity:** **M** (Medium)

---

#### 9.2 Visual Knowledge Graph
**Requirements:**
- Force-directed graph layout (nodes = notes, edges = links)
- Interactive: click node → show note, drag to explore
- Color-coded by category (coding = blue, research = green, etc.)
- Zoom, pan, search within graph

**Technical Approach:**
```swift
import SwiftUI

struct KnowledgeGraphView: View {
    @State private var nodes: [GraphNode] = []
    @State private var edges: [GraphEdge] = []
    @State private var selectedNode: GraphNode?

    var body: some View {
        ZStack {
            // Edges (lines)
            ForEach(edges) { edge in
                Path { path in
                    path.move(to: edge.from.position)
                    path.addLine(to: edge.to.position)
                }
                .stroke(Color.gray, lineWidth: 1)
            }

            // Nodes (circles)
            ForEach(nodes) { node in
                Circle()
                    .fill(node.color)
                    .frame(width: 20, height: 20)
                    .position(node.position)
                    .onTapGesture { selectedNode = node }
                    .gesture(DragGesture().onChanged { value in
                        // Update node position + re-layout
                        updateNodePosition(node, to: value.location)
                    })
            }
        }
        .sheet(item: $selectedNode) { node in
            NoteDetailView(noteID: node.noteID)
        }
    }

    func updateNodePosition(_ node: GraphNode, to position: CGPoint) {
        // Update node, trigger force-directed re-layout
        forceLayout.updatePosition(node, to: position)
    }
}

struct GraphNode: Identifiable {
    let id: UUID
    let noteID: UUID
    var position: CGPoint
    let color: Color
}

struct GraphEdge: Identifiable {
    let id = UUID()
    let from: GraphNode
    let to: GraphNode
}
```

**Force-Directed Layout:**
- Use **D3-force** algorithm (Swift port)
- Repulsion between nodes (Coulomb's law)
- Attraction along edges (Hooke's law)
- Iterate until equilibrium

**Success Criteria:**
- ✅ Graph renders for 1,000+ notes in <5s
- ✅ Smooth 60 FPS panning/zooming
- ✅ Click → show note detail
- ✅ Search highlights nodes

**Complexity:** **L** (Large) — Force layout + interactive UI is complex

---

#### 9.3 Project/Workspace Auto-Detection
**Requirements:**
- Group notes by "project" (e.g., all notes from Xcode on project X)
- Detect via:
  - Window title (e.g., "AppState.swift — ScreenMind")
  - Folder path (if available via Accessibility API)
  - Semantic clustering (notes about same topic)
- Label notes with `project` field

**Technical Approach:**
```swift
actor ProjectDetectionActor {
    func detectProject(for note: NoteModel) async -> String? {
        // Heuristic 1: Window title contains project name
        if let windowTitle = note.windowTitle, windowTitle.contains("—") {
            let parts = windowTitle.split(separator: "—")
            if parts.count > 1 {
                return String(parts[1].trimmingCharacters(in: .whitespaces))
            }
        }

        // Heuristic 2: Semantic clustering (notes about same topic)
        let similarNotes = try await semanticSearch.search(query: note.title, limit: 5)
        let projectNames = similarNotes.compactMap(\.project)
        if let mostCommon = projectNames.mostCommon() {
            return mostCommon
        }

        return nil
    }
}
```

**UI:**
```swift
// Notes Browser > Sidebar: Projects
Section("Projects") {
    ForEach(projects) { project in
        NavigationLink(project.name) {
            NotesListView(filter: .project(project.name))
        }
    }
}
```

**Success Criteria:**
- ✅ 60%+ notes auto-tagged with project
- ✅ User can manually override project
- ✅ Project-based filtering works

**Complexity:** **M** (Medium)

---

#### 9.4 Topic Clustering & Trend Analysis
**Requirements:**
- Auto-detect topics (e.g., "Swift concurrency", "API design", "Team meetings")
- Use **LDA** (Latent Dirichlet Allocation) or **BERTopic** for topic modeling
- Show trending topics (most notes this week)
- Timeline: "This week you focused on: Swift actors (12 notes), API security (8 notes)"

**Technical Approach:**
```swift
actor TopicModelingActor {
    func extractTopics(from notes: [NoteModel], topicCount: Int = 10) async throws -> [Topic] {
        // 1. Preprocess text (remove stopwords, lemmatize)
        let documents = notes.map { preprocessText($0.title + " " + $0.summary) }

        // 2. Run LDA (via Python script or Swift-NLP)
        let topics = try await LDA.train(documents, topicCount: topicCount)

        return topics
    }

    func trendingTopics(timeRange: DateInterval) async throws -> [Topic] {
        let notes = try await storageActor.fetchNotes(from: timeRange.start, to: timeRange.end)
        let topics = try await extractTopics(from: notes)
        return topics.sorted { $0.noteCount > $1.noteCount }
    }
}

struct Topic: Identifiable {
    let id = UUID()
    let name: String
    let keywords: [String]
    let noteCount: Int
}
```

**UI:**
```swift
// Timeline > Insights tab
Section("Trending Topics This Week") {
    ForEach(trendingTopics) { topic in
        HStack {
            Text(topic.name)
                .font(.headline)
            Spacer()
            Text("\(topic.noteCount) notes")
                .foregroundColor(.secondary)
        }
        .onTapGesture {
            // Filter timeline to notes in this topic
        }
    }
}
```

**Success Criteria:**
- ✅ 10+ topics extracted per 100 notes
- ✅ Topic names are human-readable (not "Topic 1")
- ✅ Trending topics update daily
- ✅ User can click topic → filter notes

**Complexity:** **L** (Large) — Topic modeling is complex, Python dependency

---

#### 9.5 "This Week in Review" Auto-Generated Summaries
**Requirements:**
- Weekly digest (every Sunday evening)
- AI-generated summary: "This week you captured 42 notes. You focused on Swift concurrency (12 notes), met with the team 3 times, and read 8 articles about API design."
- Includes: top categories, top apps, top topics, notable notes
- Exported to Obsidian (weekly note)

**Technical Approach:**
```swift
actor WeeklySummaryGenerator {
    func generateWeeklySummary() async throws -> String {
        let startOfWeek = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let notes = try await storageActor.fetchNotes(from: startOfWeek, to: Date())

        // Stats
        let totalNotes = notes.count
        let categoryBreakdown = Dictionary(grouping: notes, by: \.category)
        let appBreakdown = Dictionary(grouping: notes, by: \.appName)

        // Topic extraction
        let topics = try await topicActor.extractTopics(from: notes, topicCount: 5)

        // Notable notes (high confidence + long details)
        let notableNotes = notes
            .filter { $0.confidence > 0.9 && $0.details.count > 500 }
            .sorted { $0.confidence > $1.confidence }
            .prefix(5)

        // Generate AI summary
        let prompt = """
        Generate a weekly summary based on these stats:

        Total notes: \(totalNotes)

        Top categories:
        \(categoryBreakdown.map { "\($0.key): \($0.value.count)" }.joined(separator: "\n"))

        Top apps:
        \(appBreakdown.map { "\($0.key): \($0.value.count)" }.joined(separator: "\n"))

        Top topics:
        \(topics.map { "\($0.name): \($0.noteCount) notes" }.joined(separator: "\n"))

        Notable notes:
        \(notableNotes.map { "- \($0.title)" }.joined(separator: "\n"))

        Write a friendly 2-paragraph summary.
        """

        let summary = try await aiProvider.complete(prompt: prompt)
        return summary
    }
}
```

**Trigger:**
```swift
// Scheduled task (every Sunday at 8pm)
Timer.scheduledTimer(withTimeInterval: 24 * 3600, repeats: true) { _ in
    Task {
        let summary = try await weeklySummary.generateWeeklySummary()
        try await obsidianExporter.writeWeeklySummary(summary)
        NotificationManager.shared.notify(title: "Weekly Summary Ready", body: summary)
    }
}
```

**Success Criteria:**
- ✅ Weekly summary generated every Sunday
- ✅ Summary includes stats + AI narrative
- ✅ Exported to Obsidian (weekly note)
- ✅ User notification sent

**Complexity:** **S** (Small) — Reuses existing components

---

### Phase 9 Architecture Changes

**New Module: KnowledgeGraph**
```
KnowledgeGraph/
├── Actors/
│   ├── LinkDiscoveryActor.swift
│   ├── ProjectDetectionActor.swift
│   ├── TopicModelingActor.swift
│   └── WeeklySummaryGenerator.swift
├── Models/
│   ├── GraphNode.swift
│   ├── GraphEdge.swift
│   ├── Project.swift
│   └── Topic.swift
├── Database/
│   └── LinkDatabase.swift
├── Layout/
│   └── ForceDirectedLayout.swift
└── Views/
    └── KnowledgeGraphView.swift
```

**Settings UI:**
```swift
// Settings > Knowledge Graph
Toggle("Auto-Link Related Notes", isOn: $settings.autoLinkEnabled)
Slider("Link Similarity Threshold", value: $settings.linkThreshold, in: 0.5...0.9)
Toggle("Project Auto-Detection", isOn: $settings.projectDetectionEnabled)
Toggle("Weekly Summaries", isOn: $settings.weeklySummaryEnabled)
```

### Phase 9 Success Metrics

| Metric | Target |
|--------|--------|
| Notes with links | >80% |
| Knowledge graph usage | >20% of users explore graph weekly |
| Project detection accuracy | >60% auto-tagged correctly |
| Topic extraction quality | >70% topics are meaningful |
| Weekly summary engagement | >50% users read summaries |

### Phase 9 Risks

| Risk | Mitigation |
|------|------------|
| **Graph performance (1000+ nodes)** | Use WebGL or Metal for rendering, lazy-load nodes |
| **Link explosion (too many links)** | Cap at top 5 links per note, hide low-similarity |
| **Topic modeling complexity** | Start with simple LDA, defer BERTopic |
| **Weekly summary quality** | Iterate on prompt, let users customize |

**Estimated Timeline:** 6-8 weeks
**Estimated Complexity:** **L** (Large)

---

## Phase 10: Plugin System & Developer Platform

**Goal:** Build a plugin ecosystem (like Screenpipe's "Pipes") to let developers extend ScreenMind — turning it into a platform, not just an app.

**Why it matters:** Screenpipe's killer feature is the Pipe Store. We need plugin extensibility + monetization for community growth.

### Features

#### 10.1 Plugin Architecture (JavaScript/TypeScript)
**Requirements:**
- Plugins written in JS/TS (via **JavaScriptCore** or **Bun**)
- Sandboxed execution (no file system access except plugin folder)
- Plugin manifest (`plugin.json`)
- Lifecycle hooks: `onNoteCreated`, `onNoteSaved`, `onAppStartup`, `onTimer`

**Technical Approach:**
```swift
import JavaScriptCore

actor PluginEngine {
    private var loadedPlugins: [Plugin] = []
    private let jsContext = JSContext()!

    func loadPlugin(from path: String) throws {
        // 1. Read plugin.json
        let manifestURL = URL(fileURLWithPath: path).appendingPathComponent("plugin.json")
        let manifestData = try Data(contentsOf: manifestURL)
        let manifest = try JSONDecoder().decode(PluginManifest.self, from: manifestData)

        // 2. Load main.js
        let scriptURL = URL(fileURLWithPath: path).appendingPathComponent(manifest.main)
        let script = try String(contentsOf: scriptURL)

        // 3. Execute in JSContext
        jsContext.evaluateScript(script)

        // 4. Register hooks
        let plugin = Plugin(manifest: manifest, context: jsContext)
        loadedPlugins.append(plugin)
    }

    func trigger(event: PluginEvent, data: [String: Any]) async {
        for plugin in loadedPlugins {
            guard plugin.manifest.hooks.contains(event.name) else { continue }

            // Call plugin's event handler
            let handler = plugin.context.objectForKeyedSubscript(event.name)
            handler?.call(withArguments: [data])
        }
    }
}

struct PluginManifest: Codable {
    let name: String
    let version: String
    let author: String
    let description: String
    let main: String // "main.js"
    let hooks: [String] // ["onNoteCreated", "onTimer"]
    let permissions: [String] // ["network", "storage"]
}

enum PluginEvent {
    case noteCreated
    case noteSaved
    case appStartup
    case timer

    var name: String {
        switch self {
        case .noteCreated: return "onNoteCreated"
        case .noteSaved: return "onNoteSaved"
        case .appStartup: return "onAppStartup"
        case .timer: return "onTimer"
        }
    }
}
```

**Plugin Example: Notion Sync**
```javascript
// plugin.json
{
  "name": "Notion Sync",
  "version": "1.0.0",
  "author": "community",
  "description": "Sync notes to Notion database",
  "main": "main.js",
  "hooks": ["onNoteCreated"],
  "permissions": ["network"]
}

// main.js
function onNoteCreated(note) {
  const notionToken = getEnv("NOTION_API_KEY");
  const databaseID = getEnv("NOTION_DATABASE_ID");

  fetch("https://api.notion.com/v1/pages", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${notionToken}`,
      "Content-Type": "application/json",
      "Notion-Version": "2022-06-28"
    },
    body: JSON.stringify({
      parent: { database_id: databaseID },
      properties: {
        Name: { title: [{ text: { content: note.title } }] },
        Summary: { rich_text: [{ text: { content: note.summary } }] },
        Category: { select: { name: note.category } }
      }
    })
  });
}
```

**Success Criteria:**
- ✅ Plugins load and execute in <100ms
- ✅ Sandboxing prevents file system access
- ✅ `onNoteCreated` hook fires reliably
- ✅ Example plugins: Notion, Linear, Slack

**Complexity:** **L** (Large) — Sandboxing + lifecycle hooks are complex

---

#### 10.2 Plugin Store (GitHub-Based Registry)
**Requirements:**
- GitHub repo: `screenmind-plugins` (community-maintained)
- Plugin metadata in `registry.json`
- One-click install from Settings > Plugins
- Version management + auto-updates

**Technical Approach:**
```swift
actor PluginStoreClient {
    private let registryURL = "https://raw.githubusercontent.com/screenmind/plugins/main/registry.json"

    func fetchAvailablePlugins() async throws -> [PluginListingModel] {
        let (data, _) = try await URLSession.shared.data(from: URL(string: registryURL)!)
        let registry = try JSONDecoder().decode(PluginRegistry.self, from: data)
        return registry.plugins
    }

    func installPlugin(_ plugin: PluginListingModel) async throws {
        // 1. Download plugin zip
        let zipURL = URL(string: plugin.downloadURL)!
        let (data, _) = try await URLSession.shared.data(from: zipURL)

        // 2. Unzip to ~/Library/Application Support/ScreenMind/Plugins/
        let pluginDir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ScreenMind/Plugins/\(plugin.id)")

        try FileManager.default.createDirectory(at: pluginDir, withIntermediateDirectories: true)
        try Zip.unzip(data, to: pluginDir)

        // 3. Load plugin
        try await pluginEngine.loadPlugin(from: pluginDir.path)
    }
}

struct PluginRegistry: Codable {
    let plugins: [PluginListingModel]
}

struct PluginListingModel: Codable, Identifiable {
    let id: String
    let name: String
    let author: String
    let description: String
    let version: String
    let downloadURL: String
    let homepage: String
}
```

**UI:**
```swift
// Settings > Plugins > Store
List(availablePlugins) { plugin in
    HStack {
        VStack(alignment: .leading) {
            Text(plugin.name).font(.headline)
            Text(plugin.description).font(.caption)
            Text("by \(plugin.author)").foregroundColor(.secondary)
        }
        Spacer()
        Button("Install") {
            Task { try await pluginStore.installPlugin(plugin) }
        }
    }
}
```

**Success Criteria:**
- ✅ Registry updated via GitHub (no app update needed)
- ✅ One-click install works
- ✅ Plugin versioning + auto-updates
- ✅ Community contributors submit via PR

**Complexity:** **M** (Medium)

---

#### 10.3 MCP Server (Model Context Protocol)
**Requirements:**
- Implement MCP server for Claude Desktop / Cursor integration
- Expose ScreenMind notes as "tools" Claude can query
- Example: Claude can ask "What did I work on yesterday?" → queries ScreenMind API

**Technical Approach:**
```swift
// MCP server runs alongside API server (port 9877)
actor MCPServer {
    func start() async throws {
        let listener = try NWListener(using: .tcp, on: 9877)
        listener.newConnectionHandler = { connection in
            Task { await self.handleMCPRequest(connection) }
        }
        listener.start(queue: .global())
    }

    func handleMCPRequest(_ connection: NWConnection) async {
        // MCP protocol: JSON-RPC over HTTP
        // Example request:
        // {"jsonrpc": "2.0", "method": "tools/list", "id": 1}

        // Response:
        // {"jsonrpc": "2.0", "result": [
        //   {"name": "search_notes", "description": "Search ScreenMind notes", "parameters": {...}}
        // ], "id": 1}
    }
}
```

**MCP Tools Exposed:**
- `search_notes(query: string)` → Returns matching notes
- `get_note(id: string)` → Returns full note details
- `list_recent_notes(limit: int)` → Returns recent notes
- `get_today_summary()` → Returns today's note summary

**Claude Desktop Integration:**
```json
// ~/.config/claude-desktop/config.json
{
  "mcpServers": {
    "screenmind": {
      "url": "http://127.0.0.1:9877",
      "tools": ["search_notes", "get_note", "list_recent_notes", "get_today_summary"]
    }
  }
}
```

**Success Criteria:**
- ✅ MCP server responds to tool calls
- ✅ Claude Desktop can query ScreenMind notes
- ✅ Cursor can use ScreenMind as context

**Complexity:** **M** (Medium) — MCP protocol is new but simple

---

#### 10.4 macOS Shortcuts Integration
**Requirements:**
- Expose ScreenMind actions to macOS Shortcuts app
- Actions: "Search notes", "Get recent notes", "Capture now"
- Users can build workflows (e.g., "Every morning, send yesterday's notes to Slack")

**Technical Approach:**
```swift
import Intents

// Define Intents
class SearchNotesIntent: INIntent {
    @NSManaged var query: String?
}

class SearchNotesIntentHandler: NSObject, SearchNotesIntentHandling {
    func handle(intent: SearchNotesIntent, completion: @escaping (SearchNotesIntentResponse) -> Void) {
        guard let query = intent.query else {
            completion(SearchNotesIntentResponse(code: .failure, userActivity: nil))
            return
        }

        Task {
            let notes = try await storageActor.searchNotes(query: query)
            let response = SearchNotesIntentResponse(code: .success, userActivity: nil)
            response.notes = notes.map { $0.title }
            completion(response)
        }
    }
}

// Intents.intentdefinition (Xcode)
// Define 3 intents: SearchNotes, GetRecentNotes, CaptureNow
```

**Shortcuts Examples:**
1. **Morning Briefing:** "Get yesterday's notes → Speak summary"
2. **Slack Digest:** "Get today's notes → Filter by category: meetings → Send to Slack webhook"
3. **Quick Capture:** "Capture now → Add tag: #idea"

**Success Criteria:**
- ✅ 3 intents available in Shortcuts app
- ✅ Example shortcuts shared in docs
- ✅ Community creates custom workflows

**Complexity:** **S** (Small) — Intents API is well-documented

---

#### 10.5 Example Plugins (Community Seed)
**Requirements:**
- Ship 5 official plugins to seed the ecosystem
- Open-source, well-documented
- Cover common use cases

**Official Plugins:**
1. **Notion Sync** — Export notes to Notion database
2. **Linear Sync** — Create Linear issues from action items
3. **Slack Digest** — Send daily summary to Slack channel
4. **Obsidian Enhancer** — Add custom frontmatter, auto-link [[notes]]
5. **Export to PDF** — Generate weekly PDF reports

**Success Criteria:**
- ✅ 5 plugins published to registry
- ✅ Each plugin has README + example config
- ✅ Community submits 5+ plugins in first 3 months

**Complexity:** **M** (Medium) — Plugin development + docs

---

### Phase 10 Architecture Changes

**New Module: PluginSystem**
```
PluginSystem/
├── Engine/
│   ├── PluginEngine.swift
│   ├── JSContextManager.swift
│   └── PluginSandbox.swift
├── Store/
│   ├── PluginStoreClient.swift
│   └── PluginInstaller.swift
├── MCP/
│   └── MCPServer.swift
├── Shortcuts/
│   ├── SearchNotesIntent.swift
│   ├── GetRecentNotesIntent.swift
│   └── CaptureNowIntent.swift
├── Models/
│   ├── PluginManifest.swift
│   ├── PluginEvent.swift
│   └── PluginListingModel.swift
└── Views/
    ├── PluginStoreView.swift
    └── InstalledPluginsView.swift
```

**Settings UI:**
```swift
// Settings > Plugins
TabView {
    InstalledPluginsView()
        .tabItem { Label("Installed", systemImage: "list.bullet") }

    PluginStoreView()
        .tabItem { Label("Store", systemImage: "square.grid.2x2") }
}
```

### Phase 10 Success Metrics

| Metric | Target |
|--------|--------|
| Plugins available in store | 15+ in first 6 months |
| Plugin installs | 500+ total installs |
| MCP server usage | >10% of users enable |
| Shortcuts integration usage | >20% of users create workflows |
| Community plugins submitted | 5+ in first 3 months |

### Phase 10 Risks

| Risk | Mitigation |
|------|------------|
| **Plugin security vulnerabilities** | Code review all store plugins, sandboxing |
| **JavaScriptCore performance** | Profile and optimize, consider Bun if slow |
| **Plugin API churn** | Version plugin API, maintain backward compat |
| **Low community adoption** | Seed with 5 official plugins, incentivize creators |

**Estimated Timeline:** 8-10 weeks
**Estimated Complexity:** **XL** (Very Large)

---

## Phase 11: Cross-Platform Foundation

**Goal:** Port ScreenMind to Windows and Linux, making it the only truly cross-platform open-source screen memory tool (vs Screenpipe's Electron wrapper).

**Why it matters:** 70% of developers use Windows/Linux. Cross-platform unlocks enterprise adoption.

### Strategy

**Shared Core (Rust or Swift) + Native UIs**
- Extract core engine (capture, OCR, AI, storage) into standalone library
- Swift core for macOS (existing)
- Rust core for Windows/Linux (cross-compile)
- Native UIs: SwiftUI (macOS), WPF or Avalonia (Windows), GTK or Qt (Linux)

**Why Rust for cross-platform:**
- Mature ecosystem (tokio, serde, sqlx)
- No GC (vs Swift on Linux)
- Better Windows support than Swift
- Cross-compile from macOS to Windows/Linux

### Features

#### 11.1 Core Engine Extraction (Rust)
**Requirements:**
- Rewrite core pipeline in Rust
- Shared database format (SQLite with migrations)
- API compatibility (SwiftData models → SQLite schema)

**Technical Approach:**
```rust
// ScreenMindCore (Rust library)
pub struct PipelineCoordinator {
    capture: Box<dyn CaptureProvider>,
    ocr: Box<dyn OCRProvider>,
    ai: Box<dyn AIProvider>,
    storage: StorageActor,
}

impl PipelineCoordinator {
    pub async fn start(&mut self) -> Result<()> {
        let mut frames = self.capture.stream().await?;

        while let Some(frame) = frames.next().await {
            // Same pipeline stages as Swift version
            let significant = self.detect_change(&frame)?;
            let text = self.ocr.recognize(&significant)?;
            let note = self.ai.generate(&text)?;
            self.storage.save(&note)?;
        }

        Ok(())
    }
}

// Traits for platform abstraction
pub trait CaptureProvider: Send + Sync {
    async fn stream(&self) -> Result<FrameStream>;
}

pub trait OCRProvider: Send + Sync {
    fn recognize(&self, frame: &Frame) -> Result<String>;
}
```

**Shared Database Schema:**
```sql
-- SQLite migrations (shared across platforms)
CREATE TABLE notes (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    summary TEXT NOT NULL,
    details TEXT NOT NULL,
    category TEXT NOT NULL,
    tags TEXT NOT NULL, -- JSON array
    confidence REAL NOT NULL,
    app_name TEXT NOT NULL,
    window_title TEXT,
    created_at INTEGER NOT NULL,
    obsidian_links TEXT, -- JSON array
    redaction_count INTEGER DEFAULT 0
);

-- Same schema as SwiftData models
```

**Success Criteria:**
- ✅ Rust core compiles on macOS, Windows, Linux
- ✅ Pipeline parity with Swift version (9 stages)
- ✅ Database format compatible (SwiftData → SQLite)

**Complexity:** **XL** (Very Large) — Full rewrite

---

#### 11.2 Windows Support
**Requirements:**
- Screen capture via **Windows.Graphics.Capture** API (UWP)
- OCR via **Windows.Media.Ocr** (on-device)
- Native WPF or Avalonia UI
- Installer: MSI or MSIX

**Technical Approach:**
```rust
// Windows capture provider
use windows::Graphics::Capture::*;

pub struct WindowsCaptureProvider {
    item: GraphicsCaptureItem,
    frame_pool: Direct3D11CaptureFramePool,
}

impl CaptureProvider for WindowsCaptureProvider {
    async fn stream(&self) -> Result<FrameStream> {
        let session = self.frame_pool.create_capture_session(&self.item)?;
        session.start_capture()?;

        // Stream frames via channel
        Ok(FrameStream::new())
    }
}
```

**OCR:**
```rust
use windows::Media::Ocr::*;

pub struct WindowsOCRProvider {
    engine: OcrEngine,
}

impl OCRProvider for WindowsOCRProvider {
    fn recognize(&self, frame: &Frame) -> Result<String> {
        let bitmap = frame.to_softwarebitmap()?;
        let result = self.engine.recognize_async(&bitmap)?.get()?;
        Ok(result.text()?.to_string())
    }
}
```

**UI: Avalonia (cross-platform .NET)**
```xml
<Window xmlns="https://github.com/avaloniaui">
  <DockPanel>
    <Menu DockPanel.Dock="Top">
      <MenuItem Header="ScreenMind">
        <MenuItem Header="Start Monitoring" Command="{Binding StartCommand}" />
        <MenuItem Header="Stop Monitoring" Command="{Binding StopCommand}" />
      </MenuItem>
    </Menu>
    <Grid>
      <ListBox Items="{Binding Notes}" />
    </Grid>
  </DockPanel>
</Window>
```

**Success Criteria:**
- ✅ Screen capture works on Windows 10/11
- ✅ OCR works offline (Windows.Media.Ocr)
- ✅ UI matches macOS feature parity

**Complexity:** **XL** (Very Large)

---

#### 11.3 Linux Support
**Requirements:**
- Screen capture via **X11** (xlib) or **Wayland** (wlroots)
- OCR via **Tesseract** (open-source)
- Native GTK or Qt UI
- Installer: .deb, .rpm, AppImage

**Technical Approach:**
```rust
// Linux capture provider (X11)
use x11rb::connection::Connection;
use x11rb::protocol::xproto::*;

pub struct X11CaptureProvider {
    conn: x11rb::xcb_ffi::XCBConnection,
    root: Window,
}

impl CaptureProvider for X11CaptureProvider {
    async fn stream(&self) -> Result<FrameStream> {
        loop {
            let image = self.conn.get_image(
                ImageFormat::Z_PIXMAP,
                self.root,
                0, 0, width, height,
                u32::MAX
            )?.reply()?;

            yield Frame::from_bytes(&image.data);
        }
    }
}
```

**OCR: Tesseract**
```rust
use tesseract::Tesseract;

pub struct TesseractOCRProvider {
    api: Tesseract,
}

impl OCRProvider for TesseractOCRProvider {
    fn recognize(&self, frame: &Frame) -> Result<String> {
        self.api.set_image_from_mem(&frame.bytes)?;
        Ok(self.api.get_utf8_text()?)
    }
}
```

**UI: GTK**
```rust
use gtk::prelude::*;

fn build_ui(app: &gtk::Application) {
    let window = gtk::ApplicationWindow::new(app);
    let list = gtk::ListBox::new();

    // Populate list with notes
    window.set_child(Some(&list));
    window.present();
}
```

**Success Criteria:**
- ✅ X11 and Wayland support
- ✅ Tesseract OCR works
- ✅ GTK UI feature parity

**Complexity:** **XL** (Very Large)

---

#### 11.4 Platform Abstraction Layer
**Requirements:**
- Define traits for platform-specific code
- Compile-time feature flags (macOS, Windows, Linux)
- Consistent API across platforms

**Technical Approach:**
```rust
// Platform abstraction
#[cfg(target_os = "macos")]
mod capture {
    pub use crate::macos::ScreenCaptureKitProvider as CaptureProvider;
}

#[cfg(target_os = "windows")]
mod capture {
    pub use crate::windows::WindowsCaptureProvider as CaptureProvider;
}

#[cfg(target_os = "linux")]
mod capture {
    pub use crate::linux::X11CaptureProvider as CaptureProvider;
}

// Unified API
pub async fn create_pipeline() -> Result<PipelineCoordinator> {
    let capture = Box::new(capture::CaptureProvider::new()?);
    let ocr = Box::new(ocr::OCRProvider::new()?);
    let ai = Box::new(ai::AIProvider::new()?);
    let storage = StorageActor::new()?;

    Ok(PipelineCoordinator::new(capture, ocr, ai, storage))
}
```

**Success Criteria:**
- ✅ Single codebase compiles on all platforms
- ✅ Feature flags isolate platform code
- ✅ CI/CD builds for all platforms

**Complexity:** **M** (Medium)

---

### Phase 11 Architecture Changes

**New Structure:**
```
screenmind/
├── core/                     (Rust crate — cross-platform)
│   ├── src/
│   │   ├── pipeline.rs
│   │   ├── capture/
│   │   │   ├── macos.rs
│   │   │   ├── windows.rs
│   │   │   └── linux.rs
│   │   ├── ocr/
│   │   │   ├── vision.rs    (macOS)
│   │   │   ├── windows.rs
│   │   │   └── tesseract.rs (Linux)
│   │   ├── ai/
│   │   │   └── providers.rs
│   │   └── storage/
│   │       └── sqlite.rs
│   └── Cargo.toml
├── macos/                    (SwiftUI app — calls core)
│   └── Sources/ScreenMindApp/
├── windows/                  (Avalonia app — calls core)
│   └── ScreenMind.Windows/
└── linux/                    (GTK app — calls core)
    └── screenmind-gtk/
```

**FFI Bindings:**
```rust
// Expose Rust core to Swift/C#/C
#[no_mangle]
pub extern "C" fn screenmind_pipeline_start() -> *mut PipelineCoordinator {
    Box::into_raw(Box::new(PipelineCoordinator::new().unwrap()))
}

#[no_mangle]
pub extern "C" fn screenmind_pipeline_stop(ptr: *mut PipelineCoordinator) {
    unsafe { Box::from_raw(ptr); }
}
```

### Phase 11 Success Metrics

| Metric | Target |
|--------|--------|
| Platforms supported | macOS, Windows 10/11, Linux (X11/Wayland) |
| Feature parity | >90% (all core features work on all platforms) |
| Windows installs | 1,000+ in first 3 months |
| Linux installs | 500+ in first 3 months |
| Cross-platform bug rate | <5% (most bugs are platform-agnostic) |

### Phase 11 Risks

| Risk | Mitigation |
|------|------------|
| **Rust rewrite effort** | Incremental migration, maintain Swift version during transition |
| **Windows OCR quality** | Benchmark vs Apple Vision, consider Tesseract fallback |
| **Linux fragmentation (X11 vs Wayland)** | Support both via runtime detection |
| **UI consistency** | Design system (shared colors, fonts, spacing) |

**Estimated Timeline:** 12-16 weeks (longest phase)
**Estimated Complexity:** **XL** (Very Large)

---

## Phase 12: Distribution & Growth

**Goal:** Make ScreenMind easy to discover, install, and update — growing from 200 GitHub stars to 10,000+.

**Why it matters:** Great software dies without distribution. Screenpipe has Homebrew + auto-updates. We need parity.

### Features

#### 12.1 Homebrew Formula
**Requirements:**
- `brew install screenmind` works
- Formula hosted in official Homebrew or custom tap
- Auto-updates via Homebrew

**Technical Approach:**
```ruby
# screenmind.rb (Homebrew formula)
class Screenmind < Formula
  desc "AI-powered screen memory for macOS"
  homepage "https://github.com/screenmind/screenmind"
  url "https://github.com/screenmind/screenmind/releases/download/v2.0.0/screenmind-macos-arm64.tar.gz"
  sha256 "abc123..."
  version "2.0.0"

  depends_on "blackhole-2ch" # Virtual audio driver (optional)

  def install
    bin.install "screenmind"
    bin.install "screenmind-cli"
  end

  def caveats
    <<~EOS
      ScreenMind requires Screen Recording permission.
      Grant in System Settings > Privacy & Security > Screen Recording.

      To enable audio capture, install BlackHole:
        brew install blackhole-2ch
    EOS
  end
end
```

**Distribution:**
- Submit to **homebrew-core** (requires 75+ stars, 30+ forks — almost there!)
- Alternative: Custom tap (`brew tap screenmind/tap && brew install screenmind`)

**Success Criteria:**
- ✅ `brew install screenmind` works
- ✅ Formula auto-updates on new release
- ✅ 50%+ of macOS users install via Homebrew

**Complexity:** **S** (Small)

---

#### 12.2 Sparkle Auto-Updates
**Requirements:**
- Check for updates on launch
- Download + install updates in background
- Delta updates (only changed files)
- User controls: auto-install or prompt

**Technical Approach:**
```swift
import Sparkle

@main
struct ScreenMindApp: App {
    @StateObject private var updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
            Divider()
            Button("Check for Updates...") {
                updaterController.updater.checkForUpdates()
            }
        }
    }
}
```

**Appcast (update feed):**
```xml
<!-- appcast.xml -->
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>ScreenMind Releases</title>
    <item>
      <title>Version 2.0.0</title>
      <pubDate>Sun, 02 Mar 2026 12:00:00 +0000</pubDate>
      <sparkle:version>2.0.0</sparkle:version>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <enclosure
        url="https://github.com/screenmind/screenmind/releases/download/v2.0.0/ScreenMind-2.0.0.dmg"
        sparkle:edSignature="..."
        length="12345678"
        type="application/octet-stream"
      />
    </item>
  </channel>
</rss>
```

**Success Criteria:**
- ✅ Update check on launch (opt-out in Settings)
- ✅ Delta updates reduce download size by 70%
- ✅ 90%+ of users on latest version within 7 days

**Complexity:** **M** (Medium)

---

#### 12.3 Code Signing & Notarization
**Requirements:**
- Sign app with Apple Developer ID
- Notarize with Apple (required for Gatekeeper)
- DMG + ZIP releases

**Technical Approach:**
```bash
#!/bin/bash
# scripts/sign-and-notarize.sh

# 1. Sign app
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Your Name (TEAMID)" \
  --options runtime \
  --entitlements entitlements.plist \
  ScreenMind.app

# 2. Create DMG
hdiutil create -volname ScreenMind -srcfolder ScreenMind.app -ov -format UDZO ScreenMind.dmg

# 3. Sign DMG
codesign --sign "Developer ID Application: Your Name (TEAMID)" ScreenMind.dmg

# 4. Notarize
xcrun notarytool submit ScreenMind.dmg \
  --apple-id "your@email.com" \
  --team-id "TEAMID" \
  --password "app-specific-password" \
  --wait

# 5. Staple notarization ticket
xcrun stapler staple ScreenMind.dmg
```

**Entitlements:**
```xml
<!-- entitlements.plist -->
<dict>
  <key>com.apple.security.cs.allow-jit</key>
  <true/>
  <key>com.apple.security.device.camera</key>
  <true/>
  <key>com.apple.security.device.microphone</key>
  <true/>
  <key>com.apple.security.automation.apple-events</key>
  <true/>
</dict>
```

**Success Criteria:**
- ✅ App launches without Gatekeeper warning
- ✅ Notarization succeeds in <5 minutes
- ✅ Code signature verifies: `codesign --verify --deep ScreenMind.app`

**Complexity:** **M** (Medium)

---

#### 12.4 Crash Reporting (Sentry)
**Requirements:**
- Auto-report crashes (opt-in)
- Privacy-preserving (no PII, no screenshots)
- Track error trends

**Technical Approach:**
```swift
import Sentry

@main
struct ScreenMindApp: App {
    init() {
        // Only if user opted in
        if UserDefaults.standard.bool(forKey: "crashReportingEnabled") {
            SentrySDK.start { options in
                options.dsn = "https://...@sentry.io/..."
                options.tracesSampleRate = 0.1
                options.beforeSend = { event in
                    // Strip PII
                    event.user = nil
                    event.context?.removeValue(forKey: "device")
                    return event
                }
            }
        }
    }
}
```

**Privacy:**
- Opt-in during onboarding
- Settings toggle: "Help improve ScreenMind by sending crash reports"
- Strip all PII (no user names, no file paths, no note content)

**Success Criteria:**
- ✅ <5% crash rate
- ✅ Top 3 crashes fixed within 7 days
- ✅ User opt-in >30%

**Complexity:** **S** (Small)

---

#### 12.5 Analytics (Privacy-Respecting)
**Requirements:**
- Track feature usage (which features are used most)
- No PII, no tracking cookies, no cross-site tracking
- Open-source (Plausible or self-hosted)

**Technical Approach:**
```swift
actor AnalyticsClient {
    private let endpoint = "https://plausible.io/api/event"

    func track(event: String, properties: [String: String] = [:]) async {
        guard UserDefaults.standard.bool(forKey: "analyticsEnabled") else { return }

        let payload: [String: Any] = [
            "name": event,
            "url": "app://screenmind/\(event)",
            "domain": "app.screenmind.io",
            "props": properties
        ]

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        _ = try? await URLSession.shared.data(for: request)
    }
}

// Usage
await analytics.track(event: "note_created", properties: [
    "category": note.category,
    "provider": settings.aiProvider
])
```

**Events to Track:**
- `app_launched`
- `monitoring_started`
- `note_created` (category, provider)
- `search_performed` (semantic vs keyword)
- `plugin_installed`
- `export_triggered` (format)

**Success Criteria:**
- ✅ <1% performance impact
- ✅ Opt-in >50%
- ✅ Data informs roadmap decisions

**Complexity:** **S** (Small)

---

#### 12.6 Product Hunt Launch Strategy
**Requirements:**
- Launch on Product Hunt (goal: Top 5 Product of the Day)
- Pre-launch hype (Twitter, Reddit, HN)
- High-quality assets (video demo, screenshots)

**Pre-Launch (2 weeks before):**
1. **Teaser campaign** (Twitter threads, Reddit r/productivity)
2. **Beta program** (50 beta testers give feedback)
3. **Press kit** (logo assets, screenshots, video demo)
4. **Hunter outreach** (find PH hunter with 10k+ followers)

**Launch Day:**
1. **Submit at 12:01 AM PST** (24-hour window)
2. **Engage comments** (reply within 10 minutes)
3. **Cross-post** (HackerNews, Reddit r/SideProject, Twitter)
4. **Email list** (if exists)

**Post-Launch:**
1. **Thank supporters** (Twitter thread)
2. **Iterate on feedback** (ship fixes within 48h)
3. **Retro** (what worked, what didn't)

**Success Criteria:**
- ✅ Top 5 Product of the Day
- ✅ 500+ upvotes
- ✅ 200+ comments
- ✅ 2,000+ GitHub stars (from 200)

**Complexity:** **M** (Medium) — Not technical, but high-effort

---

#### 12.7 Community Building (Discord/GitHub Discussions)
**Requirements:**
- Discord server or GitHub Discussions (community forum)
- Channels: #support, #plugins, #feature-requests, #showcase
- Weekly office hours (voice chat with maintainers)

**Structure:**
- **Discord:**
  - #announcements (releases, blog posts)
  - #support (user help)
  - #plugins (plugin dev discussion)
  - #feature-requests (upvote with reactions)
  - #showcase (users share workflows)
  - #contributors (PR discussion)

**Engagement:**
- Weekly "Feature Friday" (highlight 1 plugin/workflow)
- Monthly contributor spotlight
- Quarterly roadmap review (live stream)

**Success Criteria:**
- ✅ 500+ Discord members in first 3 months
- ✅ 50+ active contributors (PRs, issues, docs)
- ✅ <24h response time on support questions

**Complexity:** **S** (Small) — Community management is ongoing

---

### Phase 12 Architecture Changes

**New Module: Distribution** (scripts + configs, not code)
```
distribution/
├── homebrew/
│   └── screenmind.rb
├── sparkle/
│   ├── appcast.xml
│   └── generate-appcast.sh
├── codesign/
│   ├── entitlements.plist
│   └── sign-and-notarize.sh
├── analytics/
│   └── AnalyticsClient.swift
└── assets/
    ├── product-hunt/
    │   ├── banner.png
    │   ├── screenshots/
    │   └── demo-video.mp4
    └── press-kit/
```

**CI/CD (GitHub Actions):**
```yaml
# .github/workflows/release.yml
name: Release
on:
  push:
    tags:
      - 'v*'

jobs:
  build-and-release:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build app
        run: swift build -c release
      - name: Sign and notarize
        run: ./scripts/sign-and-notarize.sh
      - name: Create GitHub release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            ScreenMind.dmg
            ScreenMind.zip
      - name: Update Homebrew formula
        run: ./scripts/update-homebrew.sh
```

### Phase 12 Success Metrics

| Metric | Target |
|--------|--------|
| GitHub stars | 10,000+ (from 200) |
| Homebrew installs | 5,000+ in first 3 months |
| Product Hunt ranking | Top 5 Product of the Day |
| Discord members | 500+ |
| Contributors | 50+ (PRs, issues, docs) |
| Update adoption | 90%+ on latest within 7 days |
| Crash rate | <1% |

### Phase 12 Risks

| Risk | Mitigation |
|------|------------|
| **Low Product Hunt traction** | Pre-launch hype, engage hunters, quality assets |
| **Homebrew rejection** (if submitting to core) | Start with custom tap, build momentum |
| **Notarization failures** | Test on clean machine, fix entitlements early |
| **Community toxicity** | Clear Code of Conduct, active moderation |

**Estimated Timeline:** 4-6 weeks
**Estimated Complexity:** **M** (Medium)

---

## Phase 13: Advanced UX

**Goal:** Polish the user experience to match paid tools like Rewind — making ScreenMind feel premium, not just functional.

**Why it matters:** Open-source often feels "DIY." To compete with $20/month tools, UX must be delightful.

### Features

#### 13.1 Note Editing (Inline)
**Requirements:**
- Edit note title, summary, tags after creation
- Markdown editor for details
- Auto-save (debounced)
- Version history (undo/redo)

**Technical Approach:**
```swift
struct NoteEditView: View {
    @State private var note: NoteModel
    @State private var isDirty = false

    var body: some View {
        Form {
            Section("Title") {
                TextField("Title", text: $note.title)
                    .onChange(of: note.title) { isDirty = true }
            }

            Section("Summary") {
                TextEditor(text: $note.summary)
                    .frame(height: 100)
                    .onChange(of: note.summary) { isDirty = true }
            }

            Section("Tags") {
                TagEditor(tags: $note.tags)
                    .onChange(of: note.tags) { isDirty = true }
            }

            Section("Details") {
                MarkdownEditor(text: $note.details)
                    .onChange(of: note.details) { isDirty = true }
            }
        }
        .onChange(of: isDirty) {
            if isDirty {
                Task {
                    try await storageActor.updateNote(note)
                    isDirty = false
                }
            }
        }
    }
}
```

**Version History:**
```sql
-- Add version table
CREATE TABLE note_versions (
    id INTEGER PRIMARY KEY,
    note_id TEXT NOT NULL,
    title TEXT NOT NULL,
    summary TEXT NOT NULL,
    details TEXT NOT NULL,
    edited_at INTEGER NOT NULL,
    FOREIGN KEY (note_id) REFERENCES notes(id)
);
```

**Success Criteria:**
- ✅ Edits save in <500ms
- ✅ Version history preserves last 10 edits
- ✅ Markdown preview works

**Complexity:** **M** (Medium)

---

#### 13.2 Bulk Operations
**Requirements:**
- Multi-select notes (Shift+Click, Cmd+Click)
- Bulk delete, bulk export, bulk re-tag

**Technical Approach:**
```swift
struct NotesBrowserView: View {
    @State private var selectedNotes: Set<UUID> = []

    var body: some View {
        List(selection: $selectedNotes) {
            ForEach(notes) { note in
                NoteCellView(note: note)
            }
        }
        .contextMenu(forSelectionType: UUID.self) { selection in
            Button("Delete \(selection.count) notes") {
                Task { try await storageActor.deleteNotes(ids: Array(selection)) }
            }
            Button("Export \(selection.count) notes") {
                Task { try await exportNotes(ids: Array(selection)) }
            }
            Button("Add tag...") {
                showTagEditor = true
            }
        }
    }
}
```

**Success Criteria:**
- ✅ Multi-select works (keyboard + mouse)
- ✅ Bulk delete confirms before deleting
- ✅ Bulk export saves to folder

**Complexity:** **S** (Small)

---

#### 13.3 Advanced Date Picker (Calendar Widget)
**Requirements:**
- Calendar widget in Timeline (month view)
- Click date → filter notes
- Heatmap: color intensity = note count

**Technical Approach:**
```swift
struct CalendarHeatmapView: View {
    @State private var selectedDate: Date?
    @State private var noteCounts: [Date: Int] = [:]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
            ForEach(daysInMonth, id: \.self) { date in
                Text("\(calendar.component(.day, from: date))")
                    .frame(width: 40, height: 40)
                    .background(heatmapColor(for: date))
                    .cornerRadius(8)
                    .onTapGesture {
                        selectedDate = date
                        filterNotesByDate(date)
                    }
            }
        }
    }

    func heatmapColor(for date: Date) -> Color {
        let count = noteCounts[date] ?? 0
        if count == 0 { return .clear }
        let intensity = min(Double(count) / 20.0, 1.0)
        return Color.blue.opacity(intensity)
    }
}
```

**Success Criteria:**
- ✅ Heatmap shows note density
- ✅ Click date → filter timeline
- ✅ Month navigation works

**Complexity:** **M** (Medium)

---

#### 13.4 macOS Widgets
**Requirements:**
- Today Widget (Notification Center)
- Desktop Widget (macOS 14+)
- Show: recent notes, today's note count, quick search

**Technical Approach:**
```swift
import WidgetKit
import SwiftUI

struct ScreenMindWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ScreenMindWidget", provider: Provider()) { entry in
            ScreenMindWidgetView(entry: entry)
        }
        .configurationDisplayName("ScreenMind")
        .description("Recent notes and stats")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct ScreenMindWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading) {
            Text("Today: \(entry.noteCount) notes")
                .font(.headline)

            ForEach(entry.recentNotes.prefix(3)) { note in
                Text(note.title)
                    .font(.caption)
                    .lineLimit(1)
            }
        }
        .padding()
    }
}
```

**Success Criteria:**
- ✅ Widget updates every 15 minutes
- ✅ Click widget → open ScreenMind
- ✅ Widget shows correct data

**Complexity:** **M** (Medium)

---

#### 13.5 Focus Mode Integration
**Requirements:**
- Respect macOS Focus modes (Do Not Disturb, Work, Personal)
- Pause capture during Focus (opt-in)
- Resume when Focus ends

**Technical Approach:**
```swift
import UserNotifications

actor FocusModeMonitor {
    func observeFocusMode() async {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("com.apple.focus.status.changed"),
            object: nil,
            queue: .main
        ) { notification in
            Task {
                if let focusActive = notification.userInfo?["active"] as? Bool {
                    await self.handleFocusChange(active: focusActive)
                }
            }
        }
    }

    func handleFocusChange(active: Bool) async {
        if active && UserDefaults.standard.bool(forKey: "pauseDuringFocus") {
            await pipelineCoordinator.setPaused(true)
        } else {
            await pipelineCoordinator.setPaused(false)
        }
    }
}
```

**Success Criteria:**
- ✅ Capture pauses during Focus
- ✅ Resumes when Focus ends
- ✅ User can disable in Settings

**Complexity:** **S** (Small)

---

#### 13.6 Customizable Capture Profiles
**Requirements:**
- Multiple capture profiles (Work, Research, Personal)
- Per-profile settings: intervals, excluded apps, AI provider
- Quick switch via menu bar

**Technical Approach:**
```swift
struct CaptureProfile: Codable, Identifiable {
    let id = UUID()
    var name: String
    var activeInterval: TimeInterval
    var idleInterval: TimeInterval
    var excludedApps: Set<String>
    var aiProvider: String
}

actor ProfileManager {
    private var profiles: [CaptureProfile] = []
    private var activeProfile: CaptureProfile

    func switchProfile(_ profile: CaptureProfile) async {
        activeProfile = profile
        // Reconfigure pipeline with new settings
        await pipelineCoordinator.reconfigure(config: profile)
    }
}
```

**UI:**
```swift
// Menu bar > Profiles
Menu("Profile: \(profileManager.activeProfile.name)") {
    ForEach(profiles) { profile in
        Button(profile.name) {
            Task { await profileManager.switchProfile(profile) }
        }
    }
    Divider()
    Button("Manage Profiles...") {
        showProfileEditor = true
    }
}
```

**Success Criteria:**
- ✅ 3 default profiles: Work, Research, Personal
- ✅ User can create custom profiles
- ✅ Profile switch takes <1s

**Complexity:** **M** (Medium)

---

#### 13.7 Dark/Light/Auto Theme + Custom Accent Colors
**Requirements:**
- System theme (auto), dark, light
- Custom accent colors (10 presets + color picker)
- Theme applies to all windows

**Technical Approach:**
```swift
enum AppTheme: String, CaseIterable {
    case system, light, dark
}

@AppStorage("appTheme") var appTheme: AppTheme = .system
@AppStorage("accentColor") var accentColor: String = "blue"

var body: some Scene {
    WindowGroup {
        ContentView()
            .preferredColorScheme(colorScheme(for: appTheme))
            .accentColor(Color(accentColor))
    }
}

func colorScheme(for theme: AppTheme) -> ColorScheme? {
    switch theme {
    case .system: return nil
    case .light: return .light
    case .dark: return .dark
    }
}
```

**UI:**
```swift
// Settings > Appearance
Picker("Theme", selection: $appTheme) {
    Text("System").tag(AppTheme.system)
    Text("Light").tag(AppTheme.light)
    Text("Dark").tag(AppTheme.dark)
}

ColorPicker("Accent Color", selection: $accentColor)
```

**Success Criteria:**
- ✅ Theme applies instantly
- ✅ Accent color persists
- ✅ All views respect theme

**Complexity:** **S** (Small)

---

### Phase 13 Architecture Changes

**New Module: AdvancedUI** (within ScreenMindApp)
```
ScreenMindApp/Views/
├── Editing/
│   ├── NoteEditView.swift
│   ├── MarkdownEditor.swift
│   └── TagEditor.swift
├── Calendar/
│   └── CalendarHeatmapView.swift
├── Widgets/
│   └── ScreenMindWidget.swift
└── Profiles/
    ├── ProfileManager.swift
    └── ProfileEditorView.swift
```

**Settings UI:**
```swift
// Settings > Advanced
Section("Editing") {
    Toggle("Enable Note Editing", isOn: $settings.noteEditingEnabled)
    Toggle("Version History", isOn: $settings.versionHistoryEnabled)
}

Section("Profiles") {
    NavigationLink("Manage Profiles") {
        ProfileEditorView()
    }
}

Section("Appearance") {
    Picker("Theme", selection: $appTheme) { ... }
    ColorPicker("Accent Color", selection: $accentColor)
}
```

### Phase 13 Success Metrics

| Metric | Target |
|--------|--------|
| Note editing usage | >40% of users edit at least 1 note |
| Bulk operations usage | >20% of users perform bulk actions |
| Calendar widget usage | >30% of users click calendar dates |
| macOS widget adoption | >15% of users enable widget |
| Focus mode integration usage | >25% of users enable |
| Custom profiles usage | >20% of users create profiles |

### Phase 13 Risks

| Risk | Mitigation |
|------|------------|
| **Feature bloat (too many settings)** | Progressive disclosure, sane defaults |
| **Widget performance** | Limit updates to 15-min intervals |
| **Theme bugs (dark mode inconsistencies)** | Test all views in both themes |

**Estimated Timeline:** 4-6 weeks
**Estimated Complexity:** **M** (Medium)

---

## Phase 14: Frontier Features

**Goal:** Explore cutting-edge features that differentiate ScreenMind from all competitors — making it the most advanced screen memory tool.

**Why it matters:** These are "wow" features that generate buzz, demos, and press coverage.

### Features

#### 14.1 Browser Extension (Chrome/Firefox/Arc)
**Requirements:**
- Capture URL + page title + selected text
- Send to ScreenMind via localhost API
- Works with all Chromium browsers + Firefox

**Technical Approach:**
```javascript
// manifest.json
{
  "manifest_version": 3,
  "name": "ScreenMind Connector",
  "version": "1.0",
  "permissions": ["activeTab", "storage"],
  "background": {
    "service_worker": "background.js"
  },
  "content_scripts": [{
    "matches": ["<all_urls>"],
    "js": ["content.js"]
  }]
}

// content.js
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === "captureContext") {
    const context = {
      url: window.location.href,
      title: document.title,
      selectedText: window.getSelection().toString()
    };

    // Send to ScreenMind API
    fetch("http://127.0.0.1:9876/api/capture", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(context)
    });

    sendResponse({ success: true });
  }
});
```

**ScreenMind API Endpoint:**
```swift
// New endpoint: POST /api/capture
case "/api/capture":
    guard let body = request.body,
          let context = try? JSONDecoder().decode(BrowserContext.self, from: body) else {
        return APIResponse(status: 400, body: ["error": "Invalid body"])
    }

    // Save as note
    let note = NoteModel(
        title: context.title,
        summary: context.selectedText ?? "Browser capture",
        details: "URL: \(context.url)",
        category: "reading",
        tags: ["browser", "web"],
        confidence: 1.0,
        appName: "Browser"
    )
    try await storageActor.saveNote(note)

    return APIResponse(status: 200, body: ["success": true])

struct BrowserContext: Codable {
    let url: String
    let title: String
    let selectedText: String?
}
```

**Success Criteria:**
- ✅ Extension works on Chrome, Firefox, Arc, Brave
- ✅ Context captured in <500ms
- ✅ Note appears in ScreenMind instantly

**Complexity:** **M** (Medium)

---

#### 14.2 iCloud Sync (Multi-Mac)
**Requirements:**
- Sync notes across multiple Macs
- Use **CloudKit** (Apple's iCloud API)
- Conflict resolution (last-write-wins)

**Technical Approach:**
```swift
import CloudKit

actor CloudSyncActor {
    private let container = CKContainer(identifier: "iCloud.com.screenmind")
    private let database: CKDatabase

    init() {
        self.database = container.privateCloudDatabase
    }

    func syncNotes() async throws {
        // 1. Fetch remote changes
        let query = CKQuery(recordType: "Note", predicate: NSPredicate(value: true))
        let records = try await database.records(matching: query)

        // 2. Convert to NoteModel
        let remoteNotes = records.matchResults.compactMap { try? $0.1.get() }.map { record in
            NoteModel(from: record)
        }

        // 3. Merge with local notes (conflict resolution)
        for remoteNote in remoteNotes {
            if let localNote = try await storageActor.fetchNote(id: remoteNote.id) {
                // Conflict: use most recent
                if remoteNote.createdAt > localNote.createdAt {
                    try await storageActor.updateNote(remoteNote)
                }
            } else {
                // New note from remote
                try await storageActor.saveNote(remoteNote)
            }
        }

        // 4. Push local changes to iCloud
        let localNotes = try await storageActor.fetchAllNotes()
        for note in localNotes where !note.syncedToCloud {
            let record = CKRecord(recordType: "Note", recordID: CKRecord.ID(recordName: note.id.uuidString))
            record["title"] = note.title as CKRecordValue
            record["summary"] = note.summary as CKRecordValue
            record["details"] = note.details as CKRecordValue
            record["category"] = note.category as CKRecordValue
            record["createdAt"] = note.createdAt as CKRecordValue

            try await database.save(record)
            note.syncedToCloud = true
            try await storageActor.updateNote(note)
        }
    }
}
```

**Success Criteria:**
- ✅ Notes sync between Macs in <10s
- ✅ Conflicts resolved gracefully
- ✅ User can disable sync (Settings > iCloud)

**Complexity:** **L** (Large)

---

#### 14.3 iOS Companion App (Read-Only)
**Requirements:**
- SwiftUI iOS app (iPhone + iPad)
- Read-only: browse, search notes (no capture)
- Sync via iCloud or REST API (over local network)

**Technical Approach:**
```swift
// iOS app (shared SwiftData models)
@main
struct ScreenMindiOSApp: App {
    @StateObject private var syncManager = iCloudSyncManager()

    var body: some Scene {
        WindowGroup {
            NotesListView()
                .task {
                    await syncManager.sync()
                }
        }
    }
}

struct NotesListView: View {
    @Query var notes: [NoteModel]

    var body: some View {
        NavigationStack {
            List(notes) { note in
                NavigationLink(note.title) {
                    NoteDetailView(note: note)
                }
            }
            .navigationTitle("ScreenMind")
        }
    }
}
```

**Success Criteria:**
- ✅ iOS app syncs notes via iCloud
- ✅ Search works (full-text + semantic)
- ✅ Offline mode (cached notes)

**Complexity:** **M** (Medium)

---

#### 14.4 Vision Pro / Spatial Computing Capture
**Requirements:**
- Capture visionOS windows (future-proofing)
- Spatial screenshots (3D + depth)
- AR annotations (place notes in physical space)

**Technical Approach (Speculative):**
```swift
// visionOS capture
import RealityKit
import ARKit

actor VisionProCaptureActor {
    func captureWindow(_ window: WindowEntity) async -> CapturedFrame {
        // Capture window content + depth map
        let snapshot = window.snapshot()
        let depthData = window.depthData

        return CapturedFrame(
            image: snapshot,
            depthMap: depthData,
            appName: window.applicationName,
            timestamp: Date()
        )
    }
}
```

**Success Criteria:**
- ✅ Proof-of-concept on visionOS Simulator
- ✅ Depth data preserved
- ✅ AR note placement works

**Complexity:** **XL** (Very Large, speculative)

---

#### 14.5 Real-Time Collaboration (Shared Team Memory)
**Requirements:**
- Share notes with team members
- Real-time sync (like Google Docs)
- Permissions: read-only, read-write
- Use **WebSockets** for live updates

**Technical Approach:**
```swift
import Network

actor CollaborationServer {
    private var clients: [NWConnection] = []

    func broadcast(note: NoteModel) async {
        let json = try? JSONEncoder().encode(note)
        guard let data = json else { return }

        for client in clients {
            client.send(content: data, completion: .contentProcessed { _ in })
        }
    }

    func handleClientConnection(_ connection: NWConnection) async {
        clients.append(connection)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, _, _ in
            // Handle incoming note updates
        }
    }
}
```

**Success Criteria:**
- ✅ Notes sync in <1s
- ✅ Conflict resolution (CRDT or OT)
- ✅ Team of 5 can collaborate

**Complexity:** **XL** (Very Large)

---

#### 14.6 Workflow Automation (If-This-Then-That)
**Requirements:**
- Visual workflow builder
- Triggers: note created, search match, time-based
- Actions: export, webhook, run script, notify
- Example: "If note category = meeting, export to Notion + send Slack message"

**Technical Approach:**
```swift
struct Workflow: Codable {
    let id = UUID()
    let name: String
    let trigger: Trigger
    let actions: [Action]
}

enum Trigger {
    case noteCreated(category: String?)
    case searchMatch(query: String)
    case schedule(cron: String)
}

enum Action {
    case export(format: String, destination: String)
    case webhook(url: String, payload: [String: Any])
    case runScript(path: String)
    case notify(title: String, body: String)
}

actor WorkflowEngine {
    func execute(workflow: Workflow, note: NoteModel) async {
        for action in workflow.actions {
            switch action {
            case .export(let format, let destination):
                try? await exportNote(note, format: format, to: destination)
            case .webhook(let url, let payload):
                try? await sendWebhook(url: url, payload: payload)
            case .runScript(let path):
                try? await runScript(at: path)
            case .notify(let title, let body):
                NotificationManager.shared.notify(title: title, body: body)
            }
        }
    }
}
```

**UI: Visual Workflow Builder**
```swift
struct WorkflowBuilderView: View {
    @State private var workflow = Workflow(name: "New Workflow", trigger: .noteCreated(category: nil), actions: [])

    var body: some View {
        Form {
            Section("Trigger") {
                Picker("When", selection: $workflow.trigger) {
                    Text("Note Created").tag(Trigger.noteCreated(category: nil))
                    Text("Search Match").tag(Trigger.searchMatch(query: ""))
                    Text("Schedule").tag(Trigger.schedule(cron: "0 9 * * *"))
                }
            }

            Section("Actions") {
                ForEach(workflow.actions) { action in
                    ActionRow(action: action)
                }
                Button("Add Action") {
                    workflow.actions.append(.notify(title: "New Note", body: ""))
                }
            }
        }
    }
}
```

**Success Criteria:**
- ✅ 5+ pre-built workflows
- ✅ Visual builder works (drag-and-drop)
- ✅ Community shares workflows

**Complexity:** **XL** (Very Large)

---

### Phase 14 Architecture Changes

**New Module: FrontierFeatures**
```
FrontierFeatures/
├── BrowserExtension/
│   ├── manifest.json
│   ├── content.js
│   └── background.js
├── CloudSync/
│   └── CloudSyncActor.swift
├── iOS/
│   └── ScreenMindiOS/ (separate Xcode project)
├── VisionPro/
│   └── VisionProCaptureActor.swift (speculative)
├── Collaboration/
│   └── CollaborationServer.swift
└── Workflows/
    ├── WorkflowEngine.swift
    └── WorkflowBuilderView.swift
```

### Phase 14 Success Metrics

| Metric | Target |
|--------|--------|
| Browser extension installs | 1,000+ |
| iCloud sync adoption | >30% of users enable |
| iOS app downloads | 5,000+ |
| Vision Pro PoC | Working demo |
| Collaboration beta testers | 50+ teams |
| Workflows created | 500+ |

### Phase 14 Risks

| Risk | Mitigation |
|------|------------|
| **Browser extension privacy concerns** | Open-source, localhost-only, explicit permissions |
| **iCloud sync conflicts** | Robust CRDT or last-write-wins with user override |
| **iOS app scope creep** | Keep read-only, defer capture to v2 |
| **Vision Pro adoption (low user base)** | Treat as R&D, not critical path |
| **Collaboration complexity** | Start with small teams (5-10), defer enterprise |

**Estimated Timeline:** 12-16 weeks
**Estimated Complexity:** **XL** (Very Large)

---

## 5. Technical Architecture Evolution

### Current Architecture (Phases 1-6)

```
ScreenMindApp (SwiftUI)
  ├── PipelineCore (orchestration)
  │     ├── CaptureCore (ScreenCaptureKit)
  │     ├── ChangeDetection (dHash)
  │     ├── OCRProcessing (Vision + redaction + cache)
  │     ├── AIProcessing (multi-provider)
  │     ├── StorageCore (SwiftData + exporters)
  │     └── SystemIntegration (Spotlight, API, shortcuts)
  └── Shared (constants, logging, keychain)
ScreenMindCLI (CLI tool)
```

### Target Architecture (Post-Phase 14)

```
┌─────────────────────────────────────────────────────────────────┐
│                         ScreenMind Platform                      │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      UI Layer (Platform-Specific)                │
├─────────────────────────────────────────────────────────────────┤
│  macOS (SwiftUI)  │  Windows (Avalonia)  │  Linux (GTK)         │
│  iOS (SwiftUI)    │  Browser Extension   │  Vision Pro (visionOS)│
└─────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Plugin System (JS/TS + MCP)                   │
├─────────────────────────────────────────────────────────────────┤
│  Plugin Engine  │  Plugin Store  │  MCP Server  │  Shortcuts    │
└─────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────┐
│                       Core Engine (Rust/Swift)                   │
├─────────────────────────────────────────────────────────────────┤
│  PipelineCore (orchestration)                                    │
│    ├── CaptureCore (screen + audio, multi-display)              │
│    ├── ChangeDetection (perceptual hash)                         │
│    ├── OCRProcessing (Vision/Tesseract + redaction)             │
│    ├── AudioCore (speech-to-text, VAD)                           │
│    ├── AIProcessing (multi-provider, prompts)                    │
│    ├── SemanticSearch (embeddings, RAG, NL queries)             │
│    ├── KnowledgeGraph (links, topics, projects)                  │
│    ├── StorageCore (SwiftData/SQLite + exporters)               │
│    └── SystemIntegration (Spotlight, API, notifications)         │
└─────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────┐
│                      Storage Layer (SQLite)                      │
├─────────────────────────────────────────────────────────────────┤
│  notes  │  screenshots  │  embeddings  │  links  │  workflows   │
└─────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────┐
│                     Integration Layer (APIs)                     │
├─────────────────────────────────────────────────────────────────┤
│  REST API  │  CLI  │  MCP Server  │  CloudKit  │  WebSockets    │
└─────────────────────────────────────────────────────────────────┘
```

### Module Breakdown (Post-Phase 14)

| Module | Lines of Code (Est.) | Complexity | Dependencies |
|--------|---------------------|------------|--------------|
| **CaptureCore** | 1,500 | M | ScreenCaptureKit (macOS), Windows.Graphics.Capture (Win), X11 (Linux) |
| **AudioCore** | 1,200 | M | AVAudioEngine (macOS), Speech Framework, Whisper.cpp |
| **ChangeDetection** | 500 | S | Accelerate, CoreGraphics |
| **OCRProcessing** | 1,000 | M | Vision (macOS), Windows.Media.Ocr (Win), Tesseract (Linux) |
| **AIProcessing** | 1,500 | M | URLSession, JSONEncoder/Decoder |
| **SemanticSearch** | 2,000 | L | MLX (embeddings), SQLite (vector storage), Accelerate (linear algebra) |
| **KnowledgeGraph** | 1,500 | L | Force-directed layout, topic modeling (LDA) |
| **StorageCore** | 2,000 | M | SwiftData (macOS), SQLite (cross-platform), exporters |
| **PluginSystem** | 2,000 | L | JavaScriptCore, MCP protocol, sandboxing |
| **SystemIntegration** | 1,200 | M | Spotlight, Shortcuts, EventKit, CloudKit |
| **ScreenMindApp** (UI) | 3,000 | M | SwiftUI, WidgetKit |
| **FrontierFeatures** | 2,500 | XL | CloudKit, visionOS (speculative), WebSockets |
| **Shared** | 800 | S | Logging, constants, keychain |
| **Total** | **~20,000** | **XL** | — |

### Key Architectural Decisions

#### 1. Cross-Platform Strategy: Rust Core + Native UIs
**Decision:** Rewrite core pipeline in Rust (Phase 11), keep native UIs per platform.

**Rationale:**
- Rust offers better cross-platform support than Swift (especially Windows/Linux)
- Native UIs (SwiftUI, Avalonia, GTK) feel better than Electron
- Single codebase for core logic, platform-specific capture/OCR

**Tradeoff:**
- Upfront rewrite cost (12-16 weeks)
- FFI complexity (Swift ↔ Rust, C# ↔ Rust)

#### 2. Semantic Search: On-Device MLX vs Cloud Embeddings
**Decision:** Use on-device MLX embeddings (Phase 8).

**Rationale:**
- Privacy-first (no data sent to cloud)
- Faster (no network latency)
- Free (no OpenAI embedding API costs)

**Tradeoff:**
- Smaller models (384-dim vs 1536-dim) = slightly lower accuracy
- Requires Apple Silicon for MLX (Intel Macs use fallback)

#### 3. Plugin System: JavaScriptCore vs Native Plugins
**Decision:** JavaScriptCore for JS/TS plugins (Phase 10).

**Rationale:**
- Lower barrier to entry (JS/TS is more popular than Swift/Rust)
- Sandboxing is easier (no arbitrary code execution)
- Faster iteration (no compilation)

**Tradeoff:**
- Performance (JS slower than native)
- Limited API surface (can't access all system APIs)

#### 4. Knowledge Graph: Force-Directed Layout vs Hierarchical
**Decision:** Force-directed layout (D3-force algorithm) for Phase 9.

**Rationale:**
- More visually appealing (organic, exploratory)
- Better for dense graphs (many links)

**Tradeoff:**
- Slower layout computation (O(n²) per iteration)
- Harder to navigate large graphs (>1,000 nodes)

---

## 6. Success Metrics

### Phase-Level Metrics

| Phase | Key Metric | Target | Timeline |
|-------|-----------|--------|----------|
| **Phase 7: Audio** | Audio capture adoption | >40% users enable | 6-8 weeks |
| **Phase 8: Semantic Search** | Semantic search preference | >70% prefer over keyword | 8-10 weeks |
| **Phase 9: Knowledge Graph** | Notes with links | >80% | 6-8 weeks |
| **Phase 10: Plugins** | Plugin store listings | 15+ plugins | 8-10 weeks |
| **Phase 11: Cross-Platform** | Windows/Linux installs | 1,500+ | 12-16 weeks |
| **Phase 12: Distribution** | GitHub stars | 10,000+ | 4-6 weeks |
| **Phase 13: Advanced UX** | Note editing usage | >40% | 4-6 weeks |
| **Phase 14: Frontier** | Browser extension installs | 1,000+ | 12-16 weeks |

### Overall Success Metrics (End of 2027)

| Category | Metric | 2026 Target | 2027 Target |
|----------|--------|------------|------------|
| **Adoption** | Total installs | 10,000 | 50,000 |
| **Engagement** | Daily active users (DAU) | 2,000 | 15,000 |
| **Growth** | GitHub stars | 10,000 | 25,000 |
| **Community** | Contributors (PRs, issues) | 50 | 200 |
| **Ecosystem** | Plugin store listings | 15 | 50 |
| **Revenue** (optional) | Donations/sponsors | $5k/yr | $20k/yr |
| **Platform** | Cross-platform users (Win/Linux) | 30% | 40% |
| **Performance** | Crash rate | <1% | <0.5% |
| **Quality** | NPS (Net Promoter Score) | 40 | 60 |

### Feature-Specific Metrics

| Feature | Metric | Target |
|---------|--------|--------|
| **Audio Capture** | Transcription accuracy | >90% (English) |
| **Meeting Detection** | Detection rate | >80% (calendar events) |
| **Semantic Search** | Top-5 relevance | >80% |
| **AI Chat (RAG)** | User satisfaction | >85% |
| **Knowledge Graph** | Weekly usage | >20% of users |
| **Plugins** | Avg installs per user | 3+ plugins |
| **Cross-Platform** | Windows market share | >25% of total users |
| **Auto-Updates** | Adoption of latest version | >90% within 7 days |

---

## 7. Risk Assessment

### Phase-Level Risks

#### Phase 7: Audio Intelligence

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| **BlackHole setup too complex** | High | Medium | Video tutorial, Homebrew one-liner, fallback to built-in mic |
| **Apple Speech offline limits** | Medium | High | Whisper.cpp fallback (offline, better accuracy) |
| **Speaker diarization accuracy** | Medium | High | Start simple (2 speakers), improve iteratively |
| **Privacy backlash (audio recording)** | High | Low | Prominent settings, audit log, encryption, opt-in by default |

#### Phase 8: Semantic Search & AI Chat

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| **Embedding model size (disk/memory)** | Medium | Medium | Use bge-small (33MB), defer bge-base (109MB) |
| **Vector DB performance (10k+ notes)** | High | Medium | FAISS if SQLite too slow, benchmark early |
| **LLM costs (RAG queries)** | Medium | High | Cache queries, use Ollama for offline |
| **UMAP/clustering complexity** | Low | High | Defer full clustering, start with simple 2D projection |

#### Phase 9: Knowledge Graph & Connections

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| **Graph performance (1000+ nodes)** | High | High | WebGL/Metal rendering, lazy-load nodes, virtual scrolling |
| **Link explosion (too many links)** | Medium | Medium | Cap at top 5 per note, threshold >0.7 similarity |
| **Topic modeling accuracy** | Medium | Medium | Iterate on LDA params, defer BERTopic |
| **Weekly summary quality** | Low | Medium | Prompt engineering, user feedback loop |

#### Phase 10: Plugin System & Developer Platform

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| **Plugin security vulnerabilities** | High | Medium | Code review all store plugins, sandboxing |
| **JavaScriptCore performance** | Medium | Medium | Profile early, Bun fallback if needed |
| **Plugin API churn** | Medium | High | Version plugin API, maintain backward compat for 2+ versions |
| **Low community adoption** | High | High | Seed with 5 official plugins, incentivize creators (featured in store) |

#### Phase 11: Cross-Platform Foundation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| **Rust rewrite scope creep** | High | High | Incremental migration, maintain Swift version during transition |
| **Windows OCR quality vs Apple Vision** | Medium | Medium | Benchmark both, Tesseract fallback |
| **Linux fragmentation (X11 vs Wayland)** | Medium | High | Support both via runtime detection, community testing |
| **UI consistency across platforms** | Medium | Medium | Design system (shared colors, fonts), cross-platform QA |

#### Phase 12: Distribution & Growth

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| **Low Product Hunt traction** | High | Medium | Pre-launch hype (Twitter, Reddit), engage hunters, quality assets |
| **Homebrew rejection (if submitting to core)** | Low | Medium | Start with custom tap, build momentum |
| **Notarization failures** | Medium | Low | Test on clean machine, fix entitlements early |
| **Community toxicity** | Medium | Low | Clear Code of Conduct, active moderation |

#### Phase 13: Advanced UX

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| **Feature bloat (too many settings)** | Medium | High | Progressive disclosure, sane defaults, power user section |
| **Widget performance** | Low | Medium | Limit updates to 15-min intervals, background refresh |
| **Theme bugs (dark mode inconsistencies)** | Low | Medium | Test all views in both themes, automated screenshots |

#### Phase 14: Frontier Features

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| **Browser extension privacy concerns** | High | Medium | Open-source, localhost-only, explicit permissions, no tracking |
| **iCloud sync conflicts** | Medium | High | CRDT or last-write-wins with user override |
| **iOS app scope creep** | Medium | Medium | Keep read-only, defer capture to v2 |
| **Vision Pro low user base** | Low | High | Treat as R&D, not critical path |
| **Collaboration complexity** | High | High | Start with small teams (5-10), defer enterprise features |

### Cross-Cutting Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| **Team burnout (roadmap too aggressive)** | High | Medium | Prioritize phases, cut scope if needed, take breaks |
| **API provider changes (Claude, OpenAI)** | Medium | Medium | Multi-provider strategy reduces lock-in |
| **macOS API changes (ScreenCaptureKit)** | Medium | Low | Monitor WWDC announcements, early beta testing |
| **Competition (Screenpipe adds features)** | Medium | High | Focus on differentiation (Obsidian, privacy, plugins) |
| **Open-source sustainability (no funding)** | High | High | GitHub Sponsors, optional paid plugins, consulting services |

---

## 8. Prioritization Matrix

### Impact vs Effort (Phases 7-14)

```
High Impact
    │
    │   Phase 8          Phase 7         Phase 10
    │   (Semantic)       (Audio)         (Plugins)
    │      ●               ●                ●
    │
    │                                    Phase 12
    │   Phase 9                          (Distribution)
    │   (K-Graph)                           ●
    │      ●
    │                    Phase 13
    │                    (UX)
    │                      ●
    │
    │                                    Phase 14
    │   Phase 11                         (Frontier)
    │   (Cross-Platform)                    ●
    │      ●
    │
Low Impact
    └────────────────────────────────────────────────────────> Effort
        Low                                                High
```

### Recommended Prioritization (2026-2027)

#### Q2 2026: Phase 7 (Audio) + Phase 12 (Distribution)
**Rationale:** Audio is highest user demand. Distribution unlocks growth.
- **Duration:** 10-14 weeks
- **Team Size:** 2-3 developers
- **Risk:** Medium (BlackHole complexity, Product Hunt timing)

#### Q3 2026: Phase 8 (Semantic Search) + Phase 10 (Plugins)
**Rationale:** Semantic search is killer feature. Plugins enable ecosystem.
- **Duration:** 16-20 weeks
- **Team Size:** 3-4 developers
- **Risk:** High (MLX integration, plugin security)

#### Q4 2026: Phase 9 (Knowledge Graph) + Phase 13 (UX)
**Rationale:** Knowledge graph is differentiator. UX polish for premium feel.
- **Duration:** 10-14 weeks
- **Team Size:** 2-3 developers
- **Risk:** Medium (graph performance, feature bloat)

#### Q1 2027: Phase 11 (Cross-Platform)
**Rationale:** Windows/Linux unlocks 70% of market. Biggest effort.
- **Duration:** 12-16 weeks
- **Team Size:** 4-5 developers (Rust + platform experts)
- **Risk:** High (rewrite scope, platform fragmentation)

#### Q2 2027: Phase 14 (Frontier Features)
**Rationale:** Browser extension + iOS app for growth. Collaboration for enterprise.
- **Duration:** 12-16 weeks
- **Team Size:** 3-4 developers
- **Risk:** High (iOS scope creep, collaboration complexity)

### Feature Prioritization Within Phases

#### Must-Have (P0)
- Phase 7: System audio + Apple Speech + meeting detection
- Phase 8: Vector embeddings + semantic search + AI chat (RAG)
- Phase 9: Auto-link notes + knowledge graph
- Phase 10: Plugin engine + plugin store + MCP server
- Phase 11: Windows + Linux support
- Phase 12: Homebrew + Sparkle + code signing
- Phase 13: Note editing + bulk operations + themes
- Phase 14: Browser extension + iCloud sync

#### Nice-to-Have (P1)
- Phase 7: Speaker diarization + voice memos
- Phase 8: Natural language queries + semantic timeline
- Phase 9: Topic clustering + weekly summaries
- Phase 10: Shortcuts integration + 5 example plugins
- Phase 13: Calendar widget + macOS widgets + Focus mode
- Phase 14: iOS app + workflow automation

#### Deferred (P2)
- Phase 14: Vision Pro capture + real-time collaboration

---

## Appendix A: Glossary

| Term | Definition |
|------|------------|
| **RAG** | Retrieval-Augmented Generation — technique for LLMs to answer questions by retrieving relevant documents first |
| **MLX** | Apple's machine learning framework for running models on Apple Silicon |
| **Embeddings** | Dense vector representations of text (384-dim or 1536-dim) for semantic search |
| **Cosine Similarity** | Metric for comparing vector similarity (0.0 = different, 1.0 = identical) |
| **CRDT** | Conflict-free Replicated Data Type — data structure for conflict-free sync across devices |
| **MCP** | Model Context Protocol — protocol for LLMs to query external tools (e.g., ScreenMind API) |
| **dHash** | Difference Hash — perceptual hashing algorithm for image similarity detection |
| **VAD** | Voice Activity Detection — algorithm to detect speech vs silence in audio |
| **Whisper** | OpenAI's open-source speech-to-text model |
| **LDA** | Latent Dirichlet Allocation — topic modeling algorithm |
| **UMAP** | Uniform Manifold Approximation and Projection — dimensionality reduction for visualization |
| **Sparkle** | macOS framework for auto-updating apps |
| **CloudKit** | Apple's iCloud database API for cross-device sync |

---

## Appendix B: Competitive Feature Gap Analysis

| Feature | ScreenMind (Current) | ScreenMind (Post-v2.0) | Screenpipe | Rewind AI | Microsoft Recall | Mem.ai |
|---------|---------------------|------------------------|------------|-----------|------------------|---------|
| Screen capture | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Audio capture | ❌ | ✅ | ✅ | ✅ | ❌ | ✅ |
| Speech-to-text | ❌ | ✅ | ✅ | ✅ | ❌ | ✅ |
| Meeting detection | ❌ | ✅ | ❌ | ✅ | ❌ | ✅ |
| Semantic search | ❌ | ✅ | ❌ | ✅ | ✅ | ✅ |
| AI chat (RAG) | ❌ | ✅ | ❌ | ✅ | ❌ | ✅ |
| Knowledge graph | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ (implicit) |
| Plugin system | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ |
| Cross-platform | macOS only | macOS, Win, Linux | ✅ | ✅ (was) | Windows only | ✅ (cloud) |
| Obsidian export | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Privacy (local-first) | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ |
| Multi-provider AI | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Open-source | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |

**Conclusion:** Post-v2.0, ScreenMind matches or exceeds all competitors on key features while maintaining privacy + open-source advantages.

---

## Appendix C: Technology Stack

### Core Technologies

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| **Language (macOS)** | Swift 5.10+ | Native performance, SwiftUI, Apple frameworks |
| **Language (Cross-Platform)** | Rust | Cross-compile, no GC, mature ecosystem |
| **UI (macOS)** | SwiftUI | Declarative, reactive, native look |
| **UI (Windows)** | Avalonia | Cross-platform .NET, XAML |
| **UI (Linux)** | GTK 4 | Native Linux, well-documented |
| **Database** | SQLite + SwiftData | Portable, fast, zero-config |
| **AI Providers** | Claude, OpenAI, Ollama, Gemini | Multi-provider strategy |
| **Embeddings** | MLX (bge-small-en-v1.5) | On-device, fast, private |
| **Speech-to-Text** | Apple Speech Framework + Whisper.cpp | On-device, offline |
| **OCR (macOS)** | Apple Vision Framework | On-device, fast |
| **OCR (Windows)** | Windows.Media.Ocr | On-device, built-in |
| **OCR (Linux)** | Tesseract | Open-source, accurate |
| **Screen Capture (macOS)** | ScreenCaptureKit | Modern, efficient |
| **Screen Capture (Windows)** | Windows.Graphics.Capture | UWP API |
| **Screen Capture (Linux)** | X11 / Wayland | Cross-desktop |
| **Audio Capture (macOS)** | AVAudioEngine + BlackHole | System audio routing |
| **Plugin Engine** | JavaScriptCore | Sandboxed JS/TS execution |
| **Knowledge Graph** | D3-force (Swift port) | Force-directed layout |
| **Auto-Updates** | Sparkle | Standard for macOS |
| **Cloud Sync** | CloudKit | Native iCloud integration |
| **MCP Server** | JSON-RPC over HTTP | Standard protocol |

### Frameworks & Libraries

| Domain | Framework/Library | Version | Purpose |
|--------|------------------|---------|---------|
| **Machine Learning** | MLX | Latest | On-device embeddings |
| **Audio** | AVAudioEngine | macOS 14+ | Audio capture |
| | Whisper.cpp | Latest | Offline speech-to-text |
| **OCR** | Vision | macOS 14+ | Text recognition |
| | Tesseract | 5.x | Linux OCR |
| **Database** | SwiftData | macOS 14+ | Persistence |
| | SQLite.swift | 0.15+ | Cross-platform DB |
| **Networking** | URLSession | macOS 14+ | HTTP requests |
| | Network.framework | macOS 14+ | TCP/UDP server |
| **UI** | SwiftUI | macOS 14+ | Declarative UI |
| | WidgetKit | macOS 14+ | Widgets |
| **Testing** | XCTest | macOS 14+ | Unit tests |
| **Distribution** | Sparkle | 2.x | Auto-updates |
| **Analytics** | Plausible | Cloud | Privacy-respecting analytics |
| **Crash Reporting** | Sentry | 8.x | Error tracking |

---

## Appendix D: Development Timeline (Gantt Chart)

```
2026
────────────────────────────────────────────────────────────────────
Q2 (Apr-Jun)
  Phase 7: Audio Intelligence          [████████████────────]
  Phase 12: Distribution               [────────████████████]

Q3 (Jul-Sep)
  Phase 8: Semantic Search             [████████████████────────────]
  Phase 10: Plugin System              [────────████████████████────]

Q4 (Oct-Dec)
  Phase 9: Knowledge Graph             [████████████────────]
  Phase 13: Advanced UX                [────────████████████]

2027
────────────────────────────────────────────────────────────────────
Q1 (Jan-Mar)
  Phase 11: Cross-Platform             [████████████████████████████]

Q2 (Apr-Jun)
  Phase 14: Frontier Features          [████████████████████████────]
```

**Total Duration:** ~18 months (Apr 2026 - Jun 2027)
**Parallelization:** 2-3 phases can run in parallel with 3-5 developers

---

## Appendix E: Open Questions & Decisions Needed

### Open Questions

1. **Rust vs Swift for cross-platform core?**
   - Rust: Better Windows/Linux support, no GC
   - Swift: Keep existing codebase, Swift on Linux is maturing
   - **Recommendation:** Rust (better cross-platform story)

2. **Plugin monetization strategy?**
   - Free plugins only (community-driven)
   - Optional paid plugins (Screenpipe model)
   - Plugin developer revenue share (App Store model)
   - **Recommendation:** Free + optional donations to plugin creators

3. **Enterprise features?**
   - SSO (SAML/OAuth)
   - Self-hosted deployment
   - Team management (admin panel)
   - **Recommendation:** Defer to 2028, focus on individuals first

4. **iOS app: Read-only or full capture?**
   - Read-only: Simple, syncs from Mac
   - Full capture: Complex, privacy concerns (iOS screen recording requires user permission per screenshot)
   - **Recommendation:** Read-only v1, defer capture to v2

5. **Vision Pro priority?**
   - High (future-proofing, PR value)
   - Low (small user base, speculative)
   - **Recommendation:** Low — proof-of-concept only

### Decisions Needed

| Decision | Options | Deadline | Owner |
|----------|---------|----------|-------|
| **Cross-platform language** | Rust vs Swift | Before Phase 11 | Tech Lead |
| **Plugin API versioning** | Semantic versioning | Before Phase 10 | API Team |
| **CloudKit vs self-hosted sync** | CloudKit vs WebSockets | Before Phase 14 | Backend Team |
| **Windows UI framework** | Avalonia vs WPF | Before Phase 11 | Windows Dev |
| **Linux UI framework** | GTK vs Qt | Before Phase 11 | Linux Dev |
| **Topic modeling library** | LDA (gensim) vs BERTopic | Before Phase 9 | ML Team |

---

## Appendix F: References & Prior Art

### Competitor Documentation
- **Screenpipe:** https://github.com/mediar-ai/screenpipe
- **Rewind AI:** https://www.rewind.ai (closed-source, limited public docs)
- **Microsoft Recall:** https://support.microsoft.com/en-us/windows/retrace-your-steps-with-recall-aa03f8a0-a78b-4b3e-b0a1-2eb8ac48701c
- **Mem.ai:** https://get.mem.ai
- **LiveRecall:** https://github.com/jasonjmcghee/rem (open-source, Rust)

### Technical References
- **ScreenCaptureKit:** https://developer.apple.com/documentation/screencapturekit
- **Apple Vision Framework:** https://developer.apple.com/documentation/vision
- **Apple Speech Framework:** https://developer.apple.com/documentation/speech
- **MLX:** https://github.com/ml-explore/mlx
- **Whisper.cpp:** https://github.com/ggerganov/whisper.cpp
- **MCP Protocol:** https://modelcontextprotocol.io
- **Sparkle:** https://sparkle-project.org
- **CloudKit:** https://developer.apple.com/icloud/cloudkit/

### Inspirational Projects
- **Obsidian:** https://obsidian.md (PKM tool, plugin ecosystem)
- **Raycast:** https://raycast.com (macOS launcher, extensions)
- **Arc Browser:** https://arc.net (modern browser, workflows)
- **Ollama:** https://ollama.ai (local LLM runner)

---

**END OF PRD v2.0**

*This document is a living roadmap. Phases and features will be adjusted based on user feedback, technical feasibility, and market conditions. Version history tracked in Git.*

**Contributors:** ScreenMind Core Team
**Last Updated:** 2026-03-02
**Next Review:** 2026-06-01
