import Foundation
import Testing
@testable import AetherEngine

@Suite("software playback performance metrics")
struct SWPerformanceMetricsTests {
    @Test("delta subtracts cumulative counters")
    func delta() {
        let previous = SWPerformanceSnapshot(
            videoPacketCalls: 10, videoDecodeNanoseconds: 20, videoConversionNanoseconds: 30,
            videoFrames: 4, audioPacketCalls: 5, audioDecodeNanoseconds: 60, audioBuffers: 7
        )
        let current = SWPerformanceSnapshot(
            videoPacketCalls: 13, videoDecodeNanoseconds: 25, videoConversionNanoseconds: 38,
            videoFrames: 6, audioPacketCalls: 9, audioDecodeNanoseconds: 70, audioBuffers: 12
        )
        #expect(current.delta(since: previous) == SWPerformanceSnapshot(
            videoPacketCalls: 3, videoDecodeNanoseconds: 5, videoConversionNanoseconds: 8,
            videoFrames: 2, audioPacketCalls: 4, audioDecodeNanoseconds: 10, audioBuffers: 5
        ))
    }

    @Test("counter reset starts a fresh interval")
    func reset() {
        let previous = SWPerformanceSnapshot(videoPacketCalls: 50, videoFrames: 40)
        let current = SWPerformanceSnapshot(videoPacketCalls: 2, videoFrames: 1)
        let delta = current.delta(since: previous)
        #expect(delta.videoPacketCalls == 2)
        #expect(delta.videoFrames == 1)
    }

    @Test("debug line reports rates and grain state")
    func formatting() {
        let snapshot = SWPerformanceSnapshot(
            videoPacketCalls: 24,
            videoDecodeNanoseconds: 60_000_000,
            videoConversionNanoseconds: 20_000_000,
            videoFrames: 24,
            audioPacketCalls: 10,
            audioDecodeNanoseconds: 5_000_000,
            audioBuffers: 8
        )
        let line = snapshot.debugLine(interval: 1, filmGrain: "on")
        #expect(line.contains("vdec=60.0ms/s"))
        #expect(line.contains("frames=24.0"))
        #expect(line.contains("grain=on"))
    }
}
