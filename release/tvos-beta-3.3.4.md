## tvOS Beta 3.3.4

> **Install:** [NuvioTV-3.3.4-unsigned-release.ipa](https://github.com/bobsupra/NuvioTVOS/releases/download/tvos-beta-3.3.4/NuvioTV-3.3.4-unsigned-release.ipa) requires a compatible tvOS development or sideloading signing workflow before installation.

> **New beta alerts:** [Manage notifications](https://github.com/bobsupra/NuvioTVOS/subscription) → choose **Custom → Releases** · [Report a bug or suggest an idea](https://github.com/bobsupra/NuvioTVOS/issues/new/choose)

> 🎉 **Thank you for 100+ GitHub Stars!** A huge thank you to everyone in the community for supporting NuvioTVOS and helping reach 100+ stars on GitHub! Your feedback, issue reports, and testing make this possible.

### Fixed Issues & Community Feedback (#52 – #62)

- **#52 — Resume Point & Watch Progress Synchronization:** Fixed resume position tracking and playback ledger updates, ensuring accurate resume prompts and seamless multi-device sync with NuvioSync and Trakt.
- **#53 & #59 — Addon Name Toggle & Debrid Stream Presentation:** Added `DebridStreamPresentation` and `LocalDebridService` for cleaner stream badge formatting, honoring the addon name display preference and resolving direct debrid playback links.
- **#54 — Clear Cache Feature:** Integrated cache management tools in Settings to safely clear thumbnail, metadata, and temporary video caches without losing configuration.
- **#55 & #60 — Native tvOS Search Keyboard & Dictation:** Embedded Apple's native tvOS search keyboard host (`NativeSearchView.swift`), providing full Siri dictation support, large keys, and seamless transition into search results.
- **#56 — Cinemeta & Catalog Layout Persistence:** Fixed layout reordering and Cinemeta re-downloading issues; catalog custom ordering and pinned rows now persist reliably across restarts.
- **#57 & #61 — Subtitle Addons & Native Subtitle Selector:** Enhanced subtitle discovery for third-party addons and refined the in-player subtitle track picker with styled text and timing offsets.
- **#58 — Home Screen Scrolling Performance:** Optimized horizontal catalog rows (`TVCatalogRow.swift`) and collection folder browsing (`CollectionFolderBrowseView.swift`) for buttery smooth 60fps scrolling on Apple TV.
- **#62 — Apple TV Sleep While Paused:** Implemented smart `PlaybackWakeLock` idle timer management (`PlaybackIdlePolicyTests.swift`) so the Apple TV screen saver and sleep timer activate normally when media is paused.

### Additional Engine & Core Enhancements

- **AetherEngine Diagnostics & Relays:** Integrated TLS handshake hardening, HLS origin relay, audio delay control, and software performance snapshot tracking (`SWPerformanceSnapshot.swift`).
- **Comprehensive Unit Testing:** 317 automated test suites passing with 0 failures, including `DebridStreamPresentationTests`, `HomeLayoutSettingsTests`, `PlaybackIdlePolicyTests`, and `StreamQualityTagsTests`.

### Known issues

- Picture in Picture requires a supported Apple TV 4K / tvOS 15+ device.
- Physical Apple TV playback, HDMI/HDR/Dolby Vision, AirPlay receivers, Atmos hardware, and live-TV paths still need real-device validation; the Apple TV Simulator cannot play AV1.
