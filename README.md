> **Development fork.** This repository is MagiqueDeveloper's working copy for changes destined for [`bobsupra/NuvioTVOS`](https://github.com/bobsupra/NuvioTVOS). It is not the canonical app, release channel, or issue tracker.
>
> - **Upstream (releases, issues, PRs):** https://github.com/bobsupra/NuvioTVOS  
> - **This fork (WIP branches / experiments):** https://github.com/MagiqueDeveloper/NuvioTVOS  
> - **Nightly IPA (this fork):** code changes pushed to `main` and a daily schedule refresh the rolling [`nightly`](https://github.com/MagiqueDeveloper/NuvioTVOS/releases/tag/nightly) prerelease with the latest versioned unsigned IPA.
> - Open bugs and feature requests on the [upstream issue tracker](https://github.com/bobsupra/NuvioTVOS/issues). Download official builds from [upstream Releases](https://github.com/bobsupra/NuvioTVOS/releases).

<div align="center">

  <img src="https://github.com/tapframe/NuvioTV/blob/main/assets/brand/app_logo_wordmark.png" alt="Nuvio" width="300" />
  <br />
  <br />

  <h1>Nuvio Cinema for tvOS</h1>

  <p>
    A focused Apple TV cinema for resuming, discovering, and playing user-configured sources.
    <br />
    SwiftUI tvOS shell - catalog browsing - AetherEngine / MPVKit playback
  </p>

  <p>
    <a href="https://github.com/bobsupra/NuvioTVOS/releases/latest">
      <img src="https://img.shields.io/github/v/release/bobsupra/NuvioTVOS?include_prereleases&sort=date&label=Download%20.ipa&logo=apple&logoColor=white&color=0A84FF&style=for-the-badge" alt="Download the latest tvOS .ipa" />
    </a>
  </p>

  <p>
    <a href="https://github.com/bobsupra/NuvioTVOS/graphs/contributors">
      <img src="https://img.shields.io/github/contributors/bobsupra/NuvioTVOS?style=for-the-badge&color=44CC11" alt="Contributors" />
    </a>
    <a href="https://github.com/bobsupra/NuvioTVOS/forks">
      <img src="https://img.shields.io/github/forks/bobsupra/NuvioTVOS?style=for-the-badge&color=0A84FF" alt="Forks" />
    </a>
    <a href="https://github.com/bobsupra/NuvioTVOS/stargazers">
      <img src="https://img.shields.io/github/stars/bobsupra/NuvioTVOS?style=for-the-badge&color=0A84FF" alt="Stars" />
    </a>
    <a href="https://github.com/bobsupra/NuvioTVOS/issues">
      <img src="https://img.shields.io/github/issues/bobsupra/NuvioTVOS?style=for-the-badge&color=E5C100" alt="Open issues" />
    </a>
    <a href="https://github.com/bobsupra/NuvioTVOS/releases">
      <img src="https://img.shields.io/github/downloads/bobsupra/NuvioTVOS/total?style=for-the-badge&label=Total%20downloads&color=F47732" alt="Total downloads" />
    </a>
  </p>

</div>


Download the latest Apple TV `.ipa` from [Releases](https://github.com/bobsupra/NuvioTVOS/releases), then sideload it with Xcode, Apple Configurator, or your preferred tool. See the release notes for known issues.

> **New beta alerts:** [Manage notifications](https://github.com/bobsupra/NuvioTVOS/subscription) → choose **Custom → Releases**.

## Latest tvOS Beta

<!-- BEGIN LATEST_BETA -->
**Beta 3.3.4** is the latest tvOS release.

[Quick download (.ipa)](https://github.com/bobsupra/NuvioTVOS/releases/download/tvos-beta-3.3.4/NuvioTV-3.3.4-unsigned-release.ipa) · [Read the release notes](https://github.com/bobsupra/NuvioTVOS/releases/tag/tvos-beta-3.3.4) · [Report a bug or suggest an idea](https://github.com/bobsupra/NuvioTVOS/issues/new/choose)
<!-- END LATEST_BETA -->

> 🎉 **Thank you for 100+ GitHub Stars!** A huge thank you to everyone in the community for supporting NuvioTVOS and helping us reach 100+ stars!

The IPA requires a compatible tvOS development or sideloading signing workflow before installation.

### New in Beta 3.3.4

- **Fixed Issues #52 – #62:** Addresses community-reported bugs and feature requests including watch progress resume (#52), addon name display toggle (#53), cache clearing options (#54), Cinemeta layout persistence (#56), subtitle discovery (#57), home scroll smoothness (#58), debrid stream link resolution (#59), and sleep while paused (#62).
- **Native tvOS Search Keyboard & Dictation (#55, #60):** Integrates native Apple TV keyboard with Siri dictation support and fast focus navigation.
- **Enhanced Subtitle Selector (#61):** In-player subtitle picker with track selection and timing offset adjustments.
- **AetherEngine Diagnostics & Hardening:** Enhanced TLS handshakes, HLS origin relay, and software performance snapshot tracking.

### The new player

Nuvio now uses **AetherEngine** as its primary built-in player instead of the legacy AVPlayer implementation. It supports tvOS-native playback controls, precise seeking and resume, embedded and configured subtitles, styled text and PGS bitmap subtitles, saved audio/subtitle selections, and automatic frame-rate matching. **MPVKit** remains available as a one-way compatibility fallback for sources or controls that AetherEngine cannot currently handle, including separate video/audio URLs, audio delay, audio amplification, and ASS Scale mode.

### Trakt sign-in with your own API app

Nuvio supports Trakt device login with user-provided API credentials. This is useful when you want to use your own Trakt application instead of relying on shared app credentials.

1. Create an application at [trakt.tv/oauth/applications](https://trakt.tv/oauth/applications).
2. Set its redirect URI to `urn:ietf:wg:oauth:2.0:oob`.
3. On Apple TV, go to **Settings → Integrations → Trakt**, then enter the Trakt Client ID and Client Secret.
4. Choose **Connect with Trakt**, scan the QR code or enter its code at `trakt.tv/activate`, and approve the connection.

The Client ID and Client Secret are stored only on that Apple TV; they are deliberately excluded from Nuvio account/profile sync. Changing either credential disconnects the old Trakt session so it cannot be reused with a different application.

### Simkl sign-in with your own API app

Nuvio supports Simkl TV PIN login with a user-provided Client ID.

1. Create an application in [Simkl developer settings](https://simkl.com/settings/developer/).
2. Use `urn:ietf:wg:oauth:2.0:oob` as the redirect URI when configuring the application.
3. On Apple TV, go to **Settings → Integrations → Simkl** and enter its Client ID.
4. Choose **Connect with Simkl**, scan the QR code, and enter the displayed PIN at `simkl.com/pin`.

Simkl's PIN flow does not need a Client Secret. The Client ID stays on that Apple TV and is excluded from Nuvio sync; the access token is stored in the current profile's Keychain.

### Notes

- Content availability depends on your configured sources and their upstream services.
- The Apple TV Simulator cannot play AV1. ASS/SSA positioning and typesetting use the app subtitle style.

## About

This tree is an **independent Nuvio Cinema fork** of [bobsupra/NuvioTVOS](https://github.com/bobsupra/NuvioTVOS). It keeps upstream attribution and compatible playback/integration formats while developing its own tvOS experience.

The app itself is **tvOS-only**: a native SwiftUI Apple TV client under [tvosApp](./tvosApp) with Apple TV navigation, focus handling, profile selection, catalog browsing, details screens, search, library/watchlist surfaces, and playback controls designed for the Siri Remote.

The active development surface is [Packages/NuvioTVKit](./Packages/NuvioTVKit) plus the small app composition root in [tvosApp/NuvioTV/Sources](./tvosApp/NuvioTV/Sources). Android / Kotlin Multiplatform and iOS phone targets are not part of this repository.

## Current tvOS App

- Native SwiftUI entry point in [NuvioTVApp.swift](./tvosApp/NuvioTV/Sources/NuvioTVApp.swift).
- Apple TV tab navigation for Profile, Home, Search, Library, and Settings.
- Home rows for synced Nuvio collections and configured catalog lists.
- Catalog and metadata repository with configurable catalog, playback, and subtitle integrations.
- User-configurable source integrations in Settings → Integrations → Add-ons.
- Cloud library playback through supported connected services.
- Apple TV Top Shelf extension backed by the active Continue Watching row.
- Long-press quick actions for poster cards, including details, library toggle, and watched toggle.
- Typed data, playback, UI, and feature modules live in [Packages/NuvioTVKit](./Packages/NuvioTVKit).
- tvOS profile/account sync for profiles, add-ons, settings, library, watched state, and progress. Settings follow the selected profile across Apple TVs; device-only app credentials stay local.
- Trakt device-code login using a user-provided Client ID and Client Secret, stored locally on the Apple TV.
- Simkl PIN login, watched-history sync, Plan to Watch library sync, playback progress, and scrobbling.
- New AetherEngine-first player with Siri Remote controls, precise seeking and resume, embedded/add-on subtitle support, saved track selections, frame-rate matching, and a one-way MPVKit compatibility fallback.
- Pure Swift app core (no Nuvio Rust / FFI dependency).
- tvOS app assets, splash screen, top shelf images, and Apple TV app icon stack in [Images.xcassets](./tvosApp/NuvioTV/Images.xcassets).

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](./CONTRIBUTING.md) for contribution rules, testing notes, and issue-reporting guidance.

## Requirements

- macOS with Xcode installed.
- Apple TV simulator runtime installed in Xcode.
- Network access for catalog metadata, source lookups, and Swift Package resolution.

The Xcode project targets Apple TV (`SDKROOT = appletvos`) with bundle id `com.nuvio.app.tv`. The tvOS deployment target is configured in [project.pbxproj](./tvosApp/NuvioTV.xcodeproj/project.pbxproj).

## Setup

```bash
git clone https://github.com/MagiqueDeveloper/NuvioTVOS.git
cd NuvioTVOS
```

For the canonical upstream tree instead:

```bash
git clone --recurse-submodules https://github.com/bobsupra/NuvioTVOS.git
cd NuvioTVOS
```

If you already cloned upstream without submodules:

```bash
git submodule update --init --recursive
```

Open the tvOS project:

```bash
open tvosApp/NuvioTV.xcodeproj
```

Use the `NuvioTV` scheme and an Apple TV simulator.

## Running

The helper script builds the native tvOS app, installs it on the first booted Apple TV simulator, and launches it:

```bash
./scripts/run-tvos.sh
```

If no Apple TV simulator is booted, open Simulator or Xcode first and start one, then rerun the command.

You can also build directly with Xcode:

```bash
xcodebuild \
  -project tvosApp/NuvioTV.xcodeproj \
  -scheme NuvioTV \
  -configuration Debug \
  -destination 'generic/platform=tvOS Simulator' \
  build
```

## Configuration

Account login is optional during development. The login screen supports "Continue without account" so the tvOS UI can be tested without backend credentials.

To enable QR login and email auth, fill in the Supabase values in:

```text
Packages/NuvioTVKit/Sources/NuvioData
```

Catalogs and metadata use configurable catalog, playback, and subtitle endpoints from the repository interfaces in [NuvioData](./Packages/NuvioTVKit/Sources/NuvioData).

## Tests

Unit and UI test targets live in:

- [tvosApp/NuvioTVTests](./tvosApp/NuvioTVTests)
- [tvosApp/NuvioTVUITests](./tvosApp/NuvioTVUITests)

Run tests from Xcode, or with:

```bash
  xcodebuild test \
  -project tvosApp/NuvioTV.xcodeproj \
  -scheme NuvioTV \
  -destination 'platform=tvOS Simulator,name=Apple TV'
```

Some older verification scripts in `tvosApp/` still carry inherited iOS wording. Prefer the Xcode build/test commands above as the source of truth for the tvOS target.

## Project Structure

- `Packages/NuvioTVKit/Sources/NuvioDomain/` contains pure domain models and errors.
- `Packages/NuvioTVKit/Sources/NuvioData/` contains repositories, stores, and adapters.
- `Packages/NuvioTVKit/Sources/NuvioPlayback/` contains the playback seam and Aether adapter.
- `Packages/NuvioTVKit/Sources/NuvioUI/` contains reusable tvOS presentation primitives.
- `Packages/NuvioTVKit/Sources/NuvioFeatures/` contains the Home, Search, Library, Details, Profile, and Player flows.
- `tvosApp/NuvioTV/Sources/` contains only the composition root.
- `MPVKit/` is a vendored [NuvioMedia/MPVKit](https://github.com/NuvioMedia/MPVKit) snapshot (MoltenVK tvOS) whose `Libmpv` binary is hosted on this fork's [`mpvkit-libmpv`](https://github.com/MagiqueDeveloper/NuvioTVOS/releases/tag/mpvkit-libmpv) release.
- `Vendor/AetherEngine/` is the primary playback engine package.

## Built With

- SwiftUI and UIKit focus/input bridging for tvOS
- AetherEngine and MPVKit playback engines
- Configurable catalog, source, and subtitle APIs

## Legal & DMCA

Nuvio functions solely as a client-side interface for browsing metadata and playing media provided by user-configured sources. It is intended for content the user owns or is otherwise authorized to access.

Nuvio is not affiliated with any third-party extensions, catalogs, sources, or content providers. It does not host, store, or distribute any media content.

For comprehensive legal information, including the full disclaimer, third-party extension policy, and DMCA/Copyright information, visit the [Legal & Disclaimer Page](https://nuvioapp.space/legal).
