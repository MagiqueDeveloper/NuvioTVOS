import SwiftUI
import NuvioDomain
import NuvioData
import NuvioPlayback
import NuvioUI

// MARK: - Feature Flags

/// Feature flags control incremental rollout of fork/main features.
/// Start with `.mvp` (Stremio + AetherEngine only), progress to `.full`.
public struct FeatureFlags: Sendable {
    /// Enable Jellyfin self-hosted library integration
    public let enableJellyfin: Bool
    
    /// Enable Trakt watch history sync
    public let enableTrakt: Bool
    
    /// Enable Simkl watch history sync
    public let enableSimkl: Bool
    
    /// Enable SMB network share scanning
    public let enableSMB: Bool
    
    /// Enable Debrid resolvers (RealDebrid, Premiumize, Torbox)
    public let enableDebrid: Bool
    
    /// Enable skip intro detection and UI
    public let enableSkipIntro: Bool
    
    /// Enable AI subtitle translation (OpenAI)
    public let enableAISubtitles: Bool
    
    /// Enable cloud library browsing (Premiumize, Torbox)
    public let enableCloudLibrary: Bool
    
    public init(
        enableJellyfin: Bool = false,
        enableTrakt: Bool = false,
        enableSimkl: Bool = false,
        enableSMB: Bool = false,
        enableDebrid: Bool = false,
        enableSkipIntro: Bool = false,
        enableAISubtitles: Bool = false,
        enableCloudLibrary: Bool = false
    ) {
        self.enableJellyfin = enableJellyfin
        self.enableTrakt = enableTrakt
        self.enableSimkl = enableSimkl
        self.enableSMB = enableSMB
        self.enableDebrid = enableDebrid
        self.enableSkipIntro = enableSkipIntro
        self.enableAISubtitles = enableAISubtitles
        self.enableCloudLibrary = enableCloudLibrary
    }
    
    /// MVP configuration: Stremio addons + AetherEngine only
    public static let mvp = FeatureFlags(
        enableJellyfin: false,
        enableTrakt: false,
        enableSimkl: false,
        enableSMB: false,
        enableDebrid: true,  // Enable for stream resolution
        enableSkipIntro: false,
        enableAISubtitles: false,
        enableCloudLibrary: false
    )
    
    /// Full configuration: All features enabled
    public static let full = FeatureFlags(
        enableJellyfin: true,
        enableTrakt: true,
        enableSimkl: true,
        enableSMB: true,
        enableDebrid: true,
        enableSkipIntro: true,
        enableAISubtitles: true,
        enableCloudLibrary: true
    )
}

public struct AppDependencies: Sendable {
    public let featureFlags: FeatureFlags
    public let catalog: any CatalogRepository
    public let metadata: any MetadataRepository
    public let streams: any StreamRepository
    public let profiles: any ProfileStore
    public let progress: any ProgressStore
    public let library: any LibraryStore
    public let playbackFactory: @MainActor @Sendable () -> any PlaybackEngine

    @MainActor
    public static func live() -> AppDependencies {
        let flags = FeatureFlags.mvp  // Start with MVP configuration
        let repository = MemoryCatalogRepository()
        let importer = LegacyStorageImporter()
        _ = importer.run()
        return AppDependencies(
            featureFlags: flags,
            catalog: repository,
            metadata: repository,
            streams: repository,
            profiles: DefaultProfileStore(),
            progress: DefaultProgressStore(),
            library: DefaultLibraryStore(),
            playbackFactory: { AetherPlaybackEngine.live() }
        )
    }

    public init(featureFlags: FeatureFlags, catalog: any CatalogRepository, metadata: any MetadataRepository, streams: any StreamRepository, profiles: any ProfileStore, progress: any ProgressStore, library: any LibraryStore, playbackFactory: @escaping @MainActor @Sendable () -> any PlaybackEngine) {
        self.featureFlags = featureFlags; self.catalog = catalog; self.metadata = metadata; self.streams = streams; self.profiles = profiles; self.progress = progress; self.library = library; self.playbackFactory = playbackFactory
    }
}

@MainActor
public final class HomeViewModel: ObservableObject {
    @Published public private(set) var page: CatalogPage?
    @Published public private(set) var error: String?
    @Published public private(set) var isLoading = false
    private let repository: any CatalogRepository

    public init(repository: any CatalogRepository) { self.repository = repository }
    public func load() async {
        guard !isLoading else { return }
        isLoading = true; defer { isLoading = false }
        do { page = try await repository.home(); error = nil } catch let caught { error = caught.localizedDescription }
    }
}

public struct HomeView: View {
    @StateObject private var model: HomeViewModel
    private let open: (MediaSummary) -> Void

    public init(repository: any CatalogRepository, open: @escaping (MediaSummary) -> Void) { _model = StateObject(wrappedValue: HomeViewModel(repository: repository)); self.open = open }

    public var body: some View {
        Group {
            if let error = model.error { ErrorStateView(message: error) { Task { await model.load() } } }
            else if model.isLoading && model.page == nil { LoadingStateView() }
            else { ScrollView { LazyVStack(alignment: .leading, spacing: 40) { ForEach(model.page?.sections ?? []) { MediaRow(section: $0, action: open).id($0.id) } }.padding(50) } }
        }
        .task { await model.load() }
    }
}

@MainActor
public final class DetailsViewModel: ObservableObject {
    @Published public private(set) var media: MediaSummary?
    @Published public private(set) var streams: [MediaStream] = []
    @Published public private(set) var error: String?
    private let metadata: any MetadataRepository
    private let streamRepository: any StreamRepository

    public init(metadata: any MetadataRepository, streams: any StreamRepository) { self.metadata = metadata; self.streamRepository = streams }
    public func load(id: NuvioID, type: MediaType) async {
        do { let media = try await metadata.details(for: id, type: type); self.media = media; streams = try await streamRepository.streams(for: media); error = nil }
        catch let caught { error = caught.localizedDescription }
    }
}

public struct DetailsView: View {
    @StateObject private var model: DetailsViewModel
    private let id: NuvioID
    private let type: MediaType
    private let play: (MediaSummary, MediaStream) -> Void

    public init(id: NuvioID, type: MediaType, metadata: any MetadataRepository, streams: any StreamRepository, play: @escaping (MediaSummary, MediaStream) -> Void) { self.id = id; self.type = type; _model = StateObject(wrappedValue: DetailsViewModel(metadata: metadata, streams: streams)); self.play = play }

    public var body: some View {
        Group {
            if let error = model.error { ErrorStateView(message: error) { Task { await model.load(id: id, type: type) } } }
            else if let media = model.media { ScrollView { GlassSurface { VStack(alignment: .leading, spacing: 24) { Text(media.title).font(.largeTitle.bold()); if let overview = media.overview { Text(overview).font(.title3).foregroundStyle(.secondary) }; if !model.streams.isEmpty { Text("Streams").font(.title2.bold()); ForEach(model.streams) { stream in Button(stream.title) { play(media, stream) } } } } }.padding(60) } }
            else { LoadingStateView() }
        }.task { await model.load(id: id, type: type) }
    }
}

@MainActor
public final class SearchViewModel: ObservableObject {
    @Published public private(set) var results: [MediaSummary] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: String?
    private let repository: any CatalogRepository

    public init(repository: any CatalogRepository) { self.repository = repository }

    public func search(_ query: String) async {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { results = []; error = nil; return }
        isLoading = true; defer { isLoading = false }
        do { results = try await repository.search(query: query); error = nil }
        catch let caught { error = caught.localizedDescription }
    }
}

public struct SearchView: View {
    @StateObject private var model: SearchViewModel
    @State private var query = ""
    private let open: (MediaSummary) -> Void

    public init(repository: any CatalogRepository, open: @escaping (MediaSummary) -> Void) { _model = StateObject(wrappedValue: SearchViewModel(repository: repository)); self.open = open }

    public var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            TextField("Search titles", text: $query)
                .textFieldStyle(.plain)
                .padding(18)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                .onSubmit { Task { await model.search(query) } }
                // Keep results in sync with edits made using the tvOS keyboard or dictation.
                // The task id automatically cancels an obsolete request when the query changes.
                .task(id: query) {
                    guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        await model.search("")
                        return
                    }
                    try? await Task.sleep(for: .milliseconds(250))
                    guard !Task.isCancelled else { return }
                    await model.search(query)
                }
            if let error = model.error { ErrorStateView(message: error) }
            else if model.isLoading { LoadingStateView() }
            else { ScrollView { LazyVStack(alignment: .leading, spacing: 18) { ForEach(model.results) { item in Button(item.title) { open(item) }.buttonStyle(.card).id(item.id) } } } }
        }
        .padding(60)
    }
}

public struct DiscoverView: View {
    @State private var query = ""
    private let repository: any CatalogRepository
    private let open: (MediaSummary) -> Void

    public init(repository: any CatalogRepository, open: @escaping (MediaSummary) -> Void) { self.repository = repository; self.open = open }

    public var body: some View {
        SearchBackedCatalogView(title: "Discover", repository: repository, query: query, open: open)
    }
}

private struct SearchBackedCatalogView: View {
    let title: String
    let repository: any CatalogRepository
    let query: String
    let open: (MediaSummary) -> Void
    @State private var items: [MediaSummary] = []

    var body: some View {
        ScrollView { LazyVStack(alignment: .leading, spacing: 18) { Text(title).font(.largeTitle.bold()); ForEach(items) { item in Button(item.title) { open(item) }.buttonStyle(.card).id(item.id) } }.padding(60) }
            .task { items = (try? await repository.discover(query: query)) ?? [] }
    }
}

public struct LibraryView: View {
    private let store: any LibraryStore
    private let profiles: any ProfileStore
    private let open: (MediaSummary) -> Void
    @State private var items: [SavedMedia] = []

    public init(store: any LibraryStore, profiles: any ProfileStore, open: @escaping (MediaSummary) -> Void) { self.store = store; self.profiles = profiles; self.open = open }

    public var body: some View {
        ScrollView { LazyVStack(alignment: .leading, spacing: 18) { Text("Library").font(.largeTitle.bold()); ForEach(items) { item in Button(item.media.title) { open(item.media) }.buttonStyle(.card).id(item.id) } }.padding(60) }
            .task { if let profile = try? profiles.activeProfile() { items = (try? store.items(profileID: profile.id)) ?? [] } }
    }
}

public struct ProfileView: View {
    private let store: any ProfileStore
    @State private var profiles: [Profile] = []
    @State private var activeID: NuvioID?

    public init(store: any ProfileStore) { self.store = store }

    public var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Profiles").font(.largeTitle.bold())
            if profiles.isEmpty { Text("No profiles yet.").foregroundStyle(.secondary) }
            else { ForEach(profiles) { profile in
                Button {
                    do { try store.select(profileID: profile.id); activeID = profile.id } catch { /* keep the current selection on failure */ }
                } label: {
                    HStack {
                        Text(profile.name)
                        Spacer()
                        if activeID == profile.id { Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint) }
                    }
                }.buttonStyle(.card).id(profile.id)
            } }
        }
        .padding(60)
        .task { profiles = (try? store.profiles()) ?? []; activeID = try? store.activeProfile()?.id }
    }
}

public enum TopShelfCoordinator {
    public static func refresh(catalog: any CatalogRepository, profiles: any ProfileStore, progress: any ProgressStore) async {
        guard let profile = try? profiles.activeProfile() else { return }
        guard let page = try? await catalog.home() else { return }
        let progressItems = (try? progress.allProgress(profileID: profile.id)) ?? []
        let byID = Dictionary(uniqueKeysWithValues: progressItems.map { ($0.id, $0) })
        let entries = page.sections.flatMap(\.items).compactMap { media -> TopShelfEntry? in
            guard let itemProgress = byID[media.id], itemProgress.position > 0 else { return nil }
            return TopShelfEntry(contentId: media.id.rawValue, contentType: media.type.rawValue, title: media.title, subtitle: media.subtitle, imageURL: media.artwork.poster?.absoluteString, progress: min(max(itemProgress.fraction ?? 0, 0), 1))
        }
        TopShelfFeedStore.write(Array(entries.prefix(10)))
    }
}

public struct PlayerView: View {
    @StateObject private var model: PlayerViewModel
    private let request: PlaybackRequest

    public init(request: PlaybackRequest, profileID: NuvioID?, engine: any PlaybackEngine, progress: any ProgressStore) { self.request = request; _model = StateObject(wrappedValue: PlayerViewModel(request: request, profileID: profileID, engine: engine, progress: progress)) }

    public var body: some View {
        ZStack { model.engine.surface(); if case .failed(let message) = model.engine.state { ErrorStateView(message: message) } }
            .task { await model.start() }
            .onDisappear { model.stop() }
    }
}

@MainActor
private final class PlayerViewModel: ObservableObject {
    let engine: any PlaybackEngine
    private let request: PlaybackRequest
    private let profileID: NuvioID?
    private let progress: any ProgressStore
    private var progressTask: Task<Void, Never>?

    init(request: PlaybackRequest, profileID: NuvioID?, engine: any PlaybackEngine, progress: any ProgressStore) { self.request = request; self.profileID = profileID; self.engine = engine; self.progress = progress }

    func start() async {
        await engine.load(request)
        progressTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard let self, !Task.isCancelled else { return }
                self.saveProgress()
            }
        }
    }

    func stop() {
        progressTask?.cancel()
        saveProgress()
        engine.stop()
    }

    private func saveProgress() {
        guard let profileID, engine.currentTime > 0 else { return }
        try? progress.save(WatchProgress(id: request.title.id, profileID: profileID, position: engine.currentTime, duration: engine.duration > 0 ? engine.duration : nil))
    }
}

public struct AppShellView: View {
    @State private var path: [NuvioID] = []
    @State private var selected: MediaSummary?
    @State private var playerRequest: PlaybackRequest?
    private let dependencies: AppDependencies

    public init(dependencies: AppDependencies) { self.dependencies = dependencies }

    public var body: some View {
        NavigationStack(path: $path) {
            TabView {
                HomeView(repository: dependencies.catalog) { selected = $0 }
                    .tabItem { Label("Home", systemImage: "house") }
                DiscoverView(repository: dependencies.catalog) { selected = $0 }
                    .tabItem { Label("Discover", systemImage: "sparkles") }
                SearchView(repository: dependencies.catalog) { selected = $0 }
                    .tabItem { Label("Search", systemImage: "magnifyingglass") }
                LibraryView(store: dependencies.library, profiles: dependencies.profiles) { selected = $0 }
                    .tabItem { Label("Library", systemImage: "books.vertical") }
                ProfileView(store: dependencies.profiles)
                    .tabItem { Label("Profile", systemImage: "person.crop.circle") }
            }
            .navigationTitle("Nuvio")
            .sheet(item: $selected) { media in
                DetailsView(id: media.id, type: media.type, metadata: dependencies.metadata, streams: dependencies.streams) { title, stream in
                    let activeProfile = try? dependencies.profiles.activeProfile()
                    let resume = activeProfile.flatMap { try? dependencies.progress.progress(for: title.id, profileID: $0.id) }?.position
                    playerRequest = .init(stream: stream, title: title, resumePosition: resume)
                }
            }
            .fullScreenCover(item: $playerRequest) { request in
                PlayerView(request: request, profileID: try? dependencies.profiles.activeProfile()?.id, engine: dependencies.playbackFactory(), progress: dependencies.progress)
            }
            .task { await TopShelfCoordinator.refresh(catalog: dependencies.catalog, profiles: dependencies.profiles, progress: dependencies.progress) }
        }
    }
}
