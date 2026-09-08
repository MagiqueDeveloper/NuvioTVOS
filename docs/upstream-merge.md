# Upstream overlay

Recipe for merging `bobsupra/NuvioTVOS` `main` into this fork. Reference merge: `5adb346` (2026-09-08, tvOS Beta 3.3.4).

**Policy.** Upstream wins for every product change. This fork keeps only the **fork scaffold**. A three-way auto-merge that preserves old fork feature hunks is a failed overlay.

Done when: `tvosApp/` and `Vendor/` match `origin/main` exactly, the scaffold files below are still this fork's versions, `fork/main` has been pushed, and the fork has no branches other than `main`.

## Fork scaffold

Restore these from the fork parent (`HEAD` during the merge, which is `fork/main`):

| Path | Why |
| --- | --- |
| `.github/ISSUE_TEMPLATE/` | Issues disabled; redirect to upstream; tvOS-only fields |
| `.github/workflows/ci.yml` | Fork PR/main tvOS build + `NuvioTVTests` |
| `.github/workflows/nightly.yml` | Rolling `nightly` IPA on this fork |
| `.github/workflows/update-latest-beta.yml` | Skip the `nightly` prerelease tag when updating the README |
| `CONTRIBUTING.md` | Points contributors at upstream |
| `FUTURE_IMPLEMENTATION.md` | tvOS-only wording |
| `scripts/ci/` | `nightly_release.py` for the Nightly workflow |
| `scripts/run-tvos.sh` | Simulator helper used in the fork README |
| `MPVKit/` | In-tree sources (not the upstream git submodule) |
| `.gitignore` | Ignore all of `artifacts/`, plus `MPVKit/.build/` and `MPVKit/.swiftpm/` |
| `README.md` | Keep the development-fork banner, tvOS-only About, clone URL, and `./scripts/run-tvos.sh`. Take upstream's Latest tvOS Beta block and release notes |

Take these from `origin/main` (overwrite ours):

- `tvosApp/`
- `Vendor/`
- `release/`
- `.agents/`
- `supabase/`
- `memory.md`
- `LICENSE`
- `scripts/build-ipa.sh`
- `scripts/deploy_trakt_function.sh`
- `scripts/run-mobile.sh`
- `scripts/translate_catalog.py`
- `.github/workflows/close-stale-issues.yml`
- `.github/workflows/close-unlabeled-issues.yml`
- `.github/workflows/pr-template-check.yml`

Strip these if the merge brings them back (upstream still carries Android/KMP leftovers and committed artifacts):

- `composeApp/`
- `iosApp/`
- `artifacts/`
- `build/`
- `gradle/`
- `build.gradle.kts`
- `settings.gradle.kts`
- `gradle.properties`
- `gradlew`
- `.gitmodules`
- `.github/workflows/issue-welcome.yml` (this fork has Issues disabled)

Let upstream **delete** `.github/workflows/stale-needs-info.yml` and `.github/workflows/triage-needs-info.yml` when origin has replaced that flow.

Drop fork-only feature files that origin never had. After checking out `tvosApp` from origin they can remain in the index. Find them with:

```sh
comm -23 \
  <(git ls-tree -r --name-only HEAD -- tvosApp | sort) \
  <(git ls-tree -r --name-only origin/main -- tvosApp | sort)
```

`git rm` every path that list prints. Historical examples: `ExternalSubtitleFileCache.swift`, `TVCacheClearing.swift`, and their tests.

## Steps

### 1. Fetch both remotes

```sh
git remote -v
git fetch origin
git fetch fork
```

Done when `origin/main` and `fork/main` are current. Add remotes named `origin` and `fork` first if they are missing.

### 2. Start from fork `main`

`main` may already be checked out in another worktree. In that case branch from `fork/main` instead of checking out `main`:

```sh
git checkout -B merge/upstream-main fork/main
```

If git refuses because leftover `MPVKit` submodule files would be overwritten:

```sh
git checkout -f -B merge/upstream-main fork/main
git clean -fd -- MPVKit
```

Done when `HEAD` is `fork/main`, `.gitmodules` is absent, `MPVKit/` is a normal directory, and `.github/workflows/nightly.yml` exists.

### 3. Merge upstream without committing

```sh
git merge origin/main --no-commit --no-ff
```

Conflicts are expected. Do not resolve hunk-by-hunk in `tvosApp/` or `Vendor/`.

### 4. Overlay

```sh
git checkout origin/main -- \
  tvosApp Vendor release .agents supabase memory.md LICENSE \
  scripts/build-ipa.sh scripts/deploy_trakt_function.sh \
  scripts/run-mobile.sh scripts/translate_catalog.py

git checkout HEAD -- \
  .github/ISSUE_TEMPLATE \
  .github/workflows/ci.yml \
  .github/workflows/nightly.yml \
  .github/workflows/update-latest-beta.yml \
  CONTRIBUTING.md \
  FUTURE_IMPLEMENTATION.md \
  scripts/ci \
  scripts/run-tvos.sh \
  MPVKit

git rm -rf --ignore-unmatch composeApp iosApp artifacts build gradle
git rm -f --ignore-unmatch \
  build.gradle.kts settings.gradle.kts gradle.properties gradlew \
  .gitmodules \
  .github/workflows/issue-welcome.yml \
  .github/workflows/stale-needs-info.yml \
  .github/workflows/triage-needs-info.yml
```

Then `git rm` every leftover fork-only `tvosApp` path from the `comm` command in **Fork scaffold**.

README: keep the fork banner and tvOS-only About/setup; take origin's `<!-- BEGIN LATEST_BETA -->` block and "New in Beta …" notes. Confirm `.gitignore` still ignores `artifacts/` (not only `artifacts/*-ipa/`) and the `MPVKit` build dirs.

Done when `git diff --name-only --diff-filter=U` is empty.

### 5. Verify

```sh
git diff origin/main -- tvosApp Vendor
test ! -f .gitmodules
test -f .github/workflows/nightly.yml
test -f scripts/ci/nightly_release.py
test ! -d composeApp
test ! -d artifacts
```

Done when the `tvosApp`/`Vendor` diff prints nothing, MPVKit is still in-tree, Nightly CI files exist, and Android/artifact paths are gone. Grep the tree for merge markers (`<<<<<<<`) and fix any that remain in tracked files.

### 6. Commit and push

```sh
git commit -m "$(cat <<'EOF'
Merge bobsupra/NuvioTVOS main into the development fork.

Take upstream app, engine, and release updates, and keep this fork's tvOS-only layout, in-tree MPVKit, Nightly CI, and contributor identity.
EOF
)"

git push fork HEAD:main
```

Use a merge commit so `fork/main` can fast-forward without `--force`. Do not force-push `main`.

Done when `git ls-remote --heads fork refs/heads/main` is the merge commit.

### 7. Main-only branches

This fork stays on a single `main` after an overlay.

```sh
git push fork --delete <every fork branch except main>
git branch -D <every local branch except main>
git fetch fork --prune
```

Do not delete branches on `origin`. If this worktree cannot check out `main` because another worktree already has it, detach at the merge commit and delete the temporary `merge/upstream-main` branch.

Done when `git ls-remote --heads fork` lists only `main` and `git branch` lists only `main`.
