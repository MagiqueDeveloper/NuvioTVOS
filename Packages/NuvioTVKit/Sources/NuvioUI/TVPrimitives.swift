import SwiftUI
import NuvioDomain

public struct ArtworkView: View {
    private let url: URL?
    private let aspect: CGFloat

    public init(url: URL?, aspect: CGFloat = 2 / 3) { self.url = url; self.aspect = aspect }

    public var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image): image.resizable().scaledToFill()
            default: RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.08)).overlay { Image(systemName: "film").font(.largeTitle).foregroundStyle(.secondary) }
            }
        }
        .aspectRatio(aspect, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

public struct PosterCard: View {
    private let media: MediaSummary
    private let action: () -> Void

    public init(media: MediaSummary, action: @escaping () -> Void) { self.media = media; self.action = action }

    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                ArtworkView(url: media.artwork.poster)
                Text(media.title).font(.headline).lineLimit(1)
                if let subtitle = media.subtitle { Text(subtitle).font(.subheadline).foregroundStyle(.secondary).lineLimit(1) }
            }
        }
        .buttonStyle(.card)
    }
}

public struct MediaRow: View {
    private let section: CatalogSection
    private let action: (MediaSummary) -> Void

    public init(section: CatalogSection, action: @escaping (MediaSummary) -> Void) { self.section = section; self.action = action }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(section.title).font(.title2.bold())
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 28) {
                    ForEach(section.items) { item in PosterCard(media: item) { action(item) }.id(item.id) }
                }
            }
        }
    }
}

public struct GlassSurface<Content: View>: View {
    private let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View { content.padding(28).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24)) }
}

public struct LoadingStateView: View {
    private let title: String
    public init(_ title: String = "Loading…") { self.title = title }
    public var body: some View { VStack(spacing: 18) { ProgressView(); Text(title).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, maxHeight: .infinity) }
}

public struct ErrorStateView: View {
    private let message: String
    private let retry: (() -> Void)?
    public init(message: String, retry: (() -> Void)? = nil) { self.message = message; self.retry = retry }
    public var body: some View { VStack(spacing: 18) { Image(systemName: "exclamationmark.triangle").font(.largeTitle); Text(message); if let retry { Button("Retry", action: retry) } }.frame(maxWidth: .infinity, maxHeight: .infinity) }
}
