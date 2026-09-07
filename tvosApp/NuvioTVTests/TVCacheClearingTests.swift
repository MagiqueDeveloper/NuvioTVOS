import XCTest
@testable import NuvioTV

final class TVCacheClearingTests: XCTestCase {
    func testClearedNotificationName() {
        XCTAssertEqual(TVCacheClearing.clearedNotification.rawValue, "nuvio.tv.cache.cleared")
    }

    func testLayoutCacheKeysAreDistinctFromPreferenceToggles() {
        // Clear Cache wipes layout/order blobs while preference toggles stay put.
        let layoutKeys: Set<String> = [
            SettingsKey.homeCatalogOrder,
            SettingsKey.homeCatalogTitles,
            SettingsKey.homeCatalogSyncedOrder
        ]
        XCTAssertFalse(layoutKeys.contains(SettingsKey.catalogAddonNames))
        XCTAssertFalse(layoutKeys.contains(SettingsKey.homeLayout))
        XCTAssertFalse(layoutKeys.contains(SettingsKey.theme))
        XCTAssertTrue(SettingsKey.all.contains(SettingsKey.catalogAddonNames))
        XCTAssertTrue(SettingsKey.all.contains(SettingsKey.homeLayout))
    }
}
