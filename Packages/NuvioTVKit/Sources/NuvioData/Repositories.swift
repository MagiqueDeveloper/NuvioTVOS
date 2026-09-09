import Foundation
import NuvioDomain

public final actor MemoryCatalogRepository: CatalogRepository, MetadataRepository, StreamRepository {
    private var sections: [CatalogSection]

    public init(sections: [CatalogSection] = SampleCatalog.sections) { self.sections = sections }

    public func home() async throws -> CatalogPage { CatalogPage(sections: sections) }

    public func discover(query: String) async throws -> [MediaSummary] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return sections.flatMap(\.items) }
        return sections.flatMap(\.items).filter { $0.title.lowercased().contains(query) }
    }

    public func search(query: String) async throws -> [MediaSummary] { try await discover(query: query) }

    public func details(for id: NuvioID, type: MediaType) async throws -> MediaSummary {
        guard let item = sections.flatMap(\.items).first(where: { $0.id == id }) else { throw NuvioError.notFound }
        return item
    }

    public func streams(for title: MediaSummary) async throws -> [MediaStream] {
        guard let url = URL(string: "https://demo.invalid/\(title.id.rawValue).m3u8") else { throw NuvioError.invalidResponse }
        return [MediaStream(id: NuvioID(rawValue: "\(title.id.rawValue)-default"), title: "Auto", url: url)]
    }
}

public enum SampleCatalog {
    public static let sections: [CatalogSection] = [
        CatalogSection(id: "continue", title: "Continue Watching", items: [
            MediaSummary(id: "sample-1", type: .movie, title: "The Long Way Home", subtitle: "Resume watching", overview: "A sample title used until a catalog adapter is configured.", year: 2025, rating: 8.1),
            MediaSummary(id: "sample-2", type: .series, title: "Night Signal", subtitle: "Season 1", overview: "A serialized mystery built for the first vertical slice.", year: 2024, rating: 8.4)
        ]),
        CatalogSection(id: "popular", title: "Popular", items: [
            MediaSummary(id: "sample-3", type: .movie, title: "Orbit Fall", year: 2023, rating: 7.9),
            MediaSummary(id: "sample-4", type: .series, title: "North Shore", year: 2022, rating: 8.0),
            MediaSummary(id: "sample-5", type: .movie, title: "Signal Fire", year: 2021, rating: 7.6),
            MediaSummary(id: "sample-6", type: .series, title: "Afterlight", year: 2020, rating: 7.8)
        ])
    ]
}
