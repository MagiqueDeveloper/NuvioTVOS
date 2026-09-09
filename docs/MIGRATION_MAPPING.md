# Nuvio Cinema Migration Mapping

## Overview

Porting and **refactoring** 113 implementation files from **fork/main** (flat structure in `tvosApp/NuvioTV/Sources/`) to **nuviocinema** (modular SPM architecture in `Packages/NuvioTVKit/`).

**Strategy:** 
- Adapter pattern to bridge fork/main's domain models to nuviocinema's clean architecture
- **Port + Polish:** Refactor as we port - extract reusable components, modernize patterns, enhance UX
- **Premium Cinema Experience:** Liquid glass morphism, smooth animations, cinematic aesthetics
- **Code Quality:** Clean async/await, proper error handling, comprehensive documentation

---

## File Mapping: fork/main → nuviocinema

### Phase 0: Foundation (Adapters & Domain Extensions)

| Source (fork/main) | Target (nuviocinema) | Notes |
|--------------------|----------------------|-------|
| `DomainModels.swift` (StremioMeta, Profile, WatchedItem) | Extend `NuvioDomain/Domain.swift` | Add missing fields to MediaSummary |
| N/A | Create `NuvioData/Adapters.swift` | New file: StremioMetaAdapter, CatalogAdapter, StreamAdapter |
| N/A | Add FeatureFlags to `NuvioFeatures/Features.swift` | Feature toggle system |

---

### Phase 1: Core Content Pipeline (Stremio Addons)

| Source (fork/main) | Target (nuviocinema) | Layer | Notes |
|--------------------|----------------------|-------|-------|
| `Core/Addons/AddonTransportUrls.swift` | `NuvioData/AddonClient.swift` | Data | HTTP transport for Stremio addons |
| `Core/Addons/CommunityAddonCatalog.swift` | `NuvioData/AddonClient.swift` | Data | Default addon catalog |
| `Data/Repository/CatalogRepository.swift` | `NuvioData/StremioAddonCatalogRepository.swift` | Data | Implement CatalogRepository protocol |
| `Data/Repository/StreamsRepository.swift` | `NuvioData/StremioStreamRepository.swift` | Data | Implement StreamRepository protocol |
| `Data/Repository/CollectionSourceResolver.swift` | `NuvioData/MetadataService.swift` | Data | TMDB/Cinemeta enrichment |

**Validation:** HomeView displays real Stremio catalogs with artwork.

---

### Phase 2: Playback Engine

| Source (fork/main) | Target (nuviocinema) | Layer | Notes |
|--------------------|----------------------|-------|-------|
| `Models/WatchProgressLedger.swift` | `NuvioData/WatchProgressStore.swift` | Data | Implement ProgressStore protocol |
| `DomainModels.swift` (ProfileManager) | `NuvioData/ProfileStore.swift` | Data | Implement ProfileStore protocol |
| `Core/Debrid/DebridResolver.swift` | `NuvioData/DebridResolvers.swift` | Data | Protocol definition |
| `Core/Debrid/RealDebridResolver.swift` | `NuvioData/DebridResolvers.swift` | Data | RealDebrid implementation |
| `Core/Debrid/PremiumizeResolver.swift` | `NuvioData/DebridResolvers.swift` | Data | Premiumize implementation |
| `Core/Debrid/TorboxResolver.swift` | `NuvioData/DebridResolvers.swift` | Data | Torbox implementation |
| `Core/Debrid/DebridProvider.swift` | `NuvioData/DebridResolvers.swift` | Data | Provider enum |
| `Core/Debrid/DebridStreamPresentation.swift` | `NuvioData/DebridResolvers.swift` | Data | Stream formatting |
| `Core/Debrid/LocalDebridService.swift` | `NuvioData/DebridResolvers.swift` | Data | Service coordinator |
| `Core/Debrid/DebridDeviceAuthorization.swift` | `NuvioData/DebridResolvers.swift` | Data | OAuth device flow |
| `Core/Player/PlaybackEngineControlling.swift` | Extend `NuvioPlayback/PlaybackEngine.swift` | Playback | Add missing protocol methods |
| `Core/Player/PlaybackEngineState.swift` | Extend `NuvioDomain/Domain.swift` | Domain | Extend PlaybackState enum |
| `Core/Player/PlaybackEngineCapabilities.swift` | `NuvioPlayback/PlaybackEngine.swift` | Playback | Capabilities query |
| `Core/Player/PlaybackTrackInfo.swift` | Extend `NuvioDomain/Domain.swift` | Domain | Extend StreamTrack |
| `Core/Player/AetherPlaybackController.swift` | `NuvioPlayback/AetherPlaybackEngine.swift` | Playback | Replace stub implementation |
| `Core/Player/PlaybackBackendPolicy.swift` | `NuvioPlayback/PlaybackEngine.swift` | Playback | Aether vs MPV selection |
| `Core/Player/PlaybackSessionCoordinator.swift` | `NuvioFeatures/PlayerFeature.swift` | Features | Session management |
| `Core/Player/PlaybackLoadRequest.swift` | Extend `NuvioDomain/Domain.swift` | Domain | Extend PlaybackRequest |
| `Core/Player/PlaybackWakeLock.swift` | `NuvioPlayback/AetherPlaybackEngine.swift` | Playback | Keep screen on |
| `Core/Player/PlaybackCacheSettings.swift` | `NuvioPlayback/AetherPlaybackEngine.swift` | Playback | Buffer settings |

**Validation:** One video plays end-to-end with resume and progress tracking.

---

### Phase 3: Player UI & Controls

| Source (fork/main) | Target (nuviocinema) | Layer | Notes |
|--------------------|----------------------|-------|-------|
| `UI/Player/PlayerView.swift` | `NuvioFeatures/PlayerView.swift` | Features | Main player UI (enhance existing) |
| `UI/Player/PlayerControls.swift` | `NuvioFeatures/PlayerView.swift` | Features | Playback controls |
| `UI/Player/ScrubberViews.swift` | `NuvioUI/TVPrimitives.swift` | UI | Scrubber component |
| `UI/Player/PlayerLoadingOverlay.swift` | `NuvioFeatures/PlayerView.swift` | Features | Loading state |
| `UI/Player/PlayerSubtitleOverlay.swift` | `NuvioFeatures/PlayerView.swift` | Features | Subtitle display |
| `UI/Player/PauseOverlayView.swift` | `NuvioFeatures/PlayerView.swift` | Features | Pause UI |
| `UI/Player/RemoteInput.swift` | `NuvioFeatures/PlayerView.swift` | Features | tvOS remote handling |
| `UI/Player/SidePanels.swift` | `NuvioFeatures/PlayerView.swift` | Features | Track/audio panels |
| `ViewModels/PlayerViewModel.swift` | `NuvioFeatures/PlayerView.swift` | Features | Enhance existing ViewModel |
| `Core/Player/MPVPlaybackController.swift` | `NuvioPlayback/MPVPlaybackEngine.swift` | Playback | MPV backend |
| `UI/Details/DetailsScreen.swift` | `NuvioFeatures/DetailsView.swift` | Features | Enhance with cast/crew |
| `ViewModels/DetailsViewModel.swift` | `NuvioFeatures/DetailsView.swift` | Features | Enhance existing |

**Validation:** Player controls, subtitle selection, scrubbing work. Details screen shows cast/crew.

---

### Phase 4: Major Integrations (Behind Feature Flags)

#### Jellyfin

| Source (fork/main) | Target (nuviocinema) | Layer |
|--------------------|----------------------|-------|
| `Core/Jellyfin/JellyfinClient.swift` | `NuvioData/Jellyfin/JellyfinClient.swift` | Data |
| `Core/Jellyfin/JellyfinLibraryResolver.swift` | `NuvioData/Jellyfin/JellyfinAdapter.swift` | Data |
| `Core/Jellyfin/JellyfinLibraryIndex.swift` | `NuvioData/Jellyfin/JellyfinAdapter.swift` | Data |
| `Core/Jellyfin/JellyfinSessionManager.swift` | `NuvioData/Jellyfin/JellyfinAdapter.swift` | Data |
| `Core/Jellyfin/JellyfinServerConfig.swift` | `NuvioData/Jellyfin/JellyfinAdapter.swift` | Data |
| `Core/Jellyfin/JellyfinServerStore.swift` | `NuvioData/Jellyfin/JellyfinAdapter.swift` | Data |
| `Core/Jellyfin/JellyfinCredentialStore.swift` | `NuvioData/Jellyfin/JellyfinAdapter.swift` | Data |

**Expose as:** `CatalogRepository` + `StreamRepository` conformance

#### Trakt/Simkl Sync

| Source (fork/main) | Target (nuviocinema) | Layer |
|--------------------|----------------------|-------|
| `Core/Auth/AuthManager.swift` | `NuvioData/SyncServices/AuthManager.swift` | Data |
| `Core/Auth/AuthService.swift` | `NuvioData/SyncServices/AuthService.swift` | Data |
| `Core/Auth/AuthModels.swift` | `NuvioData/SyncServices/AuthModels.swift` | Data |
| `Core/Auth/AuthConfig.swift` | `NuvioData/SyncServices/AuthConfig.swift` | Data |
| `Core/Auth/QRCode.swift` | `NuvioData/SyncServices/QRCode.swift` | Data |
| `Core/Trakt/TraktAuthService.swift` | `NuvioData/SyncServices/TraktSync.swift` | Data |
| `Core/Trakt/TraktDetailsService.swift` | `NuvioData/SyncServices/TraktSync.swift` | Data |
| `Core/Simkl/SimklAuthService.swift` | `NuvioData/SyncServices/SimklSync.swift` | Data |
| `Core/Simkl/SimklAPIClient.swift` | `NuvioData/SyncServices/SimklSync.swift` | Data |
| `Core/Simkl/SimklDetailsService.swift` | `NuvioData/SyncServices/SimklSync.swift` | Data |
| `Core/Simkl/SimklSyncService.swift` | `NuvioData/SyncServices/SimklSync.swift` | Data |
| `Core/Sync/NuvioSyncService.swift` | `NuvioData/SyncServices/SyncCoordinator.swift` | Data |
| `Core/Sync/ICloudSettingsSyncManager.swift` | `NuvioData/SyncServices/ICloudSync.swift` | Data |

#### SMB

| Source (fork/main) | Target (nuviocinema) | Layer |
|--------------------|----------------------|-------|
| `Core/SMB/SMBLibraryResolver.swift` | `NuvioData/SMB/SMBAdapter.swift` | Data |
| `Core/SMB/SMBLibraryScanner.swift` | `NuvioData/SMB/SMBAdapter.swift` | Data |
| `Core/SMB/SMBLibraryIndex.swift` | `NuvioData/SMB/SMBAdapter.swift` | Data |
| `Core/SMB/SMBSessionManager.swift` | `NuvioData/SMB/SMBAdapter.swift` | Data |
| `Core/SMB/SMBServerConfig.swift` | `NuvioData/SMB/SMBAdapter.swift` | Data |
| `Core/SMB/SMBServerStore.swift` | `NuvioData/SMB/SMBAdapter.swift` | Data |
| `Core/SMB/SMBCredentialStore.swift` | `NuvioData/SMB/SMBAdapter.swift` | Data |
| `Core/SMB/MediaFilenameParser.swift` | `NuvioData/SMB/SMBAdapter.swift` | Data |

#### Cloud Libraries

| Source (fork/main) | Target (nuviocinema) | Layer |
|--------------------|----------------------|-------|
| `Core/Cloud/CloudLibraryService.swift` | `NuvioData/Cloud/CloudAdapter.swift` | Data |
| `Core/Cloud/CloudLibraryModels.swift` | `NuvioData/Cloud/CloudAdapter.swift` | Data |
| `Core/Cloud/PremiumizeCloudLibrary.swift` | `NuvioData/Cloud/CloudAdapter.swift` | Data |
| `Core/Cloud/TorboxCloudLibrary.swift` | `NuvioData/Cloud/CloudAdapter.swift` | Data |
| `ViewModels/CloudLibraryViewModel.swift` | `NuvioFeatures/CloudLibraryFeature.swift` | Features |
| `UI/Cloud/CloudLibraryView.swift` | `NuvioFeatures/CloudLibraryFeature.swift` | Features |

#### Settings UI

| Source (fork/main) | Target (nuviocinema) | Layer |
|--------------------|----------------------|-------|
| `UI/Settings/SettingsView.swift` | `NuvioFeatures/SettingsFeature.swift` | Features |

---

### Phase 5: Advanced Features

| Source (fork/main) | Target (nuviocinema) | Layer | Notes |
|--------------------|----------------------|-------|-------|
| `Core/Player/PostPlayRecommendationController.swift` | `NuvioFeatures/PlayerView.swift` | Features | Next episode logic |
| `UI/Player/PostPlayRecommendationOverlay.swift` | `NuvioFeatures/PlayerView.swift` | Features | Post-play UI |
| `Models/PostPlayRecommendationModels.swift` | Extend `NuvioDomain/Domain.swift` | Domain | Recommendation types |
| `Core/Player/AISubtitleTranslationCache.swift` | `NuvioPlayback/SubtitleTranslation.swift` | Playback | Gemini integration |
| `Core/Player/PictureInPictureManager.swift` | `NuvioPlayback/AetherPlaybackEngine.swift` | Playback | PiP support |
| `Core/Player/AppleTVCapability.swift` | `NuvioPlayback/PlaybackEngine.swift` | Playback | Device capability detection |
| `Core/Streams/StreamQualityTags.swift` | `NuvioData/StreamRepository.swift` | Data | Quality parsing |
| `Core/TopShelf/TopShelfFeed.swift` | Update existing `NuvioData/TopShelfFeed.swift` | Data | Enhance with real data |
| `Core/Sync/ContinueWatchingBuilder.swift` | `NuvioData/TopShelfFeed.swift` | Data | Build TopShelf feed |

---

### Phase 6: UI Components & Polish

| Source (fork/main) | Target (nuviocinema) | Layer |
|--------------------|----------------------|-------|
| `UI/Home/TVCatalogRow.swift` | `NuvioUI/TVPrimitives.swift` | UI |
| `UI/Home/CollectionFolderBrowseView.swift` | `NuvioFeatures/HomeView.swift` | Features |
| `UI/Search/SearchView.swift` | Enhance `NuvioFeatures/SearchView.swift` | Features |
| `UI/Search/NativeSearchView.swift` | `NuvioFeatures/SearchView.swift` | Features |
| `UI/Search/NetflixSearchView.swift` | `NuvioFeatures/SearchView.swift` | Features |
| `ViewModels/SearchViewModel.swift` | Enhance `NuvioFeatures/SearchView.swift` | Features |
| `ViewModels/NetflixSearchViewModel.swift` | `NuvioFeatures/SearchView.swift` | Features |
| `UI/Discover/DiscoverView.swift` | Enhance `NuvioFeatures/DiscoverView.swift` | Features |
| `ViewModels/DiscoverViewModel.swift` | Enhance `NuvioFeatures/DiscoverView.swift` | Features |
| `UI/Library/LibraryView.swift` | Enhance `NuvioFeatures/LibraryView.swift` | Features |
| `ViewModels/LibraryViewModel.swift` | Enhance `NuvioFeatures/LibraryView.swift` | Features |
| `UI/Details/ProductionBrowseView.swift` | `NuvioFeatures/DetailsView.swift` | Features |
| `Core/AppLanguage.swift` | `NuvioData/AppSettings.swift` | Data |
| `Core/NuvioFormatting.swift` | `NuvioUI/Formatting.swift` | UI |

---

## Architecture Layer Mapping

```
fork/main                          nuviocinema
─────────────────────              ───────────────────────────
DomainModels.swift         →       NuvioDomain/Domain.swift (extend)
Models/*Models.swift       →       NuvioDomain/Domain.swift (extend)

Core/Addons/*             →       NuvioData/AddonClient.swift
Core/Debrid/*             →       NuvioData/DebridResolvers.swift
Core/Jellyfin/*           →       NuvioData/Jellyfin/
Core/Trakt/*              →       NuvioData/SyncServices/Trakt*.swift
Core/Simkl/*              →       NuvioData/SyncServices/Simkl*.swift
Core/SMB/*                →       NuvioData/SMB/
Core/Cloud/*              →       NuvioData/Cloud/
Core/Auth/*               →       NuvioData/SyncServices/Auth*.swift
Core/Sync/*               →       NuvioData/SyncServices/
Data/Repository/*         →       NuvioData/*Repository.swift

Core/Player/*             →       NuvioPlayback/
                                  + extend PlaybackEngine protocol

UI/Player/*               →       NuvioFeatures/PlayerView.swift
UI/Details/*              →       NuvioFeatures/DetailsView.swift
UI/Home/*                 →       NuvioFeatures/HomeView.swift
UI/Search/*               →       NuvioFeatures/SearchView.swift
UI/Library/*              →       NuvioFeatures/LibraryView.swift
UI/Discover/*             →       NuvioFeatures/DiscoverView.swift
UI/Settings/*             →       NuvioFeatures/SettingsFeature.swift
UI/Cloud/*                →       NuvioFeatures/CloudLibraryFeature.swift

ViewModels/*              →       Merge into NuvioFeatures/*View.swift
                                  (nuviocinema colocates VM with View)

Reusable UI components    →       NuvioUI/TVPrimitives.swift
```

---

## File Count Summary

- **fork/main:** 113 Swift implementation files
- **nuviocinema baseline:** ~15 Swift files (skeleton + sample data)
- **Porting:** ~98 net new implementations (some files merge)
- **New files:** Adapters.swift, FeatureFlags, organized into SPM modules

---

## Critical Architectural Decisions

1. **Adapter Pattern:** Keep nuviocinema's clean domain names, write adapters for StremioMeta/NuvioStream/NuvioCatalog
2. **Feature Flags:** All major integrations behind `FeatureFlags` in `AppDependencies`
3. **Protocol Extensions:** Extend `PlaybackEngine` incrementally as features need it
4. **SPM Modules:** Preserve 5-layer architecture (Domain → Data/Playback/UI → Features)
5. **Colocated ViewModels:** Merge ViewModels into Feature Views (nuviocinema pattern)
6. **No Breaking Changes:** All ports conform to existing nuviocinema protocols

---

## Next Steps

1. **Phase 0:** Domain extensions + adapter foundation (Days 1-2)
2. **Phase 1:** Stremio content pipeline (Days 3-5)
3. **Phase 2:** Playback engine + Debrid (Week 2)
4. **Phase 3:** Player UI polish (Week 3)
5. **Phase 4:** Feature-flagged integrations (Weeks 4-5)
6. **Phase 5:** Advanced features (Week 6)
7. **Phase 6:** Testing & refinement (Week 6)
