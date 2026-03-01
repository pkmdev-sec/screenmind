# ScreenMind UI/UX Audit & Fix Plan

**Date:** 2026-03-02
**Status:** Ready for implementation
**Scope:** 19 SwiftUI views, 33 issues (3 critical, 18 polish, 12 enhancements)

---

## Design Principles (macOS 26 Native)

- **Materials:** `.ultraThinMaterial` for overlays/cards, `.regularMaterial` for content panels, `.thinMaterial` for status bars
- **Corner Radius:** 6pt (small controls), 10pt (cards/panels), 12pt (large modals)
- **Spacing Scale:** 4/8/12/16/24pt
- **Typography:** H1=24pt bold, H2=20pt semibold, H3=16pt semibold, Body=13pt, Small=11pt, Caption=10pt
- **Hover States:** All interactive elements must have `.quaternary.opacity(0.5)` hover background
- **No hardcoded `.background(.background)`** — always use material variants

---

## P0: Ship Blockers (3 issues)

### 1. Fix "Vie w" text truncation in Timeline toolbar
**File:** `Sources/ScreenMindApp/Views/Timeline/TimelineView.swift:149`
**Problem:** View mode picker `frame(width: 80)` is too narrow, truncates "View" label
**Fix:** Remove fixed width or increase to `frame(width: 100)`. Remove the "View" label from the picker entirely — use `labelsHidden()`.

### 2. Fix yellow border box in Timeline toolbar
**File:** `Sources/ScreenMindApp/Views/Timeline/TimelineView.swift:140-156`
**Problem:** macOS default picker styling shows yellow focus ring / border on the segmented controls
**Fix:** Wrap the HStack in a clean container. Apply `.focusable(false)` or style the parent with a clean material background. Restructure the toolbar to use a proper SwiftUI `.toolbar` modifier instead of a manual HStack.

### 3. Fix Timeline cards missing native material
**File:** `Sources/ScreenMindApp/Views/Timeline/TimelineCardView.swift:71-77`
**Problem:** Uses `.background(.background)` instead of material
**Fix:** Replace with `.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))`

---

## P1: High Impact Polish (18 issues)

### 4-9. Add hover states to ALL interactive buttons (6 files)
**Files:**
- `MenuBarContentView.swift:83-175` — All menu bar buttons
- `QuickSearchView.swift:85-115` — Search result rows
- `RecentNotesListView.swift:34-57` — Note rows
- `TimelineView.swift:164-181` — Gallery cards
- `TimelineView.swift:199-249` — List rows
- `NotesBrowserView.swift:44-47` — Note list items

**Fix pattern for each:**
```swift
@State private var hoveredItemID: UUID?

.background(
    RoundedRectangle(cornerRadius: 6)
        .fill(.quaternary.opacity(hoveredItemID == item.id ? 0.5 : 0))
)
.onHover { isHovered in
    hoveredItemID = isHovered ? item.id : nil
}
```

### 10. Timeline toolbar — use proper material
**File:** `TimelineView.swift:54-58`
**Fix:** `.background(.ultraThinMaterial)` instead of `.background(.bar)`

### 11. Timeline status bar — use thin material
**File:** `TimelineView.swift:290-293`
**Fix:** `.background(.thinMaterial)` instead of `.background(.bar)`

### 12. Timeline search field — consistent corner radius
**File:** `TimelineView.swift:115-118`
**Fix:** Change `cornerRadius: 8` to `cornerRadius: 10`

### 13. Screenshot overlay — dimmed background opacity
**File:** `ScreenshotOverlayView.swift:15`
**Fix:** `Color.black.opacity(0.85)` instead of `0.7`

### 14. Screenshot overlay — top/bottom bar material
**File:** `ScreenshotOverlayView.swift:50,107`
**Fix:** Remove `.opacity(0.3)` from `.ultraThinMaterial`

### 15. NotesBrowserView — remove manual sidebar background
**File:** `NotesBrowserView.swift:40`
**Fix:** Remove `.background(.ultraThinMaterial)` — SwiftUI's `.sidebar` style already handles this

### 16. NoteDetailView — content blocks use regularMaterial
**File:** `NoteDetailView.swift:40,61,76`
**Fix:** Change `.ultraThinMaterial` to `.regularMaterial`

### 17. GeneralSettingsView — form style
**File:** `GeneralSettingsView.swift:188`
**Fix:** Keep `.formStyle(.grouped)` — it's correct for macOS settings

### 18. AISettingsView — provider card material
**File:** `AISettingsView.swift:68-69`
**Fix:** Change `.ultraThinMaterial` to `.regularMaterial`

### 19. CaptureSettingsView — slider label sizes
**File:** `CaptureSettingsView.swift:57-63`
**Fix:** Increase from `size: 10` to `size: 11`

### 20. PrivacySettingsView — toggle description spacing
**File:** `PrivacySettingsView.swift:70,195,211`
**Fix:** Add `.padding(.top, 4)` to description HStacks

### 21. CategoryBadge — background opacity
**File:** `CategoryBadge.swift:17`
**Fix:** Change `.opacity(0.15)` to `.opacity(0.2)`

---

## P2: Enhancements (12 items)

### 22. Timeline cards — hover scale effect
**File:** `TimelineView.swift:164-181`
**Approach:** `.scaleEffect(isHovered ? 1.02 : 1.0)` with `.animation(.easeOut(duration: 0.15))`

### 23. Menu bar — animated status pulse
**File:** `MenuBarContentView.swift:18-25`
**Approach:** `.scaleEffect` animation on green status circle when monitoring

### 24. QuickSearchView — keyboard arrow navigation
**File:** `QuickSearchView.swift`
**Approach:** Add `.onKeyPress(.upArrow)` / `.onKeyPress(.downArrow)` to change `selectedIndex`

### 25. NotesBrowserView — Cmd+F search focus
**File:** `NotesBrowserView.swift:51`
**Approach:** `@FocusState` + `.keyboardShortcut("f", modifiers: .command)`

### 26. NoteDetailView — copy buttons for summary/details
**File:** `NoteDetailView.swift:56,71`
**Approach:** Add small clipboard button in section headers

### 27. GeneralSettingsView — animated disk usage bar
**File:** `GeneralSettingsView.swift:149-159`
**Approach:** `.animation(.easeOut(duration: 0.4), value: diskUsageBytes)`

### 28. ScreenshotOverlayView — click-to-zoom
**File:** `ScreenshotOverlayView.swift:62-67`
**Approach:** `@State private var zoomLevel: CGFloat = 1.0`, toggle between 1.0 and 2.0 on click

### 29. OnboardingView — larger progress dots
**File:** `OnboardingView.swift:38-40`
**Approach:** Increase from `8pt` to `10pt`

### 30. OnboardingView — stronger gradient background
**File:** `OnboardingView.swift:117-123`
**Approach:** Increase opacity from `0.05` to `0.08`

### 31. ExportSettingsView — path max width
**File:** `ExportSettingsView.swift:160-161`
**Approach:** Add `.frame(maxWidth: 280)` before `.truncationMode(.middle)`

### 32. OnboardingView — skip setup button
**File:** `OnboardingView.swift:97-112`
**Approach:** Add "Skip" button on first step for power users

### 33. PrivacySettingsView — live pattern tester
**File:** `PrivacySettingsView.swift:105-122`
**Approach:** Add text field where users can paste text and see redaction results

---

## Implementation Strategy

### Phase A: Critical Fixes (P0) — 3 files
1. `TimelineView.swift` — Fix picker width + yellow border
2. `TimelineCardView.swift` — Add native material

### Phase B: Material & Styling Sweep — 10 files
3. Replace all `.background(.background)` and `.background(.bar)` with materials
4. Standardize corner radius to 6/10/12 scale
5. Fix content panel materials (regularMaterial vs ultraThinMaterial)

### Phase C: Interactivity — 6 files
6. Add hover states to all buttons and list items
7. Add animated status indicator

### Phase D: Enhancements — 8 files
8. Hover scale on cards
9. Keyboard navigation
10. Copy buttons
11. Animations
12. Onboarding polish

---

## File Change Matrix

| File | P0 | P1 | P2 | Total Changes |
|------|----|----|-----|---------------|
| TimelineView.swift | 2 | 3 | 1 | 6 |
| TimelineCardView.swift | 1 | 0 | 1 | 2 |
| ScreenshotOverlayView.swift | 0 | 2 | 1 | 3 |
| MenuBarContentView.swift | 0 | 1 | 1 | 2 |
| QuickSearchView.swift | 0 | 1 | 1 | 2 |
| RecentNotesListView.swift | 0 | 1 | 0 | 1 |
| NotesBrowserView.swift | 0 | 1 | 1 | 2 |
| NoteDetailView.swift | 0 | 1 | 1 | 2 |
| GeneralSettingsView.swift | 0 | 0 | 1 | 1 |
| AISettingsView.swift | 0 | 1 | 0 | 1 |
| CaptureSettingsView.swift | 0 | 1 | 0 | 1 |
| PrivacySettingsView.swift | 0 | 1 | 1 | 2 |
| ExportSettingsView.swift | 0 | 0 | 1 | 1 |
| OnboardingView.swift | 0 | 0 | 3 | 3 |
| CategoryBadge.swift | 0 | 1 | 0 | 1 |
| **Total** | **3** | **18** | **12** | **33** |
