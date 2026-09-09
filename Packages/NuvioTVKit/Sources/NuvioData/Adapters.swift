import Foundation
import NuvioDomain

// MARK: - Adapters for fork/main Domain Models

/// Adapters bridge fork/main's rich models (StremioMeta, NuvioStream, NuvioCatalog)
/// to nuviocinema's clean domain types (MediaSummary, MediaStream, CatalogPage).
///
/// This allows us to port fork/main implementations without changing nuviocinema's
/// architecture, and makes it easy to swap backends later.

// MARK: - Stremio Meta Adapter

/// Lightweight metadata from Stremio addons (matches fork/main DomainModels.swift)
public struct StremioMeta: Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let contentType: String  // "movie", "series", "episode"
    public let poster: String?
    public let background: String?
    public let logo: String?
    public let description: String?
    public let releaseInfo: String?
    public let imdbRating: String?
    public let year: Int32?
    public let genres: [String]?
    public let runtime: String?
    
    public init(
        id: String,
        name: String,
        contentType: String,
        poster: String? = nil,
        background: String? = nil,
        logo: String? = nil,
        description: String? = nil,
        releaseInfo: String? = nil,
        imdbRating: String? = nil,
        year: Int32? = nil,
        genres: [String]? = nil,
        runtime: String? = nil
    ) {
        self.id = id
        self.name = name
        self.contentType = contentType
        self.poster = poster
        self.background = background
        self.logo = logo
        self.description = description
        self.releaseInfo = releaseInfo
        self.imdbRating = imdbRating
        self.year = year
        self.genres = genres
        self.runtime = runtime
    }
}

public struct StremioMetaAdapter {
    /// Convert StremioMeta to MediaSummary
    public static func adapt(_ meta: StremioMeta) -> MediaSummary {
        let type: MediaType = {
            switch meta.contentType.lowercased() {
            case "movie": return .movie
            case "series": return .series
            case "episode": return .episode
            default: return .movie
            }
        }()
        
        let artwork = Artwork(
            poster: meta.poster.flatMap { URL(string: $0) },
            backdrop: meta.background.flatMap { URL(string: $0) },
            logo: meta.logo.flatMap { URL(string: $0) }
        )
        
        let rating = meta.imdbRating.flatMap { Double($0) }
        
        let runtime = meta.runtime.flatMap { runtimeString in
            // Parse "120 min" or "2h 30m" format
            let digits = runtimeString.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            return Int(digits)
        }
        
        return MediaSummary(
            id: NuvioID(rawValue: meta.id),
            type: type,
            title: meta.name,
            subtitle: meta.releaseInfo,
            overview: meta.description,
            year: meta.year.map { Int($0) },
            artwork: artwork,
            rating: rating,
            genres: meta.genres,
            cast: nil,  // Enriched separately via TMDB
            crew: nil,
            runtime: runtime,
            trailers: nil,
            imdbID: meta.id.hasPrefix("tt") ? meta.id : nil,
            tmdbID: nil,
            episodeCount: nil,
            seasonCount: nil
        )
    }
}

// MARK: - Nuvio Stream Adapter

/// Stream from Stremio addons (matches fork/main PlayerModels.swift)
public struct NuvioStream: Codable, Hashable, Sendable {
    public let url: String
    public let title: String?
    public let description: String?
    public let behaviorHints: BehaviorHints?
    
    public struct BehaviorHints: Codable, Hashable, Sendable {
        public let headers: [String: String]?
        public let videoHash: String?
        public let videoSize: Int64?
        
        public init(headers: [String: String]? = nil, videoHash: String? = nil, videoSize: Int64? = nil) {
            self.headers = headers
            self.videoHash = videoHash
            self.videoSize = videoSize
        }
    }
    
    public init(url: String, title: String? = nil, description: String? = nil, behaviorHints: BehaviorHints? = nil) {
        self.url = url
        self.title = title
        self.description = description
        self.behaviorHints = behaviorHints
    }
}

public struct StreamAdapter {
    /// Convert NuvioStream to MediaStream
    public static func adapt(_ stream: NuvioStream, streamID: String? = nil) -> MediaStream? {
        guard let url = URL(string: stream.url) else { return nil }
        
        let headers = stream.behaviorHints?.headers ?? [:]
        
        // Use stream description or title, fallback to URL
        let title = stream.title ?? stream.description ?? url.lastPathComponent
        
        // Generate ID from URL hash or use provided ID
        let id = streamID.map { NuvioID(rawValue: $0) } ?? NuvioID(rawValue: stream.url.hash.description)
        
        return MediaStream(
            id: id,
            title: title,
            url: url,
            headers: headers,
            tracks: []  // Discovered during playback
        )
    }
}

// MARK: - Nuvio Catalog Adapter

/// Catalog from Stremio addons (matches fork/main CatalogModels.swift)
public struct NuvioCatalog: Codable, Hashable, Sendable {
    public let id: String
    public let type: String
    public let name: String
    public let metas: [StremioMeta]
    
    public init(id: String, type: String, name: String, metas: [StremioMeta]) {
        self.id = id
        self.type = type
        self.name = name
        self.metas = metas
    }
}

public struct CatalogAdapter {
    /// Convert array of NuvioCatalog to CatalogPage
    public static func adapt(_ catalogs: [NuvioCatalog]) -> CatalogPage {
        let sections = catalogs.map { catalog in
            CatalogSection(
                id: NuvioID(rawValue: catalog.id),
                title: catalog.name,
                items: catalog.metas.map { StremioMetaAdapter.adapt($0) }
            )
        }
        
        return CatalogPage(sections: sections, hasNextPage: false)
    }
}
