import Foundation
import SwiftUI
import Combine
import class AetherEngine.AetherEngine
import enum AetherEngine.PlaybackState
import struct AetherEngine.TrackInfo
import struct AetherEngine.AetherPlayerSurface
import struct AetherEngine.LoadOptions
import NuvioDomain

/// The only AetherEngine seam in the app. Features receive PlaybackEngine and
/// never need to learn Aether's state, view, or track types.
@MainActor
public final class AetherPlaybackEngine: PlaybackEngine, ObservableObject {
    private let engine: AetherEngine
    private var stateSubscription: AnyCancellable?
    private var trackSubscription: AnyCancellable?
    private var request: PlaybackRequest?

    @Published public private(set) var state: NuvioDomain.PlaybackState = .idle
    @Published public private(set) var currentTime: TimeInterval = 0
    @Published public private(set) var duration: TimeInterval = 0
    @Published public private(set) var tracks: [StreamTrack] = []

    public init() throws {
        engine = try AetherEngine()
        stateSubscription = engine.$state.sink { [weak self] value in self?.state = Self.map(value) }
        trackSubscription = engine.$audioTracks.combineLatest(engine.$subtitleTracks).sink { [weak self] audio, subtitles in
            self?.tracks = audio.map { Self.map($0, kind: .audio) } + subtitles.map { Self.map($0, kind: .subtitle) }
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
            _ = try await engine.load(url: request.stream.url, startPosition: request.resumePosition, options: options)
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
        await engine.seek(to: max(0, seconds))
        currentTime = engine.currentTime
    }

    public func select(track: StreamTrack) {
        guard let id = Int(track.id) else { return }
        switch track.kind {
        case .audio: engine.selectAudioTrack(index: id)
        case .subtitle: engine.selectSubtitleTrack(index: id)
        }
    }

    public func stop() {
        engine.stop()
        request = nil
        currentTime = 0
        duration = 0
        tracks = []
    }

    private static func map(_ state: PlaybackState) -> NuvioDomain.PlaybackState {
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

    private static func map(_ track: TrackInfo, kind: StreamTrack.Kind) -> StreamTrack {
        StreamTrack(id: String(track.id), kind: kind, label: track.name.isEmpty ? (track.language ?? "Unknown") : track.name, language: track.language, isDefault: track.isDefault)
    }
}

@MainActor
private final class UnavailablePlaybackEngine: PlaybackEngine {
    var state: NuvioDomain.PlaybackState = .failed("Aether playback is unavailable on this build.")
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var tracks: [StreamTrack] = []

    func surface() -> AnyView { AnyView(Color.black) }
    func load(_ request: PlaybackRequest) async {}
    func play() {}
    func pause() {}
    func seek(to seconds: TimeInterval) async {}
    func select(track: StreamTrack) {}
    func stop() {}
}
