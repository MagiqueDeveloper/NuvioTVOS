//
//  TVCacheClearing.swift
//  NuvioTV
//
//  Clears transient Home/artwork caches while preserving user settings.
//

import Foundation

/// Wipes poster/image caches, local Home catalog order, and row scroll
/// positions, then asks account sync to pull a fresh layout from the server.
enum TVCacheClearing {
    static let clearedNotification = Notification.Name("nuvio.tv.cache.cleared")

    /// Keys that describe cached Home layout/row state — not preference toggles.
    private static let layoutCacheKeys = [
        SettingsKey.homeCatalogOrder,
        SettingsKey.homeCatalogTitles,
        SettingsKey.homeCatalogSyncedOrder
    ]

    @MainActor
    static func clearAndRefresh() async {
        await purgeImageCaches()
        clearCatalogMetadataCache()
        clearHomeLayoutCaches()
        await StreamsRepository.clearManifestCache()

        NotificationCenter.default.post(name: clearedNotification, object: nil)

        // Prefer a forced account pull so catalog order returns from the web;
        // fall back to bumping the Home revision when signed out.
        if let sync = NuvioSyncManager.current, AuthConfig.isConfigured {
            sync.retryInitialAccountPull()
        } else {
            NotificationCenter.default.post(
                name: NuvioSyncManager.homeContentSyncedNotification,
                object: nil
            )
        }
    }

    private static func clearHomeLayoutCaches() {
        let defaults = ProfileSettings.current
        for key in layoutCacheKeys {
            defaults.removeObject(forKey: key)
        }
        NotificationCenter.default.post(name: TVHomeCatalogOrder.changedNotification, object: nil)
        NotificationCenter.default.post(
            name: TVHomeCatalogOrder.snapshotChangedNotification,
            object: nil
        )
    }

    private static func clearCatalogMetadataCache() {
        CinemetaCatalogRepository.clearMetadataCache()
    }

    private static func purgeImageCaches() async {
        await PosterArtworkCache.shared.purgeAll()
        await BackdropImageCache.shared.purge()
        await PersonProfileImageCache.shared.purge()
        URLCache.shared.removeAllCachedResponses()
    }
}
