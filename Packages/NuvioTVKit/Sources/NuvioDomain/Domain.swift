import Foundation

public struct NuvioID: RawRepresentable, Hashable, Codable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

public enum MediaType: String, Codable, CaseIterable, Sendable {
    case movie
    case series
    case episode
}

public struct Artwork: Codable, Hashable, Sendable {
    public let poster: URL?
    public let backdrop: URL?
    public let logo: URL?

    public init(poster: URL? = nil, backdrop: URL? = nil, logo: URL? = nil) {
        self.poster = poster
        self.backdrop = backdrop
        self.logo = logo
    }
}

public struct MediaSummary: Identifiable, Codable, Hashable, Sendable {
    public let id: NuvioID
    public let type: MediaType
    public let title: String
    public let subtitle: String?
    public let overview: String?
    public let year: Int?
    public let artwork: Artwork
    public let rating: Double?

    public init(
        id: NuvioID,
        type: MediaType,
        title: String,
        subtitle: String? = nil,
        overview: String? = nil,
        year: Int? = nil,
        artwork: Artwork = Artwork(),
        rating: Double? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.overview = overview
        self.year = year
        self.artwork = artwork
        self.rating = rating
    }
}

public struct Episode: Identifiable, Codable, Hashable, Sendable {
    public let id: NuvioID
    public let seriesID: NuvioID
    public let season: Int
    public let number: Int
    public let title: String
    public let overview: String?
    public let artwork: Artwork

    public init(id: NuvioID, seriesID: NuvioID, season: Int, number: Int, title: String, overview: String? = nil, artwork: Artwork = Artwork()) {
        self.id = id
        self.seriesID = seriesID
        self.season = season
        self.number = number
        self.title = title
        self.overview = overview
        self.artwork = artwork
    }
}

public struct CatalogSection: Identifiable, Codable, Hashable, Sendable {
    public let id: NuvioID
    public let title: String
    public let items: [MediaSummary]

    public init(id: NuvioID, title: String, items: [MediaSummary]) {
        self.id = id
        self.title = title
        self.items = items
    }
}

public struct CatalogPage: Codable, Sendable {
    public let sections: [CatalogSection]
    public let hasNextPage: Bool

    public init(sections: [CatalogSection], hasNextPage: Bool = false) {
        self.sections = sections
        self.hasNextPage = hasNextPage
    }
}

public struct StreamTrack: Identifiable, Codable, Hashable, Sendable {
    public enum Kind: String, Codable, Sendable { case audio, subtitle }

    public let id: String
    public let kind: Kind
    public let label: String
    public let language: String?
    public let isDefault: Bool

    public init(id: String, kind: Kind, label: String, language: String? = nil, isDefault: Bool = false) {
        self.id = id
        self.kind = kind
        self.label = label
        self.language = language
        self.isDefault = isDefault
    }
}

public struct MediaStream: Identifiable, Codable, Hashable, Sendable {
    public let id: NuvioID
    public let title: String
    public let url: URL
    public let headers: [String: String]
    public let tracks: [StreamTrack]

    public init(id: NuvioID, title: String, url: URL, headers: [String: String] = [:], tracks: [StreamTrack] = []) {
        self.id = id
        self.title = title
        self.url = url
        self.headers = headers
        self.tracks = tracks
    }
}

public struct PlaybackRequest: Identifiable, Codable, Sendable {
    public let stream: MediaStream
    public let title: MediaSummary
    public let resumePosition: TimeInterval?

    public var id: NuvioID { stream.id }

    public init(stream: MediaStream, title: MediaSummary, resumePosition: TimeInterval? = nil) {
        self.stream = stream
        self.title = title
        self.resumePosition = resumePosition
    }
}

public enum PlaybackState: Equatable, Sendable {
    case idle
    case loading
    case playing
    case paused
    case ended
    case failed(String)
}

public enum NuvioError: Error, LocalizedError, Equatable, Sendable {
    case invalidResponse
    case transport(String)
    case decoding(String)
    case notFound
    case unavailable(String)
    case migration(String)
    case playback(String)

    public var errorDescription: String? {
        switch self {
        case .invalidResponse: return "The server returned an invalid response."
        case .transport(let message), .decoding(let message), .unavailable(let message), .migration(let message), .playback(let message): return message
        case .notFound: return "The requested title was not found."
        }
    }
}

public struct Profile: Identifiable, Codable, Hashable, Sendable {
    public let id: NuvioID
    public var name: String
    public var avatar: URL?
    public var isPINProtected: Bool

    public init(id: NuvioID, name: String, avatar: URL? = nil, isPINProtected: Bool = false) {
        self.id = id
        self.name = name
        self.avatar = avatar
        self.isPINProtected = isPINProtected
    }
}

public struct WatchProgress: Identifiable, Codable, Hashable, Sendable {
    public let id: NuvioID
    public let profileID: NuvioID
    public var position: TimeInterval
    public var duration: TimeInterval?
    public var updatedAt: Date

    public init(id: NuvioID, profileID: NuvioID, position: TimeInterval, duration: TimeInterval? = nil, updatedAt: Date = Date()) {
        self.id = id
        self.profileID = profileID
        self.position = max(0, position)
        self.duration = duration
        self.updatedAt = updatedAt
    }

    public var fraction: Double? {
        guard let duration, duration > 0 else { return nil }
        return min(1, max(0, position / duration))
    }
}

public struct SavedMedia: Identifiable, Codable, Hashable, Sendable {
    public let id: NuvioID
    public let profileID: NuvioID
    public let media: MediaSummary
    public let addedAt: Date

    public init(id: NuvioID, profileID: NuvioID, media: MediaSummary, addedAt: Date = Date()) {
        self.id = id
        self.profileID = profileID
        self.media = media
        self.addedAt = addedAt
    }
}

public struct DeepLink: Equatable, Sendable {
    public enum Destination: Equatable, Sendable { case title(NuvioID, MediaType); case continueWatching(NuvioID, MediaType) }
    public let destination: Destination

    public init(destination: Destination) { self.destination = destination }

    public init?(url: URL) {
        guard let scheme = url.scheme?.lowercased(), ["nuvio", "nuvio-tv", "com.nuvio.app.tv"].contains(scheme) else { return nil }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let id = components?.queryItems?.first(where: { $0.name == "id" })?.value
            ?? url.pathComponents.dropFirst().first
        guard let id, !id.isEmpty else { return nil }
        let rawType = components?.queryItems?.first(where: { $0.name == "type" })?.value?.lowercased() ?? "movie"
        let type = MediaType(rawValue: rawType) ?? .movie
        let isContinue = url.host?.lowercased() == "continue-watching"
        self.init(destination: isContinue ? .continueWatching(NuvioID(rawValue: id), type) : .title(NuvioID(rawValue: id), type))
    }

    public var url: URL? {
        var components = URLComponents()
        components.scheme = "nuvio-tv"
        switch destination {
        case let .title(id, type): components.host = "title"; components.queryItems = [.init(name: "id", value: id.rawValue), .init(name: "type", value: type.rawValue)]
        case let .continueWatching(id, type): components.host = "continue-watching"; components.queryItems = [.init(name: "id", value: id.rawValue), .init(name: "type", value: type.rawValue)]
        }
        return components.url
    }
}
