import XCTest
@testable import NuvioTV

final class TVCacheClearingTests: XCTestCase {
    func testClearedNotificationName() {
        XCTAssertEqual(TVCacheClearing.clearedNotification.rawValue, "nuvio.tv.cache.cleared")
    }

    func testLayoutCacheKeysAreDistinctFromCoreSettings() {
        // Clear Cache must wipe layout/order blobs, not preference toggles.
        let layoutKeys: Set<String> = [
            SettingsKey.homeCatalogOrder,
            SettingsKey.homeCatalogTitles,
            SettingsKey.homeCatalogSyncedOrder
        ]
        XCTAssertTrue(layoutKeys.isSubset(of: Set(SettingsKey.all)))
        XCTAssertFalse(layoutKeys.contains(SettingsKey.catalogAddonNames))
        XCTAssertFalse(layoutKeys.contains(SettingsKey.homeLayout))
        XCTAssertFalse(layoutKeys.contains(SettingsKey.theme))
    }
}
