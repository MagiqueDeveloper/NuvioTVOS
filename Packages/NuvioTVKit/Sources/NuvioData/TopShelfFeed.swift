import Foundation

public let topShelfAppGroupID: String = {
    let bundleID = Bundle.main.bundleIdentifier ?? "com.pyksel.nuviotvos"
    let appID = bundleID.hasSuffix(".TopShelf") ? String(bundleID.dropLast(".TopShelf".count)) : bundleID
    return "group.\(appID)"
}()

public struct TopShelfEntry: Codable, Equatable, Sendable {
    public let contentId: String
    public let contentType: String
    public let title: String
    public let subtitle: String?
    public let imageURL: String?
    public let artworkFileName: String?
    public let progress: Double?

    public init(contentId: String, contentType: String, title: String, subtitle: String? = nil, imageURL: String? = nil, progress: Double? = nil, artworkFileName: String? = nil) {
        self.contentId = contentId; self.contentType = contentType; self.title = title; self.subtitle = subtitle; self.imageURL = imageURL; self.progress = progress; self.artworkFileName = artworkFileName
    }

    public var deepLinkURL: URL? {
        var components = URLComponents(); components.scheme = "nuvio-tv"; components.host = "continue-watching"
        components.queryItems = [.init(name: "id", value: contentId), .init(name: "type", value: contentType)]
        return components.url
    }
}

public struct TopShelfFeed: Codable, Equatable, Sendable {
    public let entries: [TopShelfEntry]
    public let updatedAt: Date
    public init(entries: [TopShelfEntry], updatedAt: Date = Date()) { self.entries = entries; self.updatedAt = updatedAt }
}

public enum TopShelfFeedStore {
    private static let key = "nuvio.tv.topShelf.feed"
    private static var defaults: UserDefaults? { UserDefaults(suiteName: topShelfAppGroupID) }

    public static func write(_ entries: [TopShelfEntry]) {
        guard let data = try? JSONEncoder().encode(TopShelfFeed(entries: entries)) else { return }
        defaults?.set(data, forKey: key)
    }

    public static func read() -> TopShelfFeed? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(TopShelfFeed.self, from: data)
    }

    public static func artworkURL(for entry: TopShelfEntry) -> URL? {
        guard let filename = entry.artworkFileName, let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: topShelfAppGroupID) else { return nil }
        let url = container.appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
}
