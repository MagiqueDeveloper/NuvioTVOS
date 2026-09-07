import XCTest
@testable import NuvioTV

final class DebridStreamPresentationTests: XCTestCase {
    private var testStore: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "test.debrid.presentation.\(UUID().uuidString)"
        testStore = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() {
        testStore.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testProviderKindShortNames() {
        XCTAssertEqual(DebridProviderKind.torbox.shortName, "TB")
        XCTAssertEqual(DebridProviderKind.realDebrid.shortName, "RD")
        XCTAssertEqual(DebridProviderKind.premiumize.shortName, "PM")
        XCTAssertEqual(DebridProviderKind.allDebrid.shortName, "AD")
        XCTAssertEqual(DebridProviderKind.debridLink.shortName, "DL")
        XCTAssertEqual(DebridProviderKind.none.shortName, "")
    }

    func testPassesThroughWhenDebridDisabled() async {
        testStore.set(false, forKey: SettingsKey.debridEnabled)
        testStore.set(DebridProviderKind.torbox.rawValue, forKey: SettingsKey.debridProvider)
        testStore.set("test-token", forKey: SettingsKey.torboxAccessToken)

        let presentation = DebridStreamPresentation(store: testStore)
        XCTAssertFalse(presentation.isDebridEnabled)

        let rawStream = NuvioStream(
            url: nil,
            name: "Torrentio 1080p",
            description: "1080p | 2.5 GB",
            addonName: "Torrentio",
            infoHash: "0123456789abcdef0123456789abcdef01234567"
        )

        let results = await presentation.present(streams: [rawStream])
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Torrentio 1080p")
        XCTAssertFalse(results.first?.isCached == true)
    }

    func testPassesThroughWhenNoTokenConfigured() async {
        testStore.set(true, forKey: SettingsKey.debridEnabled)
        testStore.set(DebridProviderKind.torbox.rawValue, forKey: SettingsKey.debridProvider)
        testStore.set("", forKey: SettingsKey.torboxAccessToken)

        let presentation = DebridStreamPresentation(store: testStore)
        XCTAssertFalse(presentation.isDebridEnabled)

        let rawStream = NuvioStream(
            url: nil,
            name: "Torrentio 1080p",
            description: nil,
            addonName: "Torrentio",
            infoHash: "0123456789abcdef0123456789abcdef01234567"
        )

        let results = await presentation.present(streams: [rawStream])
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Torrentio 1080p")
    }

    func testDirectHTTPStreamsAreNeverFilteredOrModified() async {
        testStore.set(true, forKey: SettingsKey.debridEnabled)
        testStore.set(DebridProviderKind.torbox.rawValue, forKey: SettingsKey.debridProvider)
        testStore.set("test-token", forKey: SettingsKey.torboxAccessToken)

        let presentation = DebridStreamPresentation(store: testStore)

        let directStream = NuvioStream(
            url: "https://example.com/direct_stream.mkv",
            name: "Direct HTTP",
            description: nil,
            addonName: "HTTP Addon"
        )

        let results = await presentation.present(streams: [directStream])
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.url, "https://example.com/direct_stream.mkv")
        XCTAssertEqual(results.first?.name, "Direct HTTP")
    }

    func testDebridResolverRespectsDebridEnabledSetting() {
        testStore.set(false, forKey: SettingsKey.debridEnabled)
        testStore.set(DebridProviderKind.torbox.rawValue, forKey: SettingsKey.debridProvider)
        testStore.set("test-token", forKey: SettingsKey.torboxAccessToken)

        let resolver = DebridResolver(store: testStore)
        XCTAssertFalse(resolver.isEnabled)

        testStore.set(true, forKey: SettingsKey.debridEnabled)
        let resolverEnabled = DebridResolver(store: testStore)
        XCTAssertTrue(resolverEnabled.isEnabled)
    }

    func testCloudLibraryServiceRespectsCloudLibraryEnabledSetting() {
        testStore.set(false, forKey: SettingsKey.cloudLibraryEnabled)
        testStore.set(DebridProviderKind.torbox.rawValue, forKey: SettingsKey.debridProvider)
        testStore.set("test-token", forKey: SettingsKey.torboxAccessToken)

        let service = CloudLibraryService(store: testStore)
        XCTAssertFalse(service.isAvailable)

        testStore.set(true, forKey: SettingsKey.cloudLibraryEnabled)
        let serviceEnabled = CloudLibraryService(store: testStore)
        XCTAssertTrue(serviceEnabled.isAvailable)
    }
}
