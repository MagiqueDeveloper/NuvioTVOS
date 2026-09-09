# Nuvio Cinema - Premium Design Brief

## Vision

Transform NuvioTV from a functional streaming app into a **premium cinematic experience** worthy of Apple TV's platform. Every interaction should feel intentional, smooth, and premium.

---

## Design Philosophy

### 1. Liquid Glass Morphism

**Not flat, not skeuomorphic - dimensional glass surfaces with depth.**

- Multi-layer blur and transparency
- Subtle borders and shadows create depth perception
- Dynamic materials that respond to content behind them
- Soft, organic shapes (generous corner radius)

### 2. Cinematic Motion

**Every animation tells a story.**

- Spring-based transitions (natural, organic feel)
- Anticipation and follow-through (Disney principles)
- Momentum scrolling with physics
- Smooth focus transitions with scale + glow
- Content fades in gracefully (no jarring pops)

### 3. Content-First Hierarchy

**The media is the hero, UI is supporting cast.**

- Full-bleed artwork whenever possible
- Overlays instead of separate screens
- Glass UI floats above content, never competes
- Generous white space lets content breathe
- Information revealed progressively (not all at once)

### 4. tvOS Native

**Built for the 10-foot experience.**

- Focus-driven navigation (predictable, logical)
- Large touch targets (88pt minimum)
- High contrast for readability
- Generous spacing between interactive elements
- Remote gestures feel natural (swipe, tap, play/pause)

---

## Visual Language

### Glass System

#### Primary Glass Card
```swift
// Ultra-thin material with subtle tint
.background(.ultraThinMaterial)
.background(Color.black.opacity(0.2))
.cornerRadius(20)
.overlay(
    RoundedRectangle(cornerRadius: 20)
        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
)
.shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
```

#### Focus State
```swift
// Scale up, add glow, intensify border
.scaleEffect(isFocused ? 1.05 : 1.0)
.shadow(color: accentColor.opacity(isFocused ? 0.5 : 0), radius: 30)
.overlay(
    RoundedRectangle(cornerRadius: 20)
        .stroke(Color.white.opacity(isFocused ? 0.3 : 0.1), lineWidth: 1)
)
.animation(.spring(response: 0.4, dampingFraction: 0.8), value: isFocused)
```

#### Overlay Glass
```swift
// Modal backgrounds, player controls
.background(.regularMaterial)
.background(Color.black.opacity(0.4))
.cornerRadius(16)
.shadow(color: .black.opacity(0.5), radius: 40, x: 0, y: 20)
```

### Color Palette

#### Accent Color
- **Primary:** `#6C5CE7` (blue-purple)
- **Gradient:** Linear from `#6C5CE7` to `#A29BFE`
- **Focus glow:** Accent at 50% opacity, 30pt radius

#### Surface Tints
- **Default glass:** Black 20% opacity over ultraThinMaterial
- **Elevated glass:** Black 30% opacity over regularMaterial
- **Hover/active:** White 5% opacity overlay

#### Text Hierarchy
- **Primary (titles):** White 100%
- **Secondary (metadata):** White 80%
- **Tertiary (labels):** White 60%
- **Disabled:** White 40%

#### Status Colors
- **Success:** `#00D26A` (green)
- **Warning:** `#FFB800` (amber)
- **Error:** `#FF3B30` (red)
- **Info:** `#5AC8FA` (blue)

### Typography

#### System Font Stack (SF Pro)
```swift
.font(.system(size: 52, weight: .bold))    // Hero titles
.font(.system(size: 38, weight: .semibold)) // Section headers
.font(.system(size: 29, weight: .medium))   // Content titles
.font(.system(size: 25, weight: .regular))  // Body text
.font(.system(size: 23, weight: .light))    // Captions
```

#### Text Treatments
- **Tracking:** -0.5pt for headlines, 0 for body
- **Line height:** 1.3x for readability
- **Drop shadows:** On text over images (0.5pt blur, 40% opacity)
- **Gradients:** Optional for hero titles (white to white 80%)

### Spacing Scale

**8pt base unit system:**
```
XXS: 8pt   - Icon padding
XS:  12pt  - Tight elements
S:   16pt  - Button padding
M:   24pt  - Card padding
L:   32pt  - Section spacing
XL:  48pt  - Screen margins
XXL: 64pt  - Hero spacing
```

### Corner Radius

```
Buttons:        12pt
Cards:          20pt
Modals:         24pt
Posters:        12pt (2:3 aspect)
Backdrops:      16pt (16:9 aspect)
Pills/Badges:   999pt (fully rounded)
```

### Shadows & Depth

**Three-tier system:**
```swift
// Level 1: Subtle elevation (cards)
.shadow(color: .black.opacity(0.2), radius: 10, y: 5)

// Level 2: Floating (buttons, focused cards)
.shadow(color: .black.opacity(0.3), radius: 20, y: 10)

// Level 3: Modal (overlays, player controls)
.shadow(color: .black.opacity(0.5), radius: 40, y: 20)
```

---

## Component Library

### Core Components

#### 1. GlassCard
**Purpose:** Container for grouped content (metadata, settings, etc.)

**Variants:**
- Default: Subtle glass, shadow level 1
- Elevated: Darker tint, shadow level 2
- Interactive: Focus state with scale + glow

**Usage:**
```swift
GlassCard(style: .elevated, focusable: true) {
    VStack(spacing: 16) {
        // Content
    }
}
```

#### 2. CinematicHero
**Purpose:** Full-width title showcase with backdrop

**Features:**
- Backdrop image with gradient overlay (black 0% → 80%)
- Logo/title over gradient
- Metadata badges (year, rating, runtime)
- Play/Resume CTA button
- Cast carousel below

**Layout:**
```
┌─────────────────────────────────┐
│   [Backdrop with gradient]      │
│                                  │
│   [Logo/Title]                  │
│   ★8.5  2024  2h 15m  4K HDR   │
│   [▶ Play] [+ Library]          │
└─────────────────────────────────┘
```

#### 3. PosterRow
**Purpose:** Horizontal scrolling media collection

**Features:**
- Momentum scrolling with snap points
- Edge fade gradients (20% width)
- Focus indicator (scale 1.0 → 1.08)
- Watch progress bar on focused poster
- Loading shimmer for unloaded items

**Spacing:**
- Poster size: 250pt × 375pt (2:3 aspect)
- Gap: 24pt
- Section title: 38pt above, 20pt below

#### 4. GlassButton
**Purpose:** Primary/secondary actions

**Variants:**
- **Primary:** Accent gradient fill, white text
- **Secondary:** Glass background, white text
- **Tertiary:** No background, accent text

**States:**
- Default: Scale 1.0, subtle shadow
- Focused: Scale 1.05, glow, border intensifies
- Pressed: Scale 0.98, brief haptic (if supported)

#### 5. StreamQualityBadge
**Purpose:** Show video quality/source metadata

**Design:**
- Glass pill with icon + text
- Color-coded: 4K (purple), HDR (gold), HD (blue), SD (gray)
- 8pt padding horizontal, 6pt vertical
- 999pt corner radius (fully rounded)

#### 6. ProgressScrubber
**Purpose:** Playback timeline control

**Features:**
- Glass track (4pt height)
- Played progress (accent color)
- Buffered progress (white 30%)
- Thumb (16pt circle) with glow on focus
- Time labels (current / remaining)
- Chapter markers (if available)

#### 7. GlassOverlay
**Purpose:** Modal/sheet backgrounds

**Features:**
- regularMaterial + dark tint
- Dismissible tap area outside content
- Spring presentation animation (scale 0.95 → 1.0, opacity 0 → 1)
- Backdrop blur animates in

---

## Screen Layouts

### Home Screen

```
┌─────────────────────────────────────┐
│ [Continue Watching - Hero]          │  ← Full-width, 40% screen height
│   [Large poster + metadata + CTA]   │
└─────────────────────────────────────┘

[Section Title: Popular Movies]        ← 38pt bold
┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐        ← Horizontal scroll
│   │ │   │ │   │ │   │ │   │
└───┘ └───┘ └───┘ └───┘ └───┘

[Section Title: Trending TV]
┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐
│   │ │   │ │   │ │   │ │   │
└───┘ └───┘ └───┘ └───┘ └───┘

// Repeat sections...
```

### Details Screen

```
┌─────────────────────────────────────┐
│    [Cinematic Hero - see above]     │  ← Backdrop + metadata
└─────────────────────────────────────┘

┌───────────────────┬─────────────────┐
│  [Description]    │  [Poster Card]  │  ← Two-column layout
│  Lorem ipsum...   │                 │
└───────────────────┴─────────────────┘

[Cast & Crew]                           ← Horizontal scroll
○ Name    ○ Name    ○ Name    ○ Name   ← Circular portraits

[Seasons & Episodes] (if series)        ← Grid or list
┌─────────┐ ┌─────────┐ ┌─────────┐
│ S1 E1   │ │ S1 E2   │ │ S1 E3   │
└─────────┘ └─────────┘ └─────────┘

[Similar Titles]                        ← Poster row
┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐
```

### Player Screen

**Default state:** Full-screen video, no UI

**On remote interaction:** Controls fade in (3sec timeout)

```
┌─────────────────────────────────────┐
│                                     │
│         [Video Surface]             │
│                                     │
│  ┌───────────────────────────────┐ │  ← Glass overlay (bottom)
│  │ [Title]                       │ │
│  │ ●─────────○───────────────── │ │  ← Scrubber
│  │ 00:45:30          -01:15:22  │ │
│  │ [◀◀] [▶] [▶▶]  [Audio] [CC] │ │  ← Controls
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
```

**Side panel (on menu press):**
```
┌──────────────┐
│ [Audio]      │  ← Glass panel (right side)
│ ✓ English    │
│   Spanish    │
│   French     │
├──────────────┤
│ [Subtitles]  │
│   Off        │
│ ✓ English    │
│   Spanish    │
└──────────────┘
```

### Settings Screen

```
[Settings]  ← 52pt hero title

┌─────────────────────────────┐
│ General                     │  ← Glass card
│ Language, Theme, etc.       │
└─────────────────────────────┘

┌─────────────────────────────┐
│ Playback                    │  ← Glass card
│ Quality, Subtitles, Audio   │
└─────────────────────────────┘

┌─────────────────────────────┐
│ Integrations                │  ← Glass card
│ Trakt, Jellyfin, Debrid     │
└─────────────────────────────┘

// Grouped glass cards with 24pt gap
```

---

## Animation Specifications

### Spring Curves

**Primary (focus, scale):**
```swift
.animation(.spring(response: 0.4, dampingFraction: 0.8), value: isFocused)
```

**Secondary (opacity, color):**
```swift
.animation(.easeInOut(duration: 0.3), value: isVisible)
```

**Scroll momentum:**
```swift
ScrollView(.horizontal) {
    // Natural deceleration, snap to items
}
.scrollTargetBehavior(.viewAligned)
```

### Transitions

**Modal presentation:**
```swift
.transition(.asymmetric(
    insertion: .scale(scale: 0.95).combined(with: .opacity),
    removal: .opacity
))
```

**Content fade-in:**
```swift
.opacity(isLoaded ? 1 : 0)
.animation(.easeIn(duration: 0.2), value: isLoaded)
```

**Player controls:**
```swift
.opacity(controlsVisible ? 1 : 0)
.offset(y: controlsVisible ? 0 : 20)
.animation(.easeOut(duration: 0.25), value: controlsVisible)
```

---

## Accessibility

### Focus Engine

- **Predictable navigation:** Left/right for rows, up/down for sections
- **Focus guides:** Connect non-adjacent elements logically
- **Focus grouping:** Tab view items, modal content
- **Remember focus:** Return to last focused item when navigating back

### Labels & Hints

```swift
.accessibilityLabel("Play Inception")
.accessibilityHint("Starts the movie from the beginning")
.accessibilityAddTraits(.isButton)
```

### Reduce Motion

Respect `UIAccessibility.isReduceMotionEnabled`:
- Disable spring animations → linear
- Reduce scale transforms → 1.02 instead of 1.08
- Skip particle effects, parallax

---

## Performance Guidelines

### Image Loading

- **Lazy loading:** Load posters as they scroll into view
- **Placeholder:** Shimmer gradient while loading
- **Caching:** URLCache + custom in-memory cache
- **Size optimization:** Request appropriately sized images (250pt @2x = 500px)

### View Identity

```swift
ForEach(items) { item in
    PosterCard(item: item)
        .id(item.id) // Stable identity prevents re-renders
}
```

### Avoid Over-Blur

- Limit blur layers (max 2-3 stacked materials)
- Use `.ultraThinMaterial` when possible (cheaper than `.regularMaterial`)
- Backdrop images: Pre-blur on backend if possible

### Throttle Updates

```swift
.onChange(of: searchText) { _, newValue in
    debounceTask?.cancel()
    debounceTask = Task {
        try? await Task.sleep(for: .milliseconds(300))
        await performSearch(newValue)
    }
}
```

---

## Platform Considerations

### tvOS Specifics

- **Safe area:** 90pt top (status bar), 60pt bottom (home indicator)
- **Overscan:** Keep critical UI 60pt from edges
- **Remote gestures:** Swipe (directional), tap (select), play/pause, menu (back)
- **Text input:** Use native `TextField` (opens system keyboard)

### Apple TV Hardware

- **Apple TV HD (2015):** 2GB RAM, A8 chip → limit blur, smaller caches
- **Apple TV 4K (2021+):** 3-4GB RAM, A12+ → full effects

**Detection:**
```swift
let isLegacyDevice = ProcessInfo.processInfo.physicalMemory <= 2_500_000_000
let blurIntensity = isLegacyDevice ? 0.5 : 1.0
```

---

## Future Enhancements

### Phase 2+ Features

- **Ambient mode:** Poster screensaver with Ken Burns effect
- **Seasonal themes:** Subtle UI tint based on content (warm for summer films, cool for winter)
- **Audio reactive:** Player UI pulses subtly with music
- **Haptic feedback:** Controller rumble on important actions (if supported)
- **Live Activities:** TopShelf integration with continue watching

---

## Reference Inspiration

**Apps to study:**
- Apple TV+ (hero layouts, typography)
- Netflix tvOS (focus transitions, loading states)
- Infuse (glass UI, settings organization)
- Plex (metadata presentation, library browsing)

**Design systems:**
- Apple Human Interface Guidelines (tvOS)
- Fluent 2 (Microsoft) - glass morphism principles
- Material 3 (Google) - motion specs

---

## Success Criteria

A successful premium cinema experience means:

✅ **Users say "wow"** when they first open the app  
✅ **Navigation feels effortless** - no hunting for focus  
✅ **Loading states are beautiful** - not jarring or blank  
✅ **Content is hero** - UI supports, never competes  
✅ **Interactions are smooth** - 60fps, no stutters  
✅ **Details matter** - shadows, spacing, typography perfect  

---

*This is a living document. Update as the design evolves.*
