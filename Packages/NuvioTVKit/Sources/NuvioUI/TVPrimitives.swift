import SwiftUI
import NuvioDomain

// MARK: - Cinema Design System

/// Premium color palette for cinematic experiences
public struct CinemaColors {
    /// Accent color for tinting (use with .tint() modifier)
    public static let accent = Color(red: 0.4, green: 0.5, blue: 1.0)
    
    /// Status colors
    public static let success = Color.green
    public static let warning = Color.yellow
    public static let error = Color.red
}

/// Typography system optimized for tvOS 10-foot viewing
public extension Font {
    static let cinemaHeroTitle = Font.system(size: 52, weight: .bold)
    static let cinemaSectionHeader = Font.system(size: 38, weight: .semibold)
    static let cinemaContentTitle = Font.system(size: 29, weight: .medium)
    static let cinemaBody = Font.system(size: 25, weight: .regular)
    static let cinemaCaption = Font.system(size: 23, weight: .light)
}

// MARK: - Authentic Apple Liquid Glass Components

/// Premium glass card using native Apple materials
/// Matches the glass aesthetic from tvOS TV app and Music app
public struct GlassCard<Content: View>: View {
    private let content: Content
    private let cornerRadius: CGFloat
    
    public init(
        cornerRadius: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding(32)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            .compositingGroup()
            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
}

/// Interactive glass button with native tvOS focus behavior
/// Uses system button styles for authentic Apple feel
public struct GlassButton: View {
    private let title: String
    private let icon: String?
    private let style: ButtonStyleType
    private let action: () -> Void
    
    public enum ButtonStyleType {
        case primary
        case secondary
        case card
    }
    
    public init(_ title: String, icon: String? = nil, style: ButtonStyleType = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    public var body: some View {
        Group {
            switch style {
            case .primary:
                Button(action: action) {
                    buttonContent
                }
                .buttonStyle(.borderedProminent)
                
            case .secondary:
                Button(action: action) {
                    buttonContent
                }
                .buttonStyle(.bordered)
                
            case .card:
                #if os(tvOS)
                Button(action: action) {
                    buttonContent
                }
                .buttonStyle(.card)
                #else
                Button(action: action) {
                    buttonContent
                }
                .buttonStyle(.bordered)
                #endif
            }
        }
        #if os(tvOS)
        .buttonBorderShape(.roundedRectangle(radius: 12))
        .hoverEffect(.lift)
        #endif
        .tint(CinemaColors.accent)
    }
    
    private var buttonContent: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.title3.bold())
            }
            Text(title)
                .font(.cinemaBody.weight(.medium))
        }
        .padding(.horizontal, 36)
        .padding(.vertical, 18)
    }
}

/// Modal and sheet backgrounds with native blur
/// Uses proper material hierarchy for authentic depth
public struct GlassOverlay<Content: View>: View {
    private let content: Content
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            content
                .padding(60)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28))
                .compositingGroup()
                .shadow(color: .black.opacity(0.3), radius: 40, y: 20)
        }
    }
}

/// Side panels with authentic glass material
public struct GlassPanel<Content: View>: View {
    private let content: Content
    private let width: CGFloat
    
    public init(width: CGFloat = 480, @ViewBuilder content: () -> Content) {
        self.width = width
        self.content = content()
    }
    
    public var body: some View {
        content
            .frame(width: width)
            .padding(40)
            .background(.regularMaterial)
            .compositingGroup()
            .shadow(color: .black.opacity(0.2), radius: 30, x: -10)
    }
}

/// Premium playback scrubber with native focus behavior
public struct GlassScrubber: View {
    @Binding private var progress: Double
    private let duration: TimeInterval
    @FocusState private var isFocused: Bool
    
    public init(progress: Binding<Double>, duration: TimeInterval) {
        self._progress = progress
        self.duration = duration
    }
    
    private var timeString: String {
        let current = Int(progress * duration)
        let total = Int(duration)
        return "\(formatTime(current)) / \(formatTime(total))"
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        return hours > 0 ? String(format: "%d:%02d:%02d", hours, minutes, secs) : String(format: "%d:%02d", minutes, secs)
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track background with native material
                    Capsule()
                        .fill(.quaternary)
                        .frame(height: 8)
                    
                    // Progress fill
                    Capsule()
                        .fill(CinemaColors.accent)
                        .frame(width: geometry.size.width * progress, height: 8)
                    
                    // Playhead
                    Circle()
                        .fill(.primary)
                        .frame(width: 20, height: 20)
                        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                        .offset(x: geometry.size.width * progress - 10)
                }
            }
            .frame(height: 20)
            .focusable()
            .focused($isFocused)
            
            Text(timeString)
                .font(.cinemaCaption)
                .foregroundStyle(.secondary)
        }
    }
}

/// Smooth loading and buffering indicator with native styling
public struct GlassProgressBar: View {
    private let progress: Double?
    
    public init(progress: Double? = nil) {
        self.progress = progress
    }
    
    public var body: some View {
        if let progress {
            ProgressView(value: progress)
                .tint(CinemaColors.accent)
                .frame(height: 6)
        } else {
            ProgressView()
                .tint(CinemaColors.accent)
                .frame(height: 6)
        }
    }
}

// MARK: - Enhanced Core Components

/// Enhanced artwork view with native loading states
public struct ArtworkView: View {
    private let url: URL?
    private let aspect: CGFloat
    private let cornerRadius: CGFloat
    
    public init(url: URL?, aspect: CGFloat = 2 / 3, cornerRadius: CGFloat = 12) {
        self.url = url
        self.aspect = aspect
        self.cornerRadius = cornerRadius
    }
    
    public var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure, .empty:
                placeholderContent
            @unknown default:
                placeholderContent
            }
        }
        .aspectRatio(aspect, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    private var placeholderContent: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.quaternary)
            .overlay {
                Image(systemName: "film")
                    .font(.largeTitle)
                    .foregroundStyle(.tertiary)
            }
    }
}

/// Enhanced poster card with native tvOS card button style
public struct PosterCard: View {
    private let media: MediaSummary
    private let showProgress: Bool
    private let progress: Double?
    private let action: () -> Void
    
    public init(
        media: MediaSummary,
        showProgress: Bool = false,
        progress: Double? = nil,
        action: @escaping () -> Void
    ) {
        self.media = media
        self.showProgress = showProgress
        self.progress = progress
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack(alignment: .bottom) {
                    ArtworkView(url: media.artwork.poster)
                    
                    // Progress indicator
                    if showProgress, let progress {
                        WatchProgressBar(progress: progress)
                            .padding(.horizontal, 8)
                            .padding(.bottom, 8)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(media.title)
                        .font(.cinemaBody.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    if let subtitle = media.subtitle {
                        Text(subtitle)
                            .font(.cinemaCaption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        #if os(tvOS)
        .buttonStyle(.card)
        .hoverEffect(.lift)
        #else
        .buttonStyle(.plain)
        #endif
    }
}

/// Enhanced media row with native scrolling
public struct MediaRow: View {
    private let section: CatalogSection
    private let showProgress: Bool
    private let action: (MediaSummary) -> Void
    
    public init(
        section: CatalogSection,
        showProgress: Bool = false,
        action: @escaping (MediaSummary) -> Void
    ) {
        self.section = section
        self.showProgress = showProgress
        self.action = action
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(section.title)
                .font(.cinemaSectionHeader)
                .foregroundStyle(.primary)
                .padding(.horizontal, 60)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 32) {
                    ForEach(section.items) { item in
                        PosterCard(
                            media: item,
                            showProgress: showProgress,
                            progress: nil
                        ) {
                            action(item)
                        }
                        .id(item.id)
                    }
                }
                .padding(.horizontal, 60)
                .padding(.vertical, 20)
            }
        }
    }
}

/// Basic glass surface (maintained for backward compatibility)
public struct GlassSurface<Content: View>: View {
    private let content: Content
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding(28)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
    }
}

/// Enhanced loading state with native progress view
public struct LoadingStateView: View {
    private let title: String
    
    public init(_ title: String = "Loading…") {
        self.title = title
    }
    
    public var body: some View {
        GlassCard {
            VStack(spacing: 24) {
                ProgressView()
                    .tint(CinemaColors.accent)
                    .scaleEffect(1.5)
                
                Text(title)
                    .font(.cinemaBody)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Enhanced error state with native styling
public struct ErrorStateView: View {
    private let message: String
    private let retry: (() -> Void)?
    
    public init(message: String, retry: (() -> Void)? = nil) {
        self.message = message
        self.retry = retry
    }
    
    public var body: some View {
        GlassCard {
            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .fill(CinemaColors.error.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(CinemaColors.error)
                }
                
                VStack(spacing: 12) {
                    Text("Something Went Wrong")
                        .font(.cinemaContentTitle.bold())
                        .foregroundStyle(.primary)
                    
                    Text(message)
                        .font(.cinemaBody)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
                
                if let retry {
                    GlassButton("Try Again", icon: "arrow.clockwise", action: retry)
                }
            }
        }
        .frame(maxWidth: 600)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Premium Cinema Components

/// Full-width cinematic hero with native materials
public struct CinematicHero: View {
    private let backdropURL: URL?
    private let logoURL: URL?
    private let title: String
    private let metadata: String
    private let overview: String
    private let action: () -> Void
    
    public init(
        backdropURL: URL?,
        logoURL: URL? = nil,
        title: String,
        metadata: String,
        overview: String,
        action: @escaping () -> Void
    ) {
        self.backdropURL = backdropURL
        self.logoURL = logoURL
        self.title = title
        self.metadata = metadata
        self.overview = overview
        self.action = action
    }
    
    public var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Backdrop image
            if let backdropURL {
                AsyncImage(url: backdropURL) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                    }
                }
            }
            
            // Gradient overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.6), .black.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Content
            VStack(alignment: .leading, spacing: 24) {
                if let logoURL {
                    AsyncImage(url: logoURL) { phase in
                        if case .success(let image) = phase {
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(height: 120)
                        }
                    }
                } else {
                    Text(title)
                        .font(.cinemaHeroTitle)
                        .foregroundStyle(.primary)
                }
                
                Text(metadata)
                    .font(.cinemaBody)
                    .foregroundStyle(.secondary)
                
                Text(overview)
                    .font(.cinemaBody)
                    .foregroundStyle(.tertiary)
                    .lineLimit(3)
                    .frame(maxWidth: 900, alignment: .leading)
                
                GlassButton("Play", icon: "play.fill", style: .primary, action: action)
            }
            .padding(60)
        }
        .frame(height: 700)
        .clipped()
    }
}

/// Season and episode grid with native card styling
public struct EpisodeGrid: View {
    private let episodes: [MediaSummary]
    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 28), count: 4)
    private let action: (MediaSummary) -> Void
    
    public init(episodes: [MediaSummary], action: @escaping (MediaSummary) -> Void) {
        self.episodes = episodes
        self.action = action
    }
    
    public var body: some View {
        LazyVGrid(columns: columns, spacing: 28) {
            ForEach(episodes) { episode in
                Button {
                    action(episode)
                } label: {
                    EpisodeCard(episode: episode)
                }
                #if os(tvOS)
                .buttonStyle(.card)
                .hoverEffect(.lift)
                #else
                .buttonStyle(.plain)
                #endif
            }
        }
    }
}

private struct EpisodeCard: View {
    let episode: MediaSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ArtworkView(url: episode.artwork.backdrop, aspect: 16 / 9, cornerRadius: 16)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(episode.title)
                    .font(.cinemaBody.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                if let subtitle = episode.subtitle {
                    Text(subtitle)
                        .font(.cinemaCaption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }
}

/// Horizontal cast carousel with native focus
public struct CastCarousel: View {
    private let castMembers: [(name: String, role: String, imageURL: URL?)]
    
    public init(castMembers: [(name: String, role: String, imageURL: URL?)]) {
        self.castMembers = castMembers
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Cast & Crew")
                .font(.cinemaSectionHeader)
                .foregroundStyle(.primary)
                .padding(.horizontal, 60)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 32) {
                    ForEach(castMembers.indices, id: \.self) { index in
                        Button {
                            // Cast member action
                        } label: {
                            CastMemberCard(
                                name: castMembers[index].name,
                                role: castMembers[index].role,
                                imageURL: castMembers[index].imageURL
                            )
                        }
                        #if os(tvOS)
                        .buttonStyle(.card)
                        .hoverEffect(.lift)
                        #else
                        .buttonStyle(.plain)
                        #endif
                    }
                }
                .padding(.horizontal, 60)
                .padding(.vertical, 20)
            }
        }
    }
}

private struct CastMemberCard: View {
    let name: String
    let role: String
    let imageURL: URL?
    
    var body: some View {
        VStack(spacing: 16) {
            AsyncImage(url: imageURL) { phase in
                if case .success(let image) = phase {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    Circle()
                        .fill(.quaternary)
                        .overlay {
                            Image(systemName: "person.fill")
                                .font(.title)
                                .foregroundStyle(.tertiary)
                        }
                }
            }
            .frame(width: 140, height: 140)
            .clipShape(Circle())
            
            VStack(spacing: 4) {
                Text(name)
                    .font(.cinemaBody.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text(role)
                    .font(.cinemaCaption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 140)
        }
    }
}

/// Glass pill badge for quality indicators (4K, HDR, etc.)
public struct StreamQualityBadge: View {
    private let label: String
    private let color: Color
    
    public init(_ label: String, color: Color = .blue) {
        self.label = label
        self.color = color
    }
    
    public var body: some View {
        Text(label)
            .font(.cinemaCaption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.regularMaterial, in: Capsule())
            .tint(color)
    }
}

/// Subtle progress indicator for poster cards
public struct WatchProgressBar: View {
    private let progress: Double
    
    public init(progress: Double) {
        self.progress = progress
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)
                    .frame(height: 4)
                
                Capsule()
                    .fill(CinemaColors.accent)
                    .frame(width: geometry.size.width * progress, height: 4)
            }
        }
        .frame(height: 4)
    }
}

/// Premium tab bar with native focus behavior
public struct FocusableTab: View {
    private let title: String
    private let icon: String
    private let action: () -> Void
    
    public init(_ title: String, icon: String, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                
                Text(title)
                    .font(.cinemaBody)
            }
            .frame(width: 160)
            .padding(.vertical, 20)
        }
        .buttonStyle(.bordered)
        #if os(tvOS)
        .buttonBorderShape(.roundedRectangle(radius: 12))
        .hoverEffect(.lift)
        #endif
        .tint(CinemaColors.accent)
    }
}
