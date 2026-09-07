import XCTest
@testable import NuvioTV

final class ExternalSubtitleFileCacheTests: XCTestCase {
    func testInfersExtensionFromContentDisposition() {
        let ext = ExternalSubtitleFormat.extensionFromContentDisposition(
            "attachment; filename=\"movie.en.srt\""
        )
        XCTAssertEqual(ext, "srt")
    }

    func testInfersExtensionFromContentType() {
        XCTAssertEqual(
            ExternalSubtitleFormat.extensionFromContentType("application/x-subrip; charset=utf-8"),
            "srt"
        )
        XCTAssertEqual(
            ExternalSubtitleFormat.extensionFromContentType("text/vtt"),
            "vtt"
        )
    }

    func testSniffsSRTWithoutExtension() {
        let data = Data("1\n00:00:01,000 --> 00:00:02,000\nHello\n".utf8)
        XCTAssertEqual(ExternalSubtitleFormat.sniffExtension(from: data), "srt")
        XCTAssertTrue(ExternalSubtitleFormat.looksLikeSubtitleText(data))
    }

    func testDetectsZipMagic() {
        XCTAssertTrue(ExternalSubtitleFormat.isZip(Data([0x50, 0x4b, 0x03, 0x04, 0x00])))
        XCTAssertFalse(ExternalSubtitleFormat.isZip(Data("1\n00:00:01,000 --> 00:00:02,000\n".utf8)))
    }

    func testEngineURLPrefersPlaybackURL() {
        var subtitle = NuvioSubtitle(
            url: "https://subs.example/file/1",
            language: "en",
            label: "English",
            source: "OpenSubtitles"
        )
        XCTAssertEqual(subtitle.engineURL, subtitle.url)
        subtitle.playbackURL = "file:///tmp/en.srt"
        subtitle.formatHint = "srt"
        XCTAssertEqual(subtitle.engineURL, "file:///tmp/en.srt")
        XCTAssertEqual(subtitle.url, "https://subs.example/file/1")
    }

    func testPayloadUsesContentTypeWhenPathHasNoExtension() throws {
        let data = Data("1\n00:00:01,000 --> 00:00:02,000\nHello\n".utf8)
        let url = try XCTUnwrap(URL(string: "https://subs5.strem.io/en/download/file/36919"))
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: [
                "Content-Type": "application/x-subrip; charset=utf-8",
                "Content-Disposition": "attachment; filename=\"movie.srt\""
            ]
        )!
        let payload = try XCTUnwrap(
            ExternalSubtitleFormat.payload(data: data, response: response, sourceURL: url)
        )
        XCTAssertEqual(payload.fileExtension, "srt")
    }
}
