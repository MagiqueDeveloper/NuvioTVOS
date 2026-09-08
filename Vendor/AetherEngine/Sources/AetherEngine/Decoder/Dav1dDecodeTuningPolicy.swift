import Foundation
import AetherLibavcodec

struct Dav1dDecodeTuning: Equatable, Sendable {
    let threadCount: Int
    let maximumFrameDelay: Int?
}

/// Physical Apple TV testing showed that 4K AV1 VOD needs enough dav1d frame
/// parallelism to stay ahead of a 23.976 fps presentation clock. Keep this
/// deliberately narrow: latency-sensitive live playback and other sizes retain
/// libavcodec's normal scheduling.
enum Dav1dDecodeTuningPolicy {
    static let tunedThreadCount = 6
    static let maximumFrameDelay = 6

    static func tuning(
        codecID: AVCodecID,
        width: Int32,
        height: Int32,
        isLive: Bool,
        availableThreadCount: Int
    ) -> Dav1dDecodeTuning {
        let defaultThreads = max(1, availableThreadCount)
        guard codecID == AV_CODEC_ID_AV1,
              !isLive,
              width > 0,
              height > 0 else {
            return Dav1dDecodeTuning(threadCount: defaultThreads, maximumFrameDelay: nil)
        }

        let pixels = Int64(width) * Int64(height)
        let minimum4KPixels = Int64(3840) * 2160
        let maximum4KPixels = Int64(4096) * 2304
        guard pixels >= minimum4KPixels, pixels <= maximum4KPixels else {
            return Dav1dDecodeTuning(threadCount: defaultThreads, maximumFrameDelay: nil)
        }

        let resolvedThreads = min(defaultThreads, tunedThreadCount)
        return Dav1dDecodeTuning(
            threadCount: resolvedThreads,
            maximumFrameDelay: min(maximumFrameDelay, resolvedThreads)
        )
    }
}
