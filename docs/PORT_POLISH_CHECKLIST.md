# Port + Polish Refactoring Checklist

## Purpose

As we port 113 files from fork/main to nuviocinema, we're not just copying - we're **improving**. This checklist ensures consistent quality elevation across all ported code.

---

## Code Quality Standards

### ✅ Modern Swift Patterns

**Before (fork/main style):**
```swift
func fetchCatalog(completion: @escaping (Result<[Item], Error>) -> Void) {
    URLSession.shared.dataTask(with: url) { data, response, error in
        // ...
    }.resume()
}
```

**After (nuviocinema style):**
```swift
func fetchCatalog() async throws -> [MediaSummary] {
    let (data, _) = try await httpClient.fetch(url)
    return try decoder.decode([MediaSummary].self, from: data)
}
```

**Checklist:**
- [ ] Replace completion handlers with async/await
- [ ] Use structured concurrency (TaskGroup, AsyncSequence)
- [ ] Remove unnecessary `@escaping` closures
- [ ] Use `Sendable` for thread-safe types
- [ ] Apply `@MainActor` to UI-bound classes

---

### ✅ Error Handling

**Before:**
```swift
guard let data = data else { 
    print("No data")
    return 
}
```

**After:**
```swift
guard let data = data else {
    throw NuvioError.noData
}

// With context
throw NuvioError.networkFailed(
    reason: "Catalog fetch failed",
    underlyingError: error
)
```

**Checklist:**
- [ ] Replace print() debug statements with proper errors
- [ ] Define typed errors in NuvioDomain
- [ ] Include context in error messages
- [ ] Handle errors at appropriate layer (don't swallow)
- [ ] User-facing error messages are clear and actionable

---

### ✅ Protocol Conformance

**Before:**
```swift
class CatalogManager {
    func fetchHome() -> [Item] { ... }
    func fetchTrending() -> [Item] { ... }
}
```

**After:**
```swift
struct StremioAddonCatalogRepository: CatalogRepository {
    func home() async throws -> CatalogPage { ... }
    func discover(query: String?) async throws -> CatalogPage { ... }
}
```

**Checklist:**
- [ ] Conform to nuviocinema protocols (CatalogRepository, StreamRepository, etc.)
- [ ] Keep implementation internal, expose via protocol
- [ ] Use dependency injection (init parameters, not singletons)
- [ ] Document protocol conformance with `// MARK: - ProtocolName`

---

### ✅ Extract Reusable Components

**Before:**
```swift
// Duplicated in 5 view models
private func formatRuntime(_ minutes: Int) -> String {
    let hours = minutes / 60
    let mins = minutes % 60
    return "\(hours)h \(mins)m"
}
```

**After:**
```swift
// In NuvioUI/Formatting.swift
extension Int {
    var formattedRuntime: String {
        let hours = self / 60
        let mins = self % 60
        return "\(hours)h \(mins)m"
    }
}
```

**Checklist:**
- [ ] Identify duplicated logic across files
- [ ] Extract to appropriate module (NuvioUI for formatting, NuvioData for business logic)
- [ ] Create extensions for common transformations
- [ ] Build utility functions for repeated patterns

---

### ✅ Naming Clarity

**Before:**
```swift
var s: [Item] = []
func doFetch() { ... }
```

**After:**
```swift
var catalogItems: [MediaSummary] = []
func fetchCatalogItems() async throws -> [MediaSummary] { ... }
```

**Checklist:**
- [ ] No single-letter variables (except loop indices)
- [ ] Function names describe what they do (verb + noun)
- [ ] Boolean properties use `is`, `has`, `should` prefix
- [ ] Acronyms: HTTP, URL, API (not Http, Url, Api)
- [ ] Collections are plural (`items` not `itemList`)

---

### ✅ SwiftUI Best Practices

**Before:**
```swift
struct MyView: View {
    var body: some View {
        VStack {
            // 200 lines of nested views
        }
    }
}
```

**After:**
```swift
struct MyView: View {
    var body: some View {
        VStack {
            headerSection
            contentSection
            footerSection
        }
    }
    
    private var headerSection: some View { ... }
    private var contentSection: some View { ... }
    private var footerSection: some View { ... }
}
```

**Checklist:**
- [ ] Split large bodies into computed properties
- [ ] Extract reusable subviews
- [ ] Use `@ViewBuilder` for conditional content
- [ ] Avoid deep nesting (max 3-4 levels)
- [ ] Stable `.id()` for list items

---

### ✅ Performance Optimization

**Before:**
```swift
ForEach(items) { item in
    PosterCard(item: item)
        .onAppear { loadImage(for: item) } // Loads every render
}
```

**After:**
```swift
ForEach(items) { item in
    PosterCard(item: item)
        .task(id: item.id) { // Only on item change
            await loadImage(for: item)
        }
}
.scrollTargetBehavior(.viewAligned) // Snap to items
```

**Checklist:**
- [ ] Lazy load images in scrollable lists
- [ ] Use `.task()` for async work (auto-cancels)
- [ ] Cache expensive computations
- [ ] Throttle/debounce user input
- [ ] Profile memory usage (Instruments)

---

### ✅ Documentation

**Before:**
```swift
func fetch() { ... }
```

**After:**
```swift
/// Fetches the home catalog page from configured Stremio addons.
///
/// - Returns: A `CatalogPage` containing sections of media items.
/// - Throws: `NuvioError.networkFailed` if request fails.
///
/// Results are cached for 5 minutes to reduce addon load.
func home() async throws -> CatalogPage { ... }
```

**Checklist:**
- [ ] Public APIs have doc comments (///)
- [ ] Complex logic has inline comments
- [ ] Non-obvious decisions explained (// Why: ...)
- [ ] TODOs tagged with context (// TODO: Add pagination)
- [ ] Magic numbers replaced with named constants

---

### ✅ Testing Readiness

**Before:**
```swift
class Manager {
    static let shared = Manager()
    private let api = APIClient()
    // Hard to test
}
```

**After:**
```swift
struct Repository: CatalogRepository {
    let httpClient: HTTPClient
    
    init(httpClient: HTTPClient = URLSessionHTTPClient()) {
        self.httpClient = httpClient
    }
}

// Easy to test with mock HTTPClient
```

**Checklist:**
- [ ] No singletons (use DI)
- [ ] No direct URLSession calls (use HTTPClient protocol)
- [ ] Protocols for all external dependencies
- [ ] Pure functions where possible (input → output, no side effects)
- [ ] State isolated in testable units

---

## UI/UX Improvements

### ✅ Premium Glass Components

**Before:**
```swift
VStack {
    Text("Title")
    Text("Subtitle")
}
.background(Color.black.opacity(0.5))
.cornerRadius(8)
```

**After:**
```swift
GlassCard(style: .elevated) {
    VStack(spacing: 12) {
        Text("Title")
            .font(.system(size: 29, weight: .medium))
        Text("Subtitle")
            .font(.system(size: 23, weight: .light))
            .foregroundColor(.white.opacity(0.8))
    }
}
```

**Checklist:**
- [ ] Use GlassCard/GlassButton from TVPrimitives
- [ ] Apply consistent spacing (8pt grid)
- [ ] Typography follows design brief scale
- [ ] Colors use defined palette
- [ ] Corner radius matches spec (12-24pt)

---

### ✅ Focus States

**Before:**
```swift
Button(action: { }) {
    Text("Play")
}
```

**After:**
```swift
@FocusState private var isFocused: Bool

GlassButton("Play", style: .primary) {
    playAction()
}
.focused($isFocused)
.scaleEffect(isFocused ? 1.05 : 1.0)
.animation(.spring(response: 0.4, dampingFraction: 0.8), value: isFocused)
```

**Checklist:**
- [ ] All interactive elements respond to focus
- [ ] Scale transform on focus (1.05x)
- [ ] Glow effect for focused state
- [ ] Spring animation (response: 0.4, damping: 0.8)
- [ ] Logical focus flow (left/right, up/down)

---

### ✅ Loading States

**Before:**
```swift
if isLoading {
    ProgressView()
} else {
    ContentView()
}
```

**After:**
```swift
ZStack {
    ContentView()
        .opacity(isLoading ? 0 : 1)
    
    if isLoading {
        LoadingStateView()
            .transition(.opacity)
    }
}
.animation(.easeInOut(duration: 0.3), value: isLoading)
```

**Checklist:**
- [ ] Smooth transitions between loading/loaded/error
- [ ] Shimmer effect for placeholder content
- [ ] LoadingStateView for full-screen loads
- [ ] Skeleton screens for partial loads
- [ ] Timeout handling (don't load forever)

---

### ✅ Error States

**Before:**
```swift
if let error = error {
    Text(error.localizedDescription)
}
```

**After:**
```swift
if let error = error {
    ErrorStateView(
        title: "Failed to Load Catalog",
        message: error.userFacingMessage,
        retryAction: { await reload() }
    )
}
```

**Checklist:**
- [ ] User-friendly error messages (not raw debug)
- [ ] Retry action where applicable
- [ ] ErrorStateView with glass styling
- [ ] Icon indicating error type
- [ ] Log technical details (don't show to user)

---

## Architecture Alignment

### ✅ Layer Separation

**Correct layer for each concern:**

```
NuvioDomain:
- Pure types (MediaSummary, PlaybackState)
- No dependencies on other modules
- Sendable, Codable where needed

NuvioData:
- Repository implementations
- HTTP clients, storage, caching
- Adapters for external APIs
- Depends on: NuvioDomain

NuvioPlayback:
- PlaybackEngine implementations
- Player state management
- Depends on: NuvioDomain

NuvioUI:
- Reusable components (GlassCard, PosterCard)
- Formatting utilities
- Depends on: NuvioDomain

NuvioFeatures:
- Feature views (HomeView, PlayerView)
- ViewModels (colocated with views)
- Depends on: all above
```

**Checklist:**
- [ ] No UI code in Data layer
- [ ] No business logic in UI components
- [ ] No data fetching in ViewModels (use repositories)
- [ ] Domain types never import SwiftUI
- [ ] Features compose from lower layers

---

### ✅ Feature Flags

**Before:**
```swift
// Jellyfin always enabled
let jellyfinClient = JellyfinClient()
```

**After:**
```swift
struct AppDependencies {
    let featureFlags: FeatureFlags
    let catalog: CatalogRepository
    
    static func live() -> AppDependencies {
        let flags = FeatureFlags.mvp // Jellyfin disabled initially
        
        let catalog: CatalogRepository
        if flags.enableJellyfin {
            catalog = JellyfinCatalogRepository(...)
        } else {
            catalog = StremioAddonCatalogRepository(...)
        }
        
        return AppDependencies(featureFlags: flags, catalog: catalog)
    }
}
```

**Checklist:**
- [ ] Major integrations behind feature flags
- [ ] Flags defined in AppDependencies
- [ ] MVP configuration for initial spike
- [ ] Full configuration for complete port
- [ ] Flag checks at dependency wiring, not view level

---

## Per-File Checklist

Use this when porting each file:

### Before Starting
- [ ] Read original file completely
- [ ] Identify what it does (single responsibility?)
- [ ] Note dependencies (what does it import?)
- [ ] Check for duplicated logic elsewhere

### During Port
- [ ] Choose correct target module (Domain/Data/Playback/UI/Features)
- [ ] Modernize to async/await
- [ ] Extract reusable components
- [ ] Apply naming conventions
- [ ] Add protocol conformance
- [ ] Split large functions (<50 lines each)
- [ ] Add documentation

### After Port
- [ ] Verify compiles in target module
- [ ] Check for unused imports
- [ ] Run SwiftLint (if available)
- [ ] Compare with design brief (UI files)
- [ ] Mark TODO for follow-up improvements

---

## Quality Gates

Before marking a phase complete:

### Phase 0-2 (MVP)
- [ ] All ported code compiles
- [ ] No force unwraps (`!`) except in unreachable paths
- [ ] No print() statements (use proper errors)
- [ ] At least one video plays end-to-end
- [ ] Focus navigation works logically
- [ ] Glass components used consistently

### Phase 3-4 (Features)
- [ ] All feature flags toggle cleanly
- [ ] Error states tested (network off)
- [ ] Loading states look premium
- [ ] Settings UI is organized
- [ ] Memory usage acceptable (<100MB idle)

### Phase 5-6 (Polish)
- [ ] All animations smooth (60fps)
- [ ] Accessibility labels complete
- [ ] Reduce motion respected
- [ ] Documentation up to date
- [ ] No compiler warnings
- [ ] CI passes

---

## Review Questions

Ask these when reviewing ported code:

1. **Is it simpler?** Did we remove unnecessary complexity?
2. **Is it reusable?** Can other features use this component?
3. **Is it testable?** Could we write a unit test for this?
4. **Is it maintainable?** Will someone understand this in 6 months?
5. **Is it premium?** Does the UI feel like a quality cinema app?

---

*This checklist evolves as we discover patterns during the port. Update it.*
