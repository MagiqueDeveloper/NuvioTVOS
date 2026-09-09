# AGENTS.md

This repository is MagiqueDeveloper's **development fork** of [bobsupra/NuvioTVOS](https://github.com/bobsupra/NuvioTVOS). It is tvOS-only. Official releases, issues, and review PRs live upstream.

## Remotes

- `origin` → `https://github.com/bobsupra/NuvioTVOS.git` (upstream)
- `fork` → `https://github.com/MagiqueDeveloper/NuvioTVOS.git` (this repo)

If either remote is missing, add it before fetching.

## Upstream overlay

This fork is an independent product direction. Integrate upstream selectively for security, engine, and compatibility fixes; do not overwrite the Nuvio Cinema UI and navigation architecture wholesale. Keep the tvOS-only tree, in-tree MPVKit, Nightly CI, and fork identity.

Follow [docs/upstream-merge.md](docs/upstream-merge.md) for the merge, verify, push, and main-only branch cleanup.

## tvOS UI

Focus-engine and SwiftUI conventions: [.agents/rules/tvos.md](.agents/rules/tvos.md)

## Contributions

Prefer issues and PRs on [upstream](https://github.com/bobsupra/NuvioTVOS). See [CONTRIBUTING.md](CONTRIBUTING.md).
