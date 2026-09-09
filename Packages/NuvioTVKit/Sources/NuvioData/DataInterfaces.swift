import Foundation
import NuvioDomain

public protocol HTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public struct HTTPClientConfiguration: Sendable {
    public var timeout: TimeInterval
    public var retries: Int

    public init(timeout: TimeInterval = 20, retries: Int = 2) {
        self.timeout = timeout
        self.retries = max(0, retries)
    }
}

public final class URLSessionHTTPClient: HTTPClient, @unchecked Sendable {
    private let session: URLSession
    private let configuration: HTTPClientConfiguration

    public init(configuration: HTTPClientConfiguration = .init(), session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    public func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        var request = request
        request.timeoutInterval = configuration.timeout
        var lastError: Error?
        for attempt in 0...configuration.retries {
            do {
                let (data, response) = try await session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else { throw NuvioError.invalidResponse }
                if (500...599).contains(httpResponse.statusCode), attempt < configuration.retries {
                    try await Task.sleep(nanoseconds: UInt64((attempt + 1) * 150_000_000))
                    continue
                }
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw NuvioError.transport("Request failed with HTTP (httpResponse.statusCode).")
                }
                return (data, httpResponse)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                lastError = error
                if attempt < configuration.retries {
                    try await Task.sleep(nanoseconds: UInt64((attempt + 1) * 150_000_000))
                }
            }
        }
        throw NuvioError.transport(lastError?.localizedDescription ?? "The request failed.")
    }
}

public protocol CatalogRepository: Sendable {
    func home() async throws -> CatalogPage
    func discover(query: String) async throws -> [MediaSummary]
    func search(query: String) async throws -> [MediaSummary]
}

public protocol MetadataRepository: Sendable {
    func details(for id: NuvioID, type: MediaType) async throws -> MediaSummary
}

public protocol StreamRepository: Sendable {
    func streams(for title: MediaSummary) async throws -> [MediaStream]
}

public protocol ProfileStore: Sendable {
    func profiles() throws -> [Profile]
    func activeProfile() throws -> Profile?
    func select(profileID: NuvioID) throws
    func save(_ profile: Profile) throws
}

public protocol ProgressStore: Sendable {
    func progress(for id: NuvioID, profileID: NuvioID) throws -> WatchProgress?
    func allProgress(profileID: NuvioID) throws -> [WatchProgress]
    func save(_ progress: WatchProgress) throws
    func remove(id: NuvioID, profileID: NuvioID) throws
}

public protocol LibraryStore: Sendable {
    func items(profileID: NuvioID) throws -> [SavedMedia]
    func contains(id: NuvioID, profileID: NuvioID) throws -> Bool
    func setSaved(_ media: MediaSummary, profileID: NuvioID, saved: Bool) throws
}

public protocol CredentialStore: Sendable {
    func value(for key: String) -> String?
    func setValue(_ value: String?, for key: String)
}

public final class UserDefaultsCredentialStore: CredentialStore, @unchecked Sendable {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    public func value(for key: String) -> String? { defaults.string(forKey: key) }
    public func setValue(_ value: String?, for key: String) { defaults.set(value, forKey: key) }
}

public struct LegacyMigrationReport: Codable, Sendable {
    public let importedKeys: [String]
    public let skippedKeys: [String]
    public let didRun: Bool

    public init(importedKeys: [String], skippedKeys: [String], didRun: Bool) {
        self.importedKeys = importedKeys
        self.skippedKeys = skippedKeys
        self.didRun = didRun
    }
}

/// One idempotent seam for the old monolithic app's persisted state. The importer
/// intentionally copies rather than deletes legacy values so a failed first launch
/// can be retried and users can roll back without losing credentials or progress.
public final class LegacyStorageImporter: @unchecked Sendable {
    public static let markerKey = "nuvio.rewrite.storageMigration.v1"
    private let defaults: UserDefaults
    private let destination: UserDefaults

    public init(defaults: UserDefaults = .standard, destination: UserDefaults = .standard) {
        self.defaults = defaults
        self.destination = destination
    }

    public func run() -> LegacyMigrationReport {
        guard !destination.bool(forKey: Self.markerKey) else { return .init(importedKeys: [], skippedKeys: [], didRun: false) }
        let keys = [
            "nuvio.profiles", "nuvio.active_profile_id", "nuvio.lastActiveProfileId",
            "nuvio.tv.watchProgress.ledger.v1", "nuvio.tv.library", "nuvio.library",
            "nuvio.auth.session", "nuvio.auth.skipLogin", "nuvio.deepLink.pending",
            "nuvio.settings.profileName", "nuvio.settings.profileAutoSelectLast"
        ]
        var imported: [String] = []
        var skipped: [String] = []
        for key in keys {
            guard let value = defaults.object(forKey: key) else { skipped.append(key); continue }
            destination.set(value, forKey: key)
            imported.append(key)
        }
        migrateProfiles()
        migrateProgress()
        destination.set(true, forKey: Self.markerKey)
        return .init(importedKeys: imported, skippedKeys: skipped, didRun: true)
    }

    private func migrateProfiles() {
        guard destination.data(forKey: "nuvio.rewrite.profiles.v1") == nil,
              let data = defaults.data(forKey: "nuvio.profiles"),
              let legacy = try? JSONDecoder().decode([LegacyProfile].self, from: data) else { return }
        let profiles = legacy.map { profile in
            Profile(id: NuvioID(rawValue: profile.id), name: profile.name, avatar: URL(string: profile.avatarId), isPINProtected: profile.isPinProtected)
        }
        guard let encoded = try? JSONEncoder().encode(profiles) else { return }
        destination.set(encoded, forKey: "nuvio.rewrite.profiles.v1")
    }

    private func migrateProgress() {
        guard destination.data(forKey: "nuvio.rewrite.progress.v1") == nil else { return }
        let activeID = defaults.string(forKey: "nuvio.active_profile_id") ?? "default"
        var migrated: [WatchProgress] = []
        for key in defaults.dictionaryRepresentation().keys where key == "nuvio.tv.watchProgress.ledger.v1" || key.hasPrefix("nuvio.tv.watchProgress.ledger.v1.") {
            guard let data = defaults.data(forKey: key), let records = try? JSONDecoder().decode([LegacyProgress].self, from: data) else { continue }
            let profileID = key == "nuvio.tv.watchProgress.ledger.v1" ? activeID : (key.split(separator: ".").last.map(String.init) ?? activeID)
            migrated.append(contentsOf: records.map {
                WatchProgress(id: NuvioID(rawValue: $0.contentId), profileID: NuvioID(rawValue: profileID), position: $0.position, duration: $0.duration > 0 ? $0.duration : nil, updatedAt: $0.lastWatchedAt)
            })
        }
        guard !migrated.isEmpty, let encoded = try? JSONEncoder().encode(migrated) else { return }
        destination.set(encoded, forKey: "nuvio.rewrite.progress.v1")
    }
}

private struct LegacyProfile: Codable {
    let id: String
    let name: String
    let isPinProtected: Bool
    let avatarId: String

    private enum CodingKeys: String, CodingKey { case id, name, isPinProtected, avatarId }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        isPinProtected = try values.decodeIfPresent(Bool.self, forKey: .isPinProtected) ?? false
        avatarId = try values.decodeIfPresent(String.self, forKey: .avatarId) ?? ""
    }
}

private struct LegacyProgress: Codable {
    let contentId: String
    let position: Double
    let duration: Double
    let lastWatchedAt: Date
}

public final class DefaultProfileStore: ProfileStore, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key = "nuvio.rewrite.profiles.v1"
    private let activeKey = "nuvio.active_profile_id"

    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    public func profiles() throws -> [Profile] {
        guard let data = defaults.data(forKey: key) else { return [] }
        do { return try JSONDecoder().decode([Profile].self, from: data) }
        catch { throw NuvioError.decoding("Profiles could not be read: \(error.localizedDescription)") }
    }

    public func activeProfile() throws -> Profile? {
        let profiles = try profiles()
        guard let id = defaults.string(forKey: activeKey) else { return profiles.first }
        return profiles.first(where: { $0.id.rawValue == id }) ?? profiles.first
    }

    public func select(profileID: NuvioID) throws {
        guard try profiles().contains(where: { $0.id == profileID }) else { throw NuvioError.notFound }
        defaults.set(profileID.rawValue, forKey: activeKey)
    }

    public func save(_ profile: Profile) throws {
        var values = try profiles()
        if let index = values.firstIndex(where: { $0.id == profile.id }) { values[index] = profile } else { values.append(profile) }
        defaults.set(try JSONEncoder().encode(values), forKey: key)
        if defaults.string(forKey: activeKey) == nil { defaults.set(profile.id.rawValue, forKey: activeKey) }
    }
}

public final class DefaultProgressStore: ProgressStore, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key = "nuvio.rewrite.progress.v1"

    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    public func progress(for id: NuvioID, profileID: NuvioID) throws -> WatchProgress? {
        try allProgress(profileID: profileID).first(where: { $0.id == id })
    }

    public func allProgress(profileID: NuvioID) throws -> [WatchProgress] {
        guard let data = defaults.data(forKey: key) else { return [] }
        let all = try JSONDecoder().decode([WatchProgress].self, from: data)
        return all.filter { $0.profileID == profileID }.sorted { $0.updatedAt > $1.updatedAt }
    }

    public func save(_ progress: WatchProgress) throws {
        var values = defaults.data(forKey: key).flatMap { try? JSONDecoder().decode([WatchProgress].self, from: $0) } ?? []
        values.removeAll { $0.id == progress.id && $0.profileID == progress.profileID }
        values.append(progress)
        defaults.set(try JSONEncoder().encode(values), forKey: key)
    }

    public func remove(id: NuvioID, profileID: NuvioID) throws {
        var values = defaults.data(forKey: key).flatMap { try? JSONDecoder().decode([WatchProgress].self, from: $0) } ?? []
        values.removeAll { $0.id == id && $0.profileID == profileID }
        defaults.set(try JSONEncoder().encode(values), forKey: key)
    }
}

public final class DefaultLibraryStore: LibraryStore, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key = "nuvio.rewrite.library.v1"

    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    public func items(profileID: NuvioID) throws -> [SavedMedia] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return try JSONDecoder().decode([SavedMedia].self, from: data).filter { $0.profileID == profileID }
    }

    public func contains(id: NuvioID, profileID: NuvioID) throws -> Bool { try items(profileID: profileID).contains { $0.media.id == id } }

    public func setSaved(_ media: MediaSummary, profileID: NuvioID, saved: Bool) throws {
        var values = defaults.data(forKey: key).flatMap { try? JSONDecoder().decode([SavedMedia].self, from: $0) } ?? []
        values.removeAll { $0.media.id == media.id && $0.profileID == profileID }
        if saved { values.append(.init(id: media.id, profileID: profileID, media: media)) }
        defaults.set(try JSONEncoder().encode(values), forKey: key)
    }
}
