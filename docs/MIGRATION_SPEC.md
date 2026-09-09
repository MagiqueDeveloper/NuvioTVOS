# Nuvio Cinema Architecture Migration Specification

**Version:** 1.0  
**Target Branch:** `nuviocinema`  
**Source Branch:** `fork/main`  
**Total Files to Port:** ~112 implementation files  
**Timeline:** 6 weeks (incremental rollout)  
**Strategy:** Adapter pattern + feature flags + clean architecture preservation

---

## Migration Overview

This specification guides the port of fork/main's feature-complete implementation (~112 files) into nuviocinema's clean architecture. The goal is to achieve feature parity while maintaining:

- **Clean separation of concerns** (Domain → Data → Features)
- **Protocol-driven design** (dependency injection via interfaces)
- **Incremental rollout** (feature flags control activation)
- **Backward compatibility** (adapters bridge domain models)

### Architecture Mapping

| fork/main (Source) | nuviocinema (Target) | Strategy |
|-------------------|---------------------|----------|
| `tvosApp/NuvioTV/Sources/Models/` | `Packages/NuvioTVKit/Sources/NuvioDomain/` | Extend domain models with adapters |
| `tvosApp/NuvioTV/Sources/Core/` | `Packages/NuvioTVKit/Sources/NuvioData/` | Port as repository implementations |
| `tvosApp/NuvioTV/Sources/Player/` | `Packages/NuvioTVKit/Sources/NuvioPlayback/` | Replace stub engine with full implementation |
| `tvosApp/NuvioTV/Sources/UI/` | `Packages/NuvioTVKit/Sources/NuvioUI/` | Preserve existing views, add new components |
| `tvosApp/NuvioTV/Sources/ViewModels/` | `Packages/NuvioTVKit/Sources/NuvioFeatures/` | Integrate into existing view models |

---

## Phase 0: Foundation (Week 1, Days 1-2)

**Goal:** Establish the adapter layer, feature flags, and domain extensions without breaking existing functionality.

### 0.1 Domain Model Extensions

**Location:** `Packages/NuvioTVKit/Sources/NuvioDomain/Domain.swift`

**Task:** Extend `MediaSummary` to support fork/main's richer metadata while maintaining backward compatibility.

#### Current MediaSummary Fields
```swift
public struct MediaSummary: Identifiable, Codable, Hashable, Sendable {
    public let id: NuvioID
    public let type: MediaType
    public let title: String
    public let subtitle: String?
    public let overview: String?
    public let year: Int?
    public let artwork: Artwork
    public let rating: Double?
}
```

#### Required Extensions
Add these fields to `MediaSummary`:

```swift
// Metadata enrichment
public let genres: [String]?
public let cast: [CastMember]?
public let crew: [CrewMember]?
public let runtime: Int?  // minutes
public let trailers: [Trailer]?
public let imdbID: String?
public let tmdbID: Int?

// Series-specific
public let episodeCount: Int?
public let seasonCount: Int?
```

#### New Supporting Types
Add to Domain.swift:

```swift
public struct CastMember: Codable, Hashable, Sendable {
    public let name: String
    public let character: String?
    public let order: Int
    
    public init(name: String, character: String? = nil, order: Int) {
        self.name = name
        self.character = character
        self.order = order
    }
}

public struct CrewMember: Codable, Hashable, Sendable {
    public let name: String
    public let job: String
    
    public init(name: String, job: String) {
        self.name = name
        self.job = job
    }
}

public struct Trailer: Codable, Hashable, Sendable {
    public let source: URL
    public let type: String  // "Trailer", "Teaser", etc.
    
    public init(source: URL, type: String) {
        self.source = source
        self.type = type
    }
}
```

**Validation:** Build succeeds, existing sample data still works.

---

### 0.2 Adapter Layer

**Location:** `Packages/NuvioTVKit/Sources/NuvioData/Adapters.swift` (new file)

**Task:** Create bidirectional adapters between fork/main models and nuviocinema domain types.

#### Source Models from fork/main
- `Models/CatalogModels.swift`: `StremioMeta`, `NuvioMeta`, `NuvioCatalog`
- `Models/PlayerModels.swift`: `NuvioStream`, `StreamQuality`, `SourceType`
- `Models/AddonModels.swift`: `AddonManifest`, `AddonResource`

#### Adapter Implementation

```swift
import Foundation
import NuvioDomain

// MARK: - Stremio Meta → MediaSummary

public struct StremioMetaAdapter {
    /// Adapts Stremio addon metadata to nuviocinema domain model
    public static func adapt(_ meta: StremioMeta) -> MediaSummary {
        MediaSummary(
            id: NuvioID(rawValue: meta.id),
            type: adaptType(meta.type),
            title: meta.name,
            subtitle: buildSubtitle(meta),
            overview: meta.description,
            year: meta.releaseInfo.flatMap(extractYear),
            artwork: adaptArtwork(meta),
            rating: meta.imdbRating.flatMap(Double.init),
            genres: meta.genres,
            cast: meta.cast?.map(adaptCast) ?? nil,
            crew: meta.crew?.map(adaptCrew) ?? nil,
            runtime: meta.runtime?.components(separatedBy: " ").first.flatMap(Int.init),
            trailers: meta.trailers?.map(adaptTrailer) ?? nil,
            imdbID: meta.imdb_id,
            tmdbID: nil  // Stremio doesn't provide TMDB IDs
        )
    }
    
    private static func adaptType(_ type: String) -> MediaType {
        switch type.lowercased() {
        case "movie": return .movie
        case "series": return .series
        case "episode": return .episode
        default: return .movie
        }
    }
    
    private static func buildSubtitle(_ meta: StremioMeta) -> String? {
        // Combine year, season/episode info
        if let year = meta.releaseInfo { return year }
        return nil
    }
    
    private static func adaptArtwork(_ meta: StremioMeta) -> Artwork {
        Artwork(
            poster: meta.poster.flatMap(URL.init),
            backdrop: meta.background.flatMap(URL.init),
            logo: meta.logo.flatMap(URL.init)
        )
    }
    
    private static func adaptCast(_ cast: StremioMeta.Cast) -> CastMember {
        CastMember(name: cast.name, character: cast.character, order: cast.order ?? 99)
    }
    
    private static func adaptCrew(_ crew: StremioMeta.Crew) -> CrewMember {
        CrewMember(name: crew.name, job: crew.job)
    }
    
    private static func adaptTrailer(_ trailer: StremioMeta.Trailer) -> Trailer {
        guard let url = URL(string: trailer.source) else {
            return Trailer(source: URL(string: "about:blank")!, type: trailer.type)
        }
        return Trailer(source: url, type: trailer.type)
    }
    
    private static func extractYear(_ releaseInfo: String) -> Int? {
        let yearPattern = #"\d{4}"#
        guard let regex = try? NSRegularExpression(pattern: yearPattern),
              let match = regex.firstMatch(in: releaseInfo, range: NSRange(releaseInfo.startIndex..., in: releaseInfo)),
              let range = Range(match.range, in: releaseInfo) else { return nil }
        return Int(releaseInfo[range])
    }
}

// MARK: - NuvioStream → MediaStream

public struct StreamAdapter {
    /// Adapts fork/main stream model to nuviocinema domain
    public static func adapt(_ stream: NuvioStream, titleID: NuvioID) -> MediaStream {
        MediaStream(
            id: NuvioID(rawValue: stream.url.absoluteString.hashValue.description),
            title: buildTitle(stream),
            url: resolveURL(stream),
            headers: stream.behaviorHints?.httpHeaders ?? [:],
            tracks: []  // Tracks are discovered by playback engine
        )
    }
    
    private static func buildTitle(_ stream: NuvioStream) -> String {
        var components: [String] = []
        
        // Quality indicator
        if let quality = stream.quality {
            components.append(quality.displayName)
        }
        
        // Source type (Torrent, Debrid, Direct)
        if let sourceType = stream.sourceType {
            components.append(sourceType.rawValue.capitalized)
        }
        
        // Provider name
        if let provider = stream.behaviorHints?.provider {
            components.append("[\(provider)]")
        }
        
        return components.isEmpty ? "Stream" : components.joined(separator: " ")
    }
    
    private static func resolveURL(_ stream: NuvioStream) -> URL {
        // If it's a magnet link, return as-is (debrid resolver handles it)
        if stream.url.scheme == "magnet" {
            return stream.url
        }
        
        // Direct HTTP(S) stream
        return stream.url
    }
}

// MARK: - Catalog Adapter

public struct CatalogAdapter {
    /// Adapts fork/main catalog structure to nuviocinema pages
    public static func adapt(_ catalogs: [NuvioCatalog]) -> CatalogPage {
        let sections = catalogs.map { catalog in
            CatalogSection(
                id: NuvioID(rawValue: catalog.id),
                title: catalog.name,
                items: catalog.metas.map(StremioMetaAdapter.adapt)
            )
        }
        return CatalogPage(sections: sections, hasNextPage: false)
    }
}

// MARK: - Reverse Adapters (for services that need fork/main models)

public struct MediaSummaryAdapter {
    /// Reverse adapt nuviocinema → fork/main (for legacy service integration)
    public static func toStremioMeta(_ summary: MediaSummary) -> StremioMeta {
        StremioMeta(
            id: summary.id.rawValue,
            type: summary.type.rawValue,
            name: summary.title,
            description: summary.overview,
            poster: summary.artwork.poster?.absoluteString,
            background: summary.artwork.backdrop?.absoluteString,
            logo: summary.artwork.logo?.absoluteString,
            releaseInfo: summary.year.map(String.init),
            imdbRating: summary.rating.map(String.init),
            genres: summary.genres,
            imdb_id: summary.imdbID
        )
    }
}
```

#### Null Handling Strategy

- **Missing fields:** Use `nil` for optional properties
- **Invalid URLs:** Fallback to `URL(string: "about:blank")!` or omit
- **Empty arrays:** Map to `nil` instead of empty array to save space
- **Type coercion failures:** Log warning, use sensible default (e.g., `.movie` type)

**Validation:** Unit tests for each adapter with sample data from fork/main.

---

### 0.3 Feature Flags

**Location:** `Packages/NuvioTVKit/Sources/NuvioFeatures/FeatureFlags.swift` (new file)

**Task:** Create centralized feature flag system for incremental rollout.

```swift
import Foundation

/// Controls which advanced features are active in this build.
/// Use `.mvp` for the initial vertical slice, then progressively enable.
public struct FeatureFlags: Sendable {
    // Phase 1: Content pipeline
    public let enableStremioAddons: Bool
    public let enableTMDBMetadata: Bool
    public let enableCinemetaFallback: Bool
    
    // Phase 2: Playback enhancements
    public let enableDebridResolvers: Bool
    public let enableAdvancedPlayback: Bool  // Track selection, speed control
    public let enableProgressSync: Bool
    
    // Phase 3: Backend integrations
    public let enableJellyfin: Bool
    public let enableSMB: Bool
    
    // Phase 4: Social features
    public let enableTrakt: Bool
    public let enableSimkl: Bool
    
    // Phase 5: Content enhancements
    public let enableSkipIntro: Bool
    public let enableAISubtitles: Bool
    public let enablePostPlayRecommendations: Bool
    
    // Phase 6: Cloud services
    public let enableCloudSync: Bool
    public let enableAuth: Bool
    
    /// MVP configuration: Stremio addons + AetherEngine playback only
    public static let mvp = FeatureFlags(
        enableStremioAddons: true,
        enableTMDBMetadata: true,
        enableCinemetaFallback: true,
        enableDebridResolvers: false,
        enableAdvancedPlayback: true,
        enableProgressSync: true,
        enableJellyfin: false,
        enableSMB: false,
        enableTrakt: false,
        enableSimkl: false,
        enableSkipIntro: false,
        enableAISubtitles: false,
        enablePostPlayRecommendations: false,
        enableCloudSync: false,
        enableAuth: false
    )
    
    /// Full feature set (target state after Phase 6)
    public static let full = FeatureFlags(
        enableStremioAddons: true,
        enableTMDBMetadata: true,
        enableCinemetaFallback: true,
        enableDebridResolvers: true,
        enableAdvancedPlayback: true,
        enableProgressSync: true,
        enableJellyfin: true,
        enableSMB: true,
        enableTrakt: true,
        enableSimkl: true,
        enableSkipIntro: true,
        enableAISubtitles: true,
        enablePostPlayRecommendations: true,
        enableCloudSync: true,
        enableAuth: true
    )
    
    public init(
        enableStremioAddons: Bool,
        enableTMDBMetadata: Bool,
        enableCinemetaFallback: Bool,
        enableDebridResolvers: Bool,
        enableAdvancedPlayback: Bool,
        enableProgressSync: Bool,
        enableJellyfin: Bool,
        enableSMB: Bool,
        enableTrakt: Bool,
        enableSimkl: Bool,
        enableSkipIntro: Bool,
        enableAISubtitles: Bool,
        enablePostPlayRecommendations: Bool,
        enableCloudSync: Bool,
        enableAuth: Bool
    ) {
        self.enableStremioAddons = enableStremioAddons
        self.enableTMDBMetadata = enableTMDBMetadata
        self.enableCinemetaFallback = enableCinemetaFallback
        self.enableDebridResolvers = enableDebridResolvers
        self.enableAdvancedPlayback = enableAdvancedPlayback
        self.enableProgressSync = enableProgressSync
        self.enableJellyfin = enableJellyfin
        self.enableSMB = enableSMB
        self.enableTrakt = enableTrakt
        self.enableSimkl = enableSimkl
        self.enableSkipIntro = enableSkipIntro
        self.enableAISubtitles = enableAISubtitles
        self.enablePostPlayRecommendations = enablePostPlayRecommendations
        self.enableCloudSync = enableCloudSync
        self.enableAuth = enableAuth
    }
}
```

#### Wiring into AppDependencies

Update `Packages/NuvioTVKit/Sources/NuvioFeatures/Features.swift`:

```swift
public struct AppDependencies: Sendable {
    public let catalog: any CatalogRepository
    public let metadata: any MetadataRepository
    public let streams: any StreamRepository
    public let profiles: any ProfileStore
    public let progress: any ProgressStore
    public let library: any LibraryStore
    public let playbackFactory: @MainActor @Sendable () -> any PlaybackEngine
    public let flags: FeatureFlags  // ADD THIS
    
    @MainActor
    public static func live() -> AppDependencies {
        let flags = FeatureFlags.mvp  // Start with MVP
        // ... rest of initialization uses flags to choose implementations
    }
}
```

**Validation:** Flags compile, `.mvp` and `.full` configurations build successfully.

---

## Phase 1: Core Content Pipeline (Week 1, Days 3-7)

**Goal:** Replace `MemoryCatalogRepository` with real Stremio addon integration. HomeView displays actual content.

### 1.1 Addon Transport Layer

**Location:** `Packages/NuvioTVKit/Sources/NuvioData/AddonClient.swift` (new file)

**Source files from fork/main:**
- `tvosApp/NuvioTV/Sources/Core/Addons/AddonTransportUrls.swift`
- `tvosApp/NuvioTV/Sources/Core/Addons/CommunityAddonCatalog.swift`

**Task:** Port addon HTTP client, conform to existing protocols.

```swift
import Foundation
import NuvioDomain

/// Handles HTTP communication with Stremio-compatible addons
public final class StremioAddonClient: Sendable {
    private let httpClient: HTTPClient
    
    public init(httpClient: HTTPClient = URLSessionHTTPClient()) {
        self.httpClient = httpClient
    }
    
    // MARK: - Addon Discovery
    
    public func fetchCommunityAddons() async throws -> [AddonConfiguration] {
        // Port logic from CommunityAddonCatalog.swift
        // Returns list of preconfigured addon URLs
    }
    
    // MARK: - Addon Metadata
    
    public func fetchManifest(from url: URL) async throws -> AddonManifest {
        let request = URLRequest(url: url.appendingPathComponent("manifest.json"))
        let (data, _) = try await httpClient.data(for: request)
        return try JSONDecoder().decode(AddonManifest.self, from: data)
    }
    
    // MARK: - Catalog Queries
    
    public func fetchCatalog(
        addonURL: URL,
        type: String,
        id: String,
        extra: [String: String] = [:]
    ) async throws -> [StremioMeta] {
        var components = URLComponents(url: addonURL, resolvingAgainstBaseURL: false)!
        components.path = "/catalog/\(type)/\(id).json"
        
        if !extra.isEmpty {
            components.queryItems = extra.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = components.url else { throw NuvioError.invalidResponse }
        let request = URLRequest(url: url)
        let (data, _) = try await httpClient.data(for: request)
        
        let response = try JSONDecoder().decode(CatalogResponse.self, from: data)
        return response.metas
    }
    
    // MARK: - Stream Queries
    
    public func fetchStreams(
        addonURL: URL,
        type: String,
        id: String
    ) async throws -> [NuvioStream] {
        let url = addonURL.appendingPathComponent("stream/\(type)/\(id).json")
        let request = URLRequest(url: url)
        let (data, _) = try await httpClient.data(for: request)
        
        let response = try JSONDecoder().decode(StreamResponse.self, from: data)
        return response.streams
    }
}

// MARK: - Response Models

private struct CatalogResponse: Codable {
    let metas: [StremioMeta]
}

private struct StreamResponse: Codable {
    let streams: [NuvioStream]
}

public struct AddonConfiguration: Codable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let transportURL: URL
    public let manifest: AddonManifest?
    
    public init(id: String, name: String, transportURL: URL, manifest: AddonManifest? = nil) {
        self.id = id
        self.name = name
        self.transportURL = transportURL
        self.manifest = manifest
    }
}

// Import StremioMeta, AddonManifest, NuvioStream models from fork/main
// (Port Models/CatalogModels.swift and Models/AddonModels.swift)
```

#### Model Files to Port

Create `Packages/NuvioTVKit/Sources/NuvioData/StremioModels.swift`:

```swift
// Port relevant types from fork/main Models/CatalogModels.swift:
// - StremioMeta
// - AddonManifest
// - AddonResource
// Keep only the types needed for addon transport, not UI models
```

**Validation:** Can fetch manifest and catalog from a test addon URL.

---

### 1.2 Catalog Repository Implementation

**Location:** `Packages/NuvioTVKit/Sources/NuvioData/StremioAddonCatalogRepository.swift` (new file)

**Task:** Implement `CatalogRepository` protocol using real addon queries.

```swift
import Foundation
import NuvioDomain

public final actor StremioAddonCatalogRepository: CatalogRepository {
    private let client: StremioAddonClient
    private let addons: [AddonConfiguration]
    private var cache: [String: (page: CatalogPage, expiry: Date)] = [:]
    
    public init(client: StremioAddonClient, addons: [AddonConfiguration]) {
        self.client = client
        self.addons = addons
    }
    
    /// Convenience initializer with default community addons
    public static func withDefaults(httpClient: HTTPClient = URLSessionHTTPClient()) async throws -> StremioAddonCatalogRepository {
        let client = StremioAddonClient(httpClient: httpClient)
        let communityAddons = try await client.fetchCommunityAddons()
        return StremioAddonCatalogRepository(client: client, addons: communityAddons)
    }
    
    // MARK: - CatalogRepository
    
    public func home() async throws -> CatalogPage {
        if let cached = cache["home"], cached.expiry > Date() {
            return cached.page
        }
        
        // Query all configured addons in parallel
        let results = await withTaskGroup(of: (String, [StremioMeta]).self) { group in
            for addon in addons {
                group.addTask {
                    let metas = (try? await self.client.fetchCatalog(
                        addonURL: addon.transportURL,
                        type: "movie",
                        id: "top"
                    )) ?? []
                    return (addon.name, metas)
                }
            }
            
            var sections: [(String, [StremioMeta])] = []
            for await result in group {
                sections.append(result)
            }
            return sections
        }
        
        // Convert to domain model
        let catalogs = results.map { (name, metas) in
            NuvioCatalog(id: name.lowercased(), name: name, metas: metas)
        }
        let page = CatalogAdapter.adapt(catalogs)
        
        // Cache for 5 minutes
        cache["home"] = (page, Date().addingTimeInterval(300))
        return page
    }
    
    public func discover(query: String) async throws -> [MediaSummary] {
        // Query "discover" endpoint on all addons
        let results = await withTaskGroup(of: [StremioMeta].self) { group in
            for addon in addons {
                group.addTask {
                    (try? await self.client.fetchCatalog(
                        addonURL: addon.transportURL,
                        type: "movie",
                        id: "discover",
                        extra: ["genre": query]
                    )) ?? []
                }
            }
            
            var allMetas: [StremioMeta] = []
            for await metas in group {
                allMetas.append(contentsOf: metas)
            }
            return allMetas
        }
        
        return results.map(StremioMetaAdapter.adapt)
    }
    
    public func search(query: String) async throws -> [MediaSummary] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        
        // Query search endpoint on all addons
        let results = await withTaskGroup(of: [StremioMeta].self) { group in
            for addon in addons {
                group.addTask {
                    (try? await self.client.fetchCatalog(
                        addonURL: addon.transportURL,
                        type: "movie",
                        id: "search",
                        extra: ["search": query]
                    )) ?? []
                }
            }
            
            var allMetas: [StremioMeta] = []
            for await metas in group {
                allMetas.append(contentsOf: metas)
            }
            return allMetas
        }
        
        return results.map(StremioMetaAdapter.adapt)
    }
}
```

**Validation:** HomeView displays real catalog data from Stremio addons.

---

### 1.3 Stream Repository Implementation

**Location:** `Packages/NuvioTVKit/Sources/NuvioData/StremioStreamRepository.swift` (new file)

**Task:** Implement `StreamRepository` protocol with progressive loading.

```swift
import Foundation
import NuvioDomain

public final actor StremioStreamRepository: StreamRepository {
    private let client: StremioAddonClient
    private let addons: [AddonConfiguration]
    
    public init(client: StremioAddonClient, addons: [AddonConfiguration]) {
        self.client = client
        self.addons = addons
    }
    
    public func streams(for title: MediaSummary) async throws -> [MediaStream] {
        var allStreams: [MediaStream] = []
        
        for addon in addons {
            let nuvioStreams = (try? await client.fetchStreams(
                addonURL: addon.transportURL,
                type: title.type.rawValue,
                id: title.id.rawValue
            )) ?? []
            
            let mediaStreams = nuvioStreams.map { stream in
                StreamAdapter.adapt(stream, titleID: title.id)
            }
            
            allStreams.append(contentsOf: mediaStreams)
        }
        
        return allStreams
    }
}
```

**Note:** Progressive loading (`AsyncThrowingStream`) will be added in Phase 2 with debrid integration.

**Validation:** DetailsView displays stream list, tap shows PlayerView (even if playback fails at this stage).

---

### 1.4 Metadata Enrichment Service

**Location:** `Packages/NuvioTVKit/Sources/NuvioData/MetadataService.swift` (new file)

**Source files from fork/main:**
- `tvosApp/NuvioTV/Sources/Core/TMDB/` (port TMDB client)

**Task:** Enrich MediaSummary with TMDB artwork and metadata.

```swift
import Foundation
import NuvioDomain

public final actor TMDBMetadataRepository: MetadataRepository {
    private let httpClient: HTTPClient
    private let apiKey: String
    private let baseURL = URL(string: "https://api.themoviedb.org/3")!
    
    public init(httpClient: HTTPClient, apiKey: String) {
        self.httpClient = httpClient
        self.apiKey = apiKey
    }
    
    public func details(for id: NuvioID, type: MediaType) async throws -> MediaSummary {
        // Try to parse TMDB ID from NuvioID
        // If it's a Stremio ID format (tt1234567), search TMDB by IMDB ID
        // Fetch full details including cast, crew, trailers
        // Return enriched MediaSummary
        
        let path = type == .movie ? "/movie/\(id.rawValue)" : "/tv/\(id.rawValue)"
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "append_to_response", value: "credits,videos")
        ]
        
        let request = URLRequest(url: components.url!)
        let (data, _) = try await httpClient.data(for: request)
        let tmdbMedia = try JSONDecoder().decode(TMDBMediaDetail.self, from: data)
        
        return adaptTMDBToMediaSummary(tmdbMedia, type: type)
    }
    
    private func adaptTMDBToMediaSummary(_ tmdb: TMDBMediaDetail, type: MediaType) -> MediaSummary {
        MediaSummary(
            id: NuvioID(rawValue: String(tmdb.id)),
            type: type,
            title: tmdb.title ?? tmdb.name ?? "Unknown",
            subtitle: nil,
            overview: tmdb.overview,
            year: extractYear(from: tmdb.release_date ?? tmdb.first_air_date),
            artwork: Artwork(
                poster: tmdb.poster_path.map { URL(string: "https://image.tmdb.org/t/p/w500\($0)") } ?? nil,
                backdrop: tmdb.backdrop_path.map { URL(string: "https://image.tmdb.org/t/p/original\($0)") } ?? nil,
                logo: nil
            ),
            rating: tmdb.vote_average,
            genres: tmdb.genres?.map(\.name),
            cast: tmdb.credits?.cast?.prefix(10).map { CastMember(name: $0.name, character: $0.character, order: $0.order) },
            crew: tmdb.credits?.crew?.filter { $0.job == "Director" }.map { CrewMember(name: $0.name, job: $0.job) },
            runtime: tmdb.runtime,
            trailers: tmdb.videos?.results?.filter { $0.site == "YouTube" }.map {
                Trailer(source: URL(string: "https://www.youtube.com/watch?v=\($0.key)")!, type: $0.type)
            },
            imdbID: tmdb.imdb_id,
            tmdbID: tmdb.id
        )
    }
    
    private func extractYear(from dateString: String?) -> Int? {
        guard let dateString, dateString.count >= 4 else { return nil }
        return Int(dateString.prefix(4))
    }
}

// MARK: - TMDB Response Models

private struct TMDBMediaDetail: Codable {
    let id: Int
    let title: String?
    let name: String?
    let overview: String?
    let release_date: String?
    let first_air_date: String?
    let poster_path: String?
    let backdrop_path: String?
    let vote_average: Double?
    let runtime: Int?
    let imdb_id: String?
    let genres: [TMDBGenre]?
    let credits: TMDBCredits?
    let videos: TMDBVideos?
}

private struct TMDBGenre: Codable {
    let name: String
}

private struct TMDBCredits: Codable {
    let cast: [TMDBCast]?
    let crew: [TMDBCrew]?
}

private struct TMDBCast: Codable {
    let name: String
    let character: String?
    let order: Int
}

private struct TMDBCrew: Codable {
    let name: String
    let job: String
}

private struct TMDBVideos: Codable {
    let results: [TMDBVideo]?
}

private struct TMDBVideo: Codable {
    let key: String
    let site: String
    let type: String
}
```

**Validation:** DetailsView shows enriched metadata (cast, crew, better artwork).

---

### 1.5 Wire into AppDependencies

**Location:** `Packages/NuvioTVKit/Sources/NuvioFeatures/Features.swift`

**Task:** Replace stub repository with real implementations.

```swift
@MainActor
public static func live() -> AppDependencies {
    let flags = FeatureFlags.mvp
    let httpClient = URLSessionHTTPClient()
    let importer = LegacyStorageImporter()
    _ = importer.run()
    
    // Initialize addon client
    let addonClient = StremioAddonClient(httpClient: httpClient)
    
    // Load default addon configurations
    let defaultAddons = [
        AddonConfiguration(
            id: "cinemeta",
            name: "Cinemeta",
            transportURL: URL(string: "https://v3-cinemeta.strem.io")!
        )
    ]
    
    let catalogRepo = StremioAddonCatalogRepository(client: addonClient, addons: defaultAddons)
    let streamRepo = StremioStreamRepository(client: addonClient, addons: defaultAddons)
    let metadataRepo = TMDBMetadataRepository(
        httpClient: httpClient,
        apiKey: "YOUR_TMDB_API_KEY"  // TODO: Move to config
    )
    
    return AppDependencies(
        catalog: catalogRepo,
        metadata: flags.enableTMDBMetadata ? metadataRepo : catalogRepo as any MetadataRepository,
        streams: streamRepo,
        profiles: DefaultProfileStore(),
        progress: DefaultProgressStore(),
        library: DefaultLibraryStore(),
        playbackFactory: { AetherPlaybackEngine.live() },
        flags: flags
    )
}
```

**Validation:**
- ✅ HomeView displays real Stremio content with posters
- ✅ Search returns actual results
- ✅ DetailsView shows metadata and stream list
- ✅ No crashes, graceful fallbacks on network errors

---

## Phase 2: Playback Pipeline (Week 2)

**Goal:** Full playback functionality with track selection, debrid support, and progress tracking.

### 2.1 Enhanced PlaybackEngine Protocol

**Location:** `Packages/NuvioTVKit/Sources/NuvioPlayback/PlaybackEngine.swift`

**Task:** Extend protocol with advanced controls from fork/main's `PlaybackEngineControlling`.

**Source:** `tvosApp/NuvioTV/Sources/Core/Player/PlaybackEngineControlling.swift`

```swift
import Foundation
import SwiftUI
import NuvioDomain

@MainActor
public protocol PlaybackEngine: AnyObject {
    // Existing properties
    var state: PlaybackState { get }
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }
    var tracks: [StreamTrack] { get }
    
    // NEW: Advanced track controls
    var audioTracks: [StreamTrack] { get }
    var subtitleTracks: [StreamTrack] { get }
    var selectedAudioTrack: StreamTrack? { get }
    var selectedSubtitleTrack: StreamTrack? { get }
    
    // NEW: Playback modifiers
    var playbackSpeed: Float { get }
    var audioDelay: TimeInterval { get }
    var subtitleDelay: TimeInterval { get }
    var subtitleScale: Float { get }
    
    // NEW: Diagnostics
    var bufferingProgress: Double { get }
    var droppedFrames: Int { get }
    
    // Existing methods
    func surface() -> AnyView
    func load(_ request: PlaybackRequest) async
    func play()
    func pause()
    func seek(to seconds: TimeInterval) async
    func select(track: StreamTrack)
    func stop()
    
    // NEW: Advanced controls
    func selectAudio(track: StreamTrack)
    func selectSubtitle(track: StreamTrack?)  // nil = disable
    func setPlaybackSpeed(_ speed: Float)  // 0.5x to 2.0x
    func setAudioDelay(_ delay: TimeInterval)
    func setSubtitleDelay(_ delay: TimeInterval)
    func setSubtitleScale(_ scale: Float)
}

// Default implementations for backward compatibility
public extension PlaybackEngine {
    var audioTracks: [StreamTrack] { tracks.filter { $0.kind == .audio } }
    var subtitleTracks: [StreamTrack] { tracks.filter { $0.kind == .subtitle } }
    var selectedAudioTrack: StreamTrack? { nil }
    var selectedSubtitleTrack: StreamTrack? { nil }
    var playbackSpeed: Float { 1.0 }
    var audioDelay: TimeInterval { 0 }
    var subtitleDelay: TimeInterval { 0 }
    var subtitleScale: Float { 1.0 }
    var bufferingProgress: Double { 0 }
    var droppedFrames: Int { 0 }
    
    func selectAudio(track: StreamTrack) { select(track: track) }
    func selectSubtitle(track: StreamTrack?) {
        if let track { select(track: track) }
    }
    func setPlaybackSpeed(_ speed: Float) {}
    func setAudioDelay(_ delay: TimeInterval) {}
    func setSubtitleDelay(_ delay: TimeInterval) {}
    func setSubtitleScale(_ scale: Float) {}
}
```

**Validation:** Existing code compiles, new properties have default implementations.

---

### 2.2 Full AetherPlaybackEngine Implementation

**Location:** `Packages/NuvioTVKit/Sources/NuvioPlayback/AetherPlaybackEngine.swift`

**Source:** `tvosApp/NuvioTV/Sources/Core/Player/AetherPlaybackController.swift` (~100KB file)

**Task:** Replace stub with fork/main's full implementation, adapted to protocol.

```swift
import Foundation
import SwiftUI
import Combine
import class AetherEngine.AetherEngine
import enum AetherEngine.PlaybackState
import struct AetherEngine.TrackInfo
import struct AetherEngine.AetherPlayerSurface
import struct AetherEngine.LoadOptions
import NuvioDomain

@MainActor
public final class AetherPlaybackEngine: PlaybackEngine, ObservableObject {
    private let engine: AetherEngine
    private var stateSubscription: AnyCancellable?
    private var audioTracksSubscription: AnyCancellable?
    private var subtitleTracksSubscription: AnyCancellable?
    private var timeSubscription: AnyCancellable?
    private var request: PlaybackRequest?
    
    // Published state
    @Published public private(set) var state: NuvioDomain.PlaybackState = .idle
    @Published public private(set) var currentTime: TimeInterval = 0
    @Published public private(set) var duration: TimeInterval = 0
    @Published public private(set) var tracks: [StreamTrack] = []
    @Published public private(set) var audioTracks: [StreamTrack] = []
    @Published public private(set) var subtitleTracks: [StreamTrack] = []
    @Published public private(set) var selectedAudioTrack: StreamTrack? = nil
    @Published public private(set) var selectedSubtitleTrack: StreamTrack? = nil
    @Published public private(set) var playbackSpeed: Float = 1.0
    @Published public private(set) var audioDelay: TimeInterval = 0
    @Published public private(set) var subtitleDelay: TimeInterval = 0
    @Published public private(set) var subtitleScale: Float = 1.0
    @Published public private(set) var bufferingProgress: Double = 0
    @Published public private(set) var droppedFrames: Int = 0
    
    public init() throws {
        engine = try AetherEngine()
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        // State mapping
        stateSubscription = engine.$state.sink { [weak self] value in
            self?.state = Self.mapState(value)
        }
        
        // Track management
        audioTracksSubscription = engine.$audioTracks.sink { [weak self] tracks in
            self?.audioTracks = tracks.map { Self.mapTrack($0, kind: .audio) }
            self?.tracks = (self?.audioTracks ?? []) + (self?.subtitleTracks ?? [])
        }
        
        subtitleTracksSubscription = engine.$subtitleTracks.sink { [weak self] tracks in
            self?.subtitleTracks = tracks.map { Self.mapTrack($0, kind: .subtitle) }
            self?.tracks = (self?.audioTracks ?? []) + (self?.subtitleTracks ?? [])
        }
        
        // Time updates (throttled)
        timeSubscription = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.currentTime = self.engine.currentTime
                self.duration = self.engine.duration
                self.bufferingProgress = self.engine.bufferingProgress
                self.droppedFrames = self.engine.droppedFrames
            }
    }
    
    public static func live() -> any PlaybackEngine {
        (try? AetherPlaybackEngine()) ?? UnavailablePlaybackEngine()
    }
    
    public func surface() -> AnyView {
        AnyView(AetherPlayerSurface(engine: engine))
    }
    
    public func load(_ request: PlaybackRequest) async {
        self.request = request
        do {
            var options = LoadOptions()
            options.httpHeaders = request.stream.headers
            
            // Set playback cache if available
            options.cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
                .appendingPathComponent("playback-cache", isDirectory: true)
            
            _ = try await engine.load(
                url: request.stream.url,
                startPosition: request.resumePosition,
                options: options
            )
            
            currentTime = engine.currentTime
            duration = engine.duration
            engine.play()
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
    
    public func play() { engine.play() }
    public func pause() { engine.pause() }
    
    public func seek(to seconds: TimeInterval) async {
        await engine.seek(to: max(0, min(seconds, duration)))
        currentTime = engine.currentTime
    }
    
    public func select(track: StreamTrack) {
        guard let id = Int(track.id) else { return }
        switch track.kind {
        case .audio: selectAudio(track: track)
        case .subtitle: selectSubtitle(track: track)
        }
    }
    
    public func selectAudio(track: StreamTrack) {
        guard let index = Int(track.id) else { return }
        engine.selectAudioTrack(index: index)
        selectedAudioTrack = track
    }
    
    public func selectSubtitle(track: StreamTrack?) {
        if let track, let index = Int(track.id) {
            engine.selectSubtitleTrack(index: index)
            selectedSubtitleTrack = track
        } else {
            engine.deselectSubtitles()
            selectedSubtitleTrack = nil
        }
    }
    
    public func setPlaybackSpeed(_ speed: Float) {
        let clamped = min(2.0, max(0.5, speed))
        engine.setPlaybackSpeed(clamped)
        playbackSpeed = clamped
    }
    
    public func setAudioDelay(_ delay: TimeInterval) {
        engine.setAudioDelay(delay)
        audioDelay = delay
    }
    
    public func setSubtitleDelay(_ delay: TimeInterval) {
        engine.setSubtitleDelay(delay)
        subtitleDelay = delay
    }
    
    public func setSubtitleScale(_ scale: Float) {
        let clamped = min(2.0, max(0.5, scale))
        engine.setSubtitleScale(clamped)
        subtitleScale = clamped
    }
    
    public func stop() {
        engine.stop()
        request = nil
        currentTime = 0
        duration = 0
        tracks = []
        audioTracks = []
        subtitleTracks = []
        selectedAudioTrack = nil
        selectedSubtitleTrack = nil
        playbackSpeed = 1.0
        audioDelay = 0
        subtitleDelay = 0
        subtitleScale = 1.0
    }
    
    // MARK: - Mapping
    
    private static func mapState(_ state: AetherEngine.PlaybackState) -> NuvioDomain.PlaybackState {
        switch state {
        case .idle: return .idle
        case .loading: return .loading
        case .playing: return .playing
        case .paused: return .paused
        case .ended: return .ended
        case .seeking: return .playing
        case .error(let message): return .failed(message)
        }
    }
    
    private static func mapTrack(_ track: TrackInfo, kind: StreamTrack.Kind) -> StreamTrack {
        StreamTrack(
            id: String(track.id),
            kind: kind,
            label: track.name.isEmpty ? (track.language ?? "Unknown") : track.name,
            language: track.language,
            isDefault: track.isDefault
        )
    }
}

@MainActor
private final class UnavailablePlaybackEngine: PlaybackEngine {
    var state: NuvioDomain.PlaybackState = .failed("Aether playback is unavailable.")
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var tracks: [StreamTrack] = []
    var audioTracks: [StreamTrack] = []
    var subtitleTracks: [StreamTrack] = []
    var selectedAudioTrack: StreamTrack? = nil
    var selectedSubtitleTrack: StreamTrack? = nil
    var playbackSpeed: Float = 1.0
    var audioDelay: TimeInterval = 0
    var subtitleDelay: TimeInterval = 0
    var subtitleScale: Float = 1.0
    var bufferingProgress: Double = 0
    var droppedFrames: Int = 0
    
    func surface() -> AnyView { AnyView(Color.black) }
    func load(_ request: PlaybackRequest) async {}
    func play() {}
    func pause() {}
    func seek(to seconds: TimeInterval) async {}
    func select(track: StreamTrack) {}
    func selectAudio(track: StreamTrack) {}
    func selectSubtitle(track: StreamTrack?) {}
    func setPlaybackSpeed(_ speed: Float) {}
    func setAudioDelay(_ delay: TimeInterval) {}
    func setSubtitleDelay(_ delay: TimeInterval) {}
    func setSubtitleScale(_ scale: Float) {}
    func stop() {}
}
```

**Validation:** Video plays, tracks can be selected, seeking works, speed controls functional.

---

### 2.3 Debrid Resolver Integration

**Location:** `Packages/NuvioTVKit/Sources/NuvioData/DebridResolvers.swift` (new file)

**Source files from fork/main:**
- `tvosApp/NuvioTV/Sources/Core/Debrid/RealDebridResolver.swift`
- `tvosApp/NuvioTV/Sources/Core/Debrid/PremiumizeResolver.swift`
- `tvosApp/NuvioTV/Sources/Core/Debrid/TorboxResolver.swift`
- `tvosApp/NuvioTV/Sources/Core/Debrid/DebridProvider.swift`

**Task:** Port debrid services, integrate into stream resolution pipeline.

```swift
import Foundation
import NuvioDomain

// MARK: - Protocol

public protocol DebridResolver: Sendable {
    func resolve(magnetURL: URL) async throws -> URL
    func isAuthenticated() async -> Bool
}

// MARK: - Real-Debrid

public final actor RealDebridResolver: DebridResolver {
    private let httpClient: HTTPClient
    private let credentialStore: CredentialStore
    private let apiBaseURL = URL(string: "https://api.real-debrid.com/rest/1.0")!
    
    public init(httpClient: HTTPClient, credentialStore: CredentialStore) {
        self.httpClient = httpClient
        self.credentialStore = credentialStore
    }
    
    public func resolve(magnetURL: URL) async throws -> URL {
        guard let token = credentialStore.value(for: "realdebrid.token") else {
            throw NuvioError.unavailable("Real-Debrid token not found")
        }
        
        // 1. Add magnet to account
        let addURL = apiBaseURL.appendingPathComponent("/torrents/addMagnet")
        var addRequest = URLRequest(url: addURL)
        addRequest.httpMethod = "POST"
        addRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        addRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        addRequest.httpBody = "magnet=\(magnetURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")".data(using: .utf8)
        
        let (addData, _) = try await httpClient.data(for: addRequest)
        let addResponse = try JSONDecoder().decode(RealDebridAddMagnetResponse.self, from: addData)
        
        // 2. Select all files
        let selectURL = apiBaseURL.appendingPathComponent("/torrents/selectFiles/\(addResponse.id)")
        var selectRequest = URLRequest(url: selectURL)
        selectRequest.httpMethod = "POST"
        selectRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        selectRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        selectRequest.httpBody = "files=all".data(using: .utf8)
        
        _ = try await httpClient.data(for: selectRequest)
        
        // 3. Wait for torrent to process
        try await Task.sleep(for: .seconds(2))
        
        // 4. Get info
        let infoURL = apiBaseURL.appendingPathComponent("/torrents/info/\(addResponse.id)")
        var infoRequest = URLRequest(url: infoURL)
        infoRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (infoData, _) = try await httpClient.data(for: infoRequest)
        let info = try JSONDecoder().decode(RealDebridTorrentInfo.self, from: infoData)
        
        guard let link = info.links.first else {
            throw NuvioError.unavailable("No links available")
        }
        
        // 5. Unrestrict link
        let unrestrictURL = apiBaseURL.appendingPathComponent("/unrestrict/link")
        var unrestrictRequest = URLRequest(url: unrestrictURL)
        unrestrictRequest.httpMethod = "POST"
        unrestrictRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        unrestrictRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        unrestrictRequest.httpBody = "link=\(link.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")".data(using: .utf8)
        
        let (unrestrictData, _) = try await httpClient.data(for: unrestrictRequest)
        let unrestrict = try JSONDecoder().decode(RealDebridUnrestrictResponse.self, from: unrestrictData)
        
        guard let downloadURL = URL(string: unrestrict.download) else {
            throw NuvioError.invalidResponse
        }
        
        return downloadURL
    }
    
    public func isAuthenticated() async -> Bool {
        credentialStore.value(for: "realdebrid.token") != nil
    }
}

private struct RealDebridAddMagnetResponse: Codable {
    let id: String
    let uri: String
}

private struct RealDebridTorrentInfo: Codable {
    let id: String
    let status: String
    let links: [String]
}

private struct RealDebridUnrestrictResponse: Codable {
    let download: String
}

// MARK: - Premiumize (similar structure)
// MARK: - Torbox (similar structure)

// MARK: - Resolver Factory

public enum DebridProviderType: String, Codable, CaseIterable, Sendable {
    case realDebrid = "real-debrid"
    case premiumize
    case torbox
}

public struct DebridResolverFactory {
    public static func resolver(
        for type: DebridProviderType,
        httpClient: HTTPClient,
        credentialStore: CredentialStore
    ) -> DebridResolver {
        switch type {
        case .realDebrid:
            return RealDebridResolver(httpClient: httpClient, credentialStore: credentialStore)
        case .premiumize:
            fatalError("Premiumize not yet ported")
        case .torbox:
            fatalError("Torbox not yet ported")
        }
    }
}
```

#### Update StreamRepository

Modify `StremioStreamRepository` to use debrid resolvers:

```swift
public final actor StremioStreamRepository: StreamRepository {
    private let client: StremioAddonClient
    private let addons: [AddonConfiguration]
    private let debridResolvers: [DebridResolver]
    private let flags: FeatureFlags
    
    public init(
        client: StremioAddonClient,
        addons: [AddonConfiguration],
        debridResolvers: [DebridResolver] = [],
        flags: FeatureFlags
    ) {
        self.client = client
        self.addons = addons
        self.debridResolvers = debridResolvers
        self.flags = flags
    }
    
    public func streams(for title: MediaSummary) async throws -> [MediaStream] {
        var allStreams: [MediaStream] = []
        
        for addon in addons {
            let nuvioStreams = (try? await client.fetchStreams(
                addonURL: addon.transportURL,
                type: title.type.rawValue,
                id: title.id.rawValue
            )) ?? []
            
            for stream in nuvioStreams {
                var mediaStream = StreamAdapter.adapt(stream, titleID: title.id)
                
                // If it's a magnet link and debrid is enabled, resolve it
                if flags.enableDebridResolvers,
                   mediaStream.url.scheme == "magnet",
                   let resolver = debridResolvers.first {
                    if let resolved = try? await resolver.resolve(magnetURL: mediaStream.url) {
                        mediaStream = MediaStream(
                            id: mediaStream.id,
                            title: mediaStream.title + " (Cached)",
                            url: resolved,
                            headers: mediaStream.headers,
                            tracks: mediaStream.tracks
                        )
                    }
                }
                
                allStreams.append(mediaStream)
            }
        }
        
        return allStreams
    }
}
```

**Validation:** Magnet links resolve to direct HTTP streams when debrid is configured.

---

### 2.4 Progress Tracking Enhancement

**Location:** Storage implementations already exist in `DataInterfaces.swift`

**Task:** Ensure progress saves every 5 seconds during playback (already implemented in Features.swift PlayerViewModel).

**Verification:**
- Play a video, let it run for 30 seconds
- Force quit app
- Relaunch, verify resume position is saved
- Check `UserDefaults` key `nuvio.rewrite.progress.v1` contains data

**Validation:** Progress persists across app launches.

---

### 2.5 Integration Test Harness

**Location:** `Packages/NuvioTVKit/Sources/NuvioFeatures/Features.swift`

**Task:** Add debug-only test playback button to HomeView.

```swift
#if DEBUG
public struct HomeView: View {
    @StateObject private var model: HomeViewModel
    private let open: (MediaSummary) -> Void
    @State private var showTestPlayer = false
    
    // ... existing body ...
    
    var body: some View {
        Group {
            // ... existing UI ...
        }
        .task { await model.load() }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Test Playback") {
                    showTestPlayer = true
                }
            }
        }
        .sheet(isPresented: $showTestPlayer) {
            // Hardcoded test stream
            let testStream = MediaStream(
                id: "test",
                title: "Big Buck Bunny",
                url: URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!
            )
            let testTitle = MediaSummary(
                id: "test-title",
                type: .movie,
                title: "Test Video"
            )
            let request = PlaybackRequest(stream: testStream, title: testTitle)
            
            PlayerView(
                request: request,
                profileID: nil,
                engine: AetherPlaybackEngine.live(),
                progress: DefaultProgressStore()
            )
        }
    }
}
#endif
```

**Validation:** Test button loads and plays Big Buck Bunny successfully.

---

## Phase 3: Backend Integrations (Week 3-4)

**Goal:** Add Jellyfin and SMB as alternative content sources.

### 3.1 Jellyfin Client

**Location:** `Packages/NuvioTVKit/Sources/NuvioData/JellyfinClient.swift` (new file)

**Source files from fork/main:**
- `tvosApp/NuvioTV/Sources/Core/Jellyfin/JellyfinClient.swift`
- `tvosApp/NuvioTV/Sources/Core/Jellyfin/JellyfinSessionManager.swift`
- `tvosApp/NuvioTV/Sources/Core/Jellyfin/JellyfinCredentialStore.swift`
- `tvosApp/NuvioTV/Sources/Core/Jellyfin/JellyfinLibraryIndex.swift`
- `tvosApp/NuvioTV/Sources/Core/Jellyfin/JellyfinLibraryResolver.swift`
- `tvosApp/NuvioTV/Sources/Core/Jellyfin/JellyfinServerConfig.swift`
- `tvosApp/NuvioTV/Sources/Core/Jellyfin/JellyfinServerStore.swift`

**Task:** Port Jellyfin integration as a repository implementation.

```swift
import Foundation
import NuvioDomain

public final actor JellyfinRepository: CatalogRepository, MetadataRepository, StreamRepository {
    private let httpClient: HTTPClient
    private let serverURL: URL
    private let apiKey: String
    
    public init(httpClient: HTTPClient, serverURL: URL, apiKey: String) {
        self.httpClient = httpClient
        self.serverURL = serverURL
        self.apiKey = apiKey
    }
    
    // MARK: - CatalogRepository
    
    public func home() async throws -> CatalogPage {
        // Query /Users/{userId}/Items with various filters
        // Section 1: Recently Added
        // Section 2: Continue Watching
        // Section 3: Movies
        // Section 4: TV Shows
        // Convert JellyfinItem → MediaSummary via adapter
    }
    
    public func discover(query: String) async throws -> [MediaSummary] {
        // Query /Users/{userId}/Items with Genre filter
    }
    
    public func search(query: String) async throws -> [MediaSummary] {
        // Query /Users/{userId}/Items with SearchTerm
    }
    
    // MARK: - MetadataRepository
    
    public func details(for id: NuvioID, type: MediaType) async throws -> MediaSummary {
        // Query /Users/{userId}/Items/{itemId}
        // Return full details
    }
    
    // MARK: - StreamRepository
    
    public func streams(for title: MediaSummary) async throws -> [MediaStream] {
        // Construct direct play URL: /Videos/{itemId}/stream
        let streamURL = serverURL
            .appendingPathComponent("Videos")
            .appendingPathComponent(title.id.rawValue)
            .appendingPathComponent("stream")
        
        var components = URLComponents(url: streamURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "Static", value: "true")
        ]
        
        return [MediaStream(
            id: title.id,
            title: "Direct Play",
            url: components.url!,
            headers: ["X-Emby-Token": apiKey]
        )]
    }
}

// Adapter: JellyfinItem → MediaSummary
public struct JellyfinAdapter {
    public static func adapt(_ item: JellyfinItem) -> MediaSummary {
        // Map Jellyfin JSON structure to domain model
    }
}
```

**Wire into AppDependencies:**

```swift
@MainActor
public static func live() -> AppDependencies {
    let flags = FeatureFlags.mvp
    // ...
    
    var catalogSources: [CatalogRepository] = []
    
    if flags.enableStremioAddons {
        catalogSources.append(stremioRepo)
    }
    
    if flags.enableJellyfin,
       let jellyfinURL = UserDefaults.standard.string(forKey: "jellyfin.serverURL"),
       let jellyfinKey = UserDefaults.standard.string(forKey: "jellyfin.apiKey"),
       let url = URL(string: jellyfinURL) {
        let jellyfinRepo = JellyfinRepository(httpClient: httpClient, serverURL: url, apiKey: jellyfinKey)
        catalogSources.append(jellyfinRepo)
    }
    
    // Aggregate catalog from multiple sources
    let catalog = AggregateCatalogRepository(sources: catalogSources)
    
    return AppDependencies(
        catalog: catalog,
        // ...
    )
}
```

**Validation:** Jellyfin content appears in HomeView when flag enabled and credentials configured.

---

### 3.2 SMB Client

**Location:** `Packages/NuvioTVKit/Sources/NuvioData/SMBClient.swift` (new file)

**Source files from fork/main:**
- `tvosApp/NuvioTV/Sources/Core/SMB/` (all files)

**Task:** Port SMB network share integration.

```swift
import Foundation
import NuvioDomain
// Import SMB framework (consider using AMSMB2 or similar)

public final actor SMBRepository: CatalogRepository, StreamRepository {
    // Port SMB client logic
    // Scan network shares for video files
    // Generate MediaSummary from file metadata
    // Provide SMB URLs as streams
}
```

**Validation:** SMB shares appear in library when credentials configured.

---

### 3.3 Aggregate Repository Pattern

**Location:** `Packages/NuvioTVKit/Sources/NuvioData/AggregateRepository.swift` (new file)

**Task:** Allow multiple catalog sources to coexist.

```swift
import Foundation
import NuvioDomain

public final actor AggregateCatalogRepository: CatalogRepository {
    private let sources: [CatalogRepository]
    
    public init(sources: [CatalogRepository]) {
        self.sources = sources
    }
    
    public func home() async throws -> CatalogPage {
        // Query all sources in parallel
        let pages = await withTaskGroup(of: CatalogPage?.self) { group in
            for source in sources {
                group.addTask {
                    try? await source.home()
                }
            }
            
            var allPages: [CatalogPage] = []
            for await page in group {
                if let page { allPages.append(page) }
            }
            return allPages
        }
        
        // Merge sections, prefix with source name
        let merged = pages.flatMap(\.sections)
        return CatalogPage(sections: merged)
    }
    
    public func discover(query: String) async throws -> [MediaSummary] {
        let results = await withTaskGroup(of: [MediaSummary].self) { group in
            for source in sources {
                group.addTask {
                    (try? await source.discover(query: query)) ?? []
                }
            }
            
            var allResults: [MediaSummary] = []
            for await results in group {
                allResults.append(contentsOf: results)
            }
            return allResults
        }
        
        return results
    }
    
    public func search(query: String) async throws -> [MediaSummary] {
        let results = await withTaskGroup(of: [MediaSummary].self) { group in
            for source in sources {
                group.addTask {
                    (try? await source.search(query: query)) ?? []
                }
            }
            
            var allResults: [MediaSummary] = []
            for await results in group {
                allResults.append(contentsOf: results)
            }
            return allResults
        }
        
        return results
    }
}
```

**Validation:** HomeView shows mixed content from Stremio + Jellyfin + SMB.

---

## Phase 4: Social Features (Week 4)

**Goal:** Trakt and Simkl integration for watch history sync and social discovery.

### 4.1 Trakt Client

**Location:** `Packages/NuvioTVKit/Sources/NuvioData/TraktClient.swift` (new file)

**Source files from fork/main:**
- `tvosApp/NuvioTV/Sources/Core/Trakt/` (all files)

**Task:** Port Trakt API integration.

```swift
import Foundation
import NuvioDomain

public final actor TraktClient: Sendable {
    private let httpClient: HTTPClient
    private let credentialStore: CredentialStore
    
    // OAuth flow
    public func authenticate() async throws -> String
    
    // Sync progress
    public func syncProgress(_ progress: [WatchProgress]) async throws
    public func fetchProgress() async throws -> [WatchProgress]
    
    // Recommendations
    public func recommendations() async throws -> [MediaSummary]
}
```

#### Wire into Progress Store

Create wrapper that syncs to both local and Trakt:

```swift
public final actor TraktSyncedProgressStore: ProgressStore {
    private let local: ProgressStore
    private let trakt: TraktClient
    
    public func save(_ progress: WatchProgress) throws {
        try local.save(progress)
        Task {
            try? await trakt.syncProgress([progress])
        }
    }
    
    // ... other methods delegate to local
}
```

**Validation:** Progress syncs to Trakt, recommendations appear in Discover.

---

### 4.2 Simkl Client

**Location:** `Packages/NuvioTVKit/Sources/NuvioData/SimklClient.swift` (new file)

**Source files from fork/main:**
- `tvosApp/NuvioTV/Sources/Core/Simkl/` (all files)

**Task:** Similar structure to Trakt client.

**Validation:** Watch history syncs to Simkl.

---

## Phase 5: Content Enhancements (Week 5)

**Goal:** Skip intro, AI subtitles, post-play recommendations.

### 5.1 Skip Intro Service

**Location:** `Packages/NuvioTVKit/Sources/NuvioData/SkipIntroService.swift` (new file)

**Source files from fork/main:**
- `tvosApp/NuvioTV/Sources/Core/Skip/` (all files)

**Task:** Port intro detection and skip controls.

```swift
import Foundation
import NuvioDomain

public struct IntroSegment: Codable, Sendable {
    public let start: TimeInterval
    public let end: TimeInterval
}

public protocol IntroDetectionService: Sendable {
    func detectIntro(for mediaID: NuvioID) async throws -> IntroSegment?
}

public final actor SkipIntroService: IntroDetectionService {
    // Query intro timestamps database
    // Return skip segment if available
}
```

#### UI Integration

Update `PlayerView` to show "Skip Intro" button when in intro segment:

```swift
// In PlayerViewModel
@Published var currentIntroSegment: IntroSegment? = nil

func checkIntroSegment() {
    if let intro = introSegment,
       engine.currentTime >= intro.start,
       engine.currentTime <= intro.end {
        currentIntroSegment = intro
    } else {
        currentIntroSegment = nil
    }
}

// In PlayerView body
if let intro = model.currentIntroSegment {
    Button("Skip Intro") {
        Task { await model.engine.seek(to: intro.end) }
    }
}
```

**Validation:** Skip intro button appears during intro segments.

---

### 5.2 AI Subtitle Translation

**Location:** `Packages/NuvioTVKit/Sources/NuvioData/AISubtitleService.swift` (new file)

**Source files from fork/main:**
- `tvosApp/NuvioTV/Sources/Core/Player/AISubtitleTranslationCache.swift`

**Task:** Port OpenAI-based subtitle translation.

```swift
import Foundation

public final actor AISubtitleTranslationService {
    private let apiKey: String
    
    public func translate(
        subtitleURL: URL,
        targetLanguage: String
    ) async throws -> URL {
        // Download SRT
        // Parse, translate via OpenAI API
        // Cache translated SRT
        // Return local file URL
    }
}
```

**Validation:** Subtitle translation works when API key configured.

---

### 5.3 Post-Play Recommendations

**Location:** `Packages/NuvioTVKit/Sources/NuvioData/RecommendationService.swift` (new file)

**Source files from fork/main:**
- `tvosApp/NuvioTV/Sources/Core/Player/PostPlayRecommendationController.swift`
- `tvosApp/NuvioTV/Sources/Models/PostPlayRecommendationModels.swift`

**Task:** Show "Up Next" recommendations after playback ends.

```swift
import Foundation
import NuvioDomain

public protocol RecommendationService: Sendable {
    func recommendations(after media: MediaSummary) async throws -> [MediaSummary]
}

public final actor PostPlayRecommendationService: RecommendationService {
    // If series: next episode
    // Else: similar titles from TMDB or Trakt
}
```

#### UI Integration

Update `PlayerView` to show recommendations overlay when playback ends:

```swift
// In PlayerView
.overlay {
    if case .ended = model.engine.state,
       !model.recommendations.isEmpty {
        RecommendationsOverlay(
            items: model.recommendations,
            onSelect: { /* play selected */ }
        )
    }
}
```

**Validation:** Recommendations appear when video ends.

---

## Phase 6: Cloud & Auth (Week 6)

**Goal:** Cloud sync and authentication for multi-device support.

### 6.1 Authentication Service

**Location:** `Packages/NuvioTVKit/Sources/NuvioData/AuthService.swift` (new file)

**Source files from fork/main:**
- `tvosApp/NuvioTV/Sources/Core/Auth/` (all files)

**Task:** Port OAuth and session management.

```swift
import Foundation
import NuvioDomain

public protocol AuthService: Sendable {
    func signIn() async throws -> AuthSession
    func signOut() async throws
    func currentSession() async -> AuthSession?
}

public struct AuthSession: Codable, Sendable {
    public let userId: String
    public let accessToken: String
    public let refreshToken: String
    public let expiresAt: Date
}

public final actor SupabaseAuthService: AuthService {
    // Port Supabase integration
}
```

**Validation:** Users can sign in, session persists.

---

### 6.2 Cloud Sync Service

**Location:** `Packages/NuvioTVKit/Sources/NuvioData/CloudSyncService.swift` (new file)

**Source files from fork/main:**
- `tvosApp/NuvioTV/Sources/Core/Cloud/` (all files)
- `tvosApp/NuvioTV/Sources/Core/Sync/` (all files)

**Task:** Sync profiles, progress, library across devices.

```swift
import Foundation
import NuvioDomain

public protocol CloudSyncService: Sendable {
    func sync() async throws
    func uploadProgress(_ progress: [WatchProgress]) async throws
    func downloadProgress() async throws -> [WatchProgress]
}

public final actor SupabaseCloudSync: CloudSyncService {
    // Port Supabase sync logic
}
```

#### Wire into Stores

Wrap stores with cloud-synced versions:

```swift
public final actor CloudSyncedProgressStore: ProgressStore {
    private let local: ProgressStore
    private let cloud: CloudSyncService
    
    public func save(_ progress: WatchProgress) throws {
        try local.save(progress)
        Task {
            try? await cloud.uploadProgress([progress])
        }
    }
}
```

**Validation:** Progress syncs across multiple devices.

---

### 6.3 Settings UI

**Location:** `Packages/NuvioTVKit/Sources/NuvioFeatures/SettingsView.swift` (new file)

**Task:** Create settings screen for configuration.

```swift
import SwiftUI
import NuvioDomain

public struct SettingsView: View {
    @State private var flags: FeatureFlags = .mvp
    
    public var body: some View {
        Form {
            Section("Features") {
                Toggle("Stremio Addons", isOn: $flags.enableStremioAddons)
                Toggle("Jellyfin", isOn: $flags.enableJellyfin)
                Toggle("Debrid Resolvers", isOn: $flags.enableDebridResolvers)
                Toggle("Trakt Sync", isOn: $flags.enableTrakt)
                Toggle("Skip Intro", isOn: $flags.enableSkipIntro)
            }
            
            Section("Jellyfin") {
                TextField("Server URL", text: $jellyfinURL)
                SecureField("API Key", text: $jellyfinKey)
            }
            
            Section("Debrid") {
                Button("Configure Real-Debrid") { /* auth flow */ }
            }
            
            Section("Cloud") {
                if authService.isSignedIn {
                    Button("Sign Out") { /* sign out */ }
                } else {
                    Button("Sign In") { /* sign in */ }
                }
            }
        }
    }
}
```

Add to AppShellView TabView:

```swift
SettingsView()
    .tabItem { Label("Settings", systemImage: "gear") }
```

**Validation:** All services can be configured from settings.

---

## Rollout Strategy

### Week 1
- **Phase 0 + Phase 1:** Foundation + Core content pipeline
- **Deployment:** Internal TestFlight, MVP flag enabled
- **Success Criteria:** Real Stremio content displays, basic playback works

### Week 2
- **Phase 2:** Full playback engine + debrid
- **Deployment:** TestFlight with `.mvp` + debrid flag
- **Success Criteria:** Advanced playback controls work, debrid resolves magnets

### Week 3-4
- **Phase 3:** Jellyfin + SMB
- **Deployment:** Feature flags for each backend
- **Success Criteria:** Multi-source catalogs work

### Week 4
- **Phase 4:** Trakt + Simkl
- **Deployment:** Social sync flags
- **Success Criteria:** Progress syncs to external services

### Week 5
- **Phase 5:** Content enhancements
- **Deployment:** Skip intro, AI subtitles flags
- **Success Criteria:** Enhanced playback features work

### Week 6
- **Phase 6:** Cloud + Auth
- **Deployment:** Full feature set, `.full` flag
- **Success Criteria:** Multi-device sync works, production ready

---

## Testing Strategy

### Unit Tests
- Adapter logic (StremioMetaAdapter, StreamAdapter, etc.)
- Repository isolation (mock HTTPClient)
- Feature flag permutations

### Integration Tests
- End-to-end: Query addon → display → play → save progress
- Multi-source aggregation
- Debrid resolution pipeline
- Cloud sync roundtrip

### Manual QA Checklist
- [ ] HomeView displays content from all enabled sources
- [ ] Search returns results
- [ ] Video plays with tracks selectable
- [ ] Progress saves and resumes
- [ ] Debrid links resolve
- [ ] Jellyfin content integrates
- [ ] Trakt sync works
- [ ] Skip intro appears
- [ ] Settings persist
- [ ] Cloud sync across devices

---

## Risk Mitigation

### API Rate Limits
- **Risk:** TMDB, Trakt, debrid services have rate limits
- **Mitigation:** Cache aggressively, respect HTTP 429, implement backoff

### Backward Compatibility
- **Risk:** Breaking existing nuviocinema users
- **Mitigation:** Feature flags default to MVP, existing UI unchanged

### Data Migration
- **Risk:** Loss of user data during migration
- **Mitigation:** LegacyStorageImporter copies (doesn't delete), can retry

### Playback Failures
- **Risk:** AetherEngine integration issues
- **Mitigation:** Fallback to UnavailablePlaybackEngine with error message

---

## Rollback Plan

If a phase fails validation:

1. **Disable feature flag** for that phase
2. **Revert to previous package state** via git
3. **Deploy TestFlight** with earlier flag configuration
4. **Debug offline**, fix, re-test Phase 0 → failed phase

Each phase is independently toggleable via `FeatureFlags`, ensuring partial rollouts are safe.

---

## Completion Checklist

- [ ] Phase 0: Foundation complete, builds successfully
- [ ] Phase 1: Real content displays, search works
- [ ] Phase 2: Full playback with tracks and debrid
- [ ] Phase 3: Jellyfin and SMB integrated
- [ ] Phase 4: Trakt and Simkl syncing
- [ ] Phase 5: Skip intro and AI subtitles work
- [ ] Phase 6: Cloud sync and auth functional
- [ ] All integration tests pass
- [ ] Manual QA completed
- [ ] Documentation updated
- [ ] Production deploy to `nuviocinema` branch

---

**Document End**
