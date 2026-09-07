import Testing
import AetherLibavcodec
@testable import AetherEngine

@Suite("dav1d decode tuning policy")
struct Dav1dDecodeTuningPolicyTests {
    @Test("4K AV1 VOD uses the device-tested six-frame policy")
    func tunes4KAV1VOD() {
        let tuning = Dav1dDecodeTuningPolicy.tuning(
            codecID: AV_CODEC_ID_AV1,
            width: 3840,
            height: 2160,
            isLive: false,
            availableThreadCount: 8
        )
        #expect(tuning.threadCount == 6)
        #expect(tuning.maximumFrameDelay == 6)
    }

    @Test("frame delay does not exceed available decode threads")
    func capsDelayToAvailableThreads() {
        let tuning = Dav1dDecodeTuningPolicy.tuning(
            codecID: AV_CODEC_ID_AV1,
            width: 3840,
            height: 2160,
            isLive: false,
            availableThreadCount: 4
        )
        #expect(tuning.threadCount == 4)
        #expect(tuning.maximumFrameDelay == 4)
    }

    @Test("live and lower-resolution AV1 retain defaults")
    func excludesLiveAndLowerResolution() {
        let live = Dav1dDecodeTuningPolicy.tuning(
            codecID: AV_CODEC_ID_AV1,
            width: 3840,
            height: 2160,
            isLive: true,
            availableThreadCount: 8
        )
        let hd = Dav1dDecodeTuningPolicy.tuning(
            codecID: AV_CODEC_ID_AV1,
            width: 1920,
            height: 1080,
            isLive: false,
            availableThreadCount: 8
        )
        #expect(live == Dav1dDecodeTuning(threadCount: 8, maximumFrameDelay: nil))
        #expect(hd == Dav1dDecodeTuning(threadCount: 8, maximumFrameDelay: nil))
    }

    @Test("other codecs and 8K retain defaults")
    func excludesOtherCodecsAnd8K() {
        let hevc = Dav1dDecodeTuningPolicy.tuning(
            codecID: AV_CODEC_ID_HEVC,
            width: 3840,
            height: 2160,
            isLive: false,
            availableThreadCount: 8
        )
        let eightK = Dav1dDecodeTuningPolicy.tuning(
            codecID: AV_CODEC_ID_AV1,
            width: 7680,
            height: 4320,
            isLive: false,
            availableThreadCount: 8
        )
        #expect(hevc.maximumFrameDelay == nil)
        #expect(eightK.maximumFrameDelay == nil)
    }
}
