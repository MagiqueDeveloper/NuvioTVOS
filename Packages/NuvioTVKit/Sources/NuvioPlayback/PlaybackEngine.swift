import Foundation
import SwiftUI
import NuvioDomain

@MainActor
public protocol PlaybackEngine: AnyObject {
    var state: PlaybackState { get }
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }
    var tracks: [StreamTrack] { get }

    func surface() -> AnyView
    func load(_ request: PlaybackRequest) async
    func play()
    func pause()
    func seek(to seconds: TimeInterval) async
    func select(track: StreamTrack)
    func stop()
}
