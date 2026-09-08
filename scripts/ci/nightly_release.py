#!/usr/bin/env python3
"""Helpers for the rolling Nightly IPA release."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

NIGHTLY_CHANGE_PATHS = (
    ".github/workflows/",
    "MPVKit/",
    "Vendor/",
    "scripts/",
    "supabase/",
    "tvosApp/",
)


def run(cmd: list[str], check: bool = True) -> str:
    result = subprocess.run(cmd, check=check, capture_output=True, text=True)
    return result.stdout.strip()


def short_sha(sha: str | None = None) -> str:
    if sha:
        return sha[:8]
    return run(["git", "rev-parse", "--short=8", "HEAD"])


def full_sha() -> str:
    return run(["git", "rev-parse", "HEAD"])


def last_successful_commit(repo: str, workflow: str, branch: str) -> str:
    """Return HEAD SHA of the newest successful workflow run on branch, or empty."""
    raw = run(
        [
            "gh",
            "run",
            "list",
            "--repo",
            repo,
            "--workflow",
            workflow,
            "--branch",
            branch,
            "--status",
            "success",
            "--limit",
            "5",
            "--json",
            "headSha,event,databaseId",
        ],
        check=False,
    )
    if not raw:
        return ""
    try:
        runs = json.loads(raw)
    except json.JSONDecodeError:
        return ""
    for item in runs:
        sha = item.get("headSha") or ""
        if sha:
            return sha
    return ""


def count_new_commits(since_sha: str) -> int:
    if not since_sha:
        return 1
    out = run(["git", "rev-list", "--count", f"{since_sha}..HEAD"], check=False)
    try:
        return int(out or "0")
    except ValueError:
        return 1


def has_code_changes(since_sha: str) -> bool:
    """Return whether code or app files changed since the last nightly commit."""
    if not since_sha:
        return True
    changed = run(
        [
            "git",
            "diff",
            "--name-only",
            f"{since_sha}..HEAD",
            "--",
            *NIGHTLY_CHANGE_PATHS,
        ],
        check=False,
    )
    return bool(changed)


def changelog(since_sha: str, until_sha: str) -> str:
    if not since_sha:
        lines = run(
            ["git", "log", "-10", "--pretty=format:- %s", until_sha],
            check=False,
        )
        return lines or "- Initial nightly build"
    range_spec = f"{since_sha}..{until_sha}"
    lines = run(["git", "log", "--pretty=format:- %s", range_spec], check=False)
    if not lines:
        return "- No commit messages available"
    return lines


def write_notes(
    path: Path,
    *,
    repo: str,
    version: str,
    build: str,
    nightly_version: str,
    commit: str,
    last_success: str,
    run_id: str,
    run_url: str,
    asset_name: str,
) -> None:
    built_at = datetime.now(timezone.utc)
    built_at_human = built_at.strftime("%a %b %d %H:%M:%S %Y")
    built_at_date = built_at.strftime("%Y-%m-%d")
    commit_url = f"https://github.com/{repo}/commit/{commit}"
    short = short_sha(commit)
    changes = changelog(last_success, commit)
    if last_success:
        compare = (
            f"[{short_sha(last_success)}...{short}]"
            f"(https://github.com/{repo}/compare/{last_success}...{commit})"
        )
    else:
        compare = f"[`{short}`]({commit_url})"

    body = f"""This is an ⚠️ **EXPERIMENTAL** ⚠️ Nightly build for commit [{commit}]({commit_url}).

Nightly builds are **development snapshots for testers**. They often contain bugs and unfinished work. Use at your own risk. Official releases stay on [bobsupra/NuvioTVOS](https://github.com/bobsupra/NuvioTVOS/releases).

## Build Info

Built at (UTC): `{built_at_human}`
Built at (UTC date): `{built_at_date}`
Commit SHA: `{commit}`
App version: `{version}` ({build})
Nightly version: `{nightly_version}`
Workflow: [run {run_id}]({run_url})

### What's Changed

{changes}

### Full Changelog: {compare}

## Download

Download **{asset_name}** from this release. The filename includes the app version, build date, workflow run, and source commit.

The IPA is **unsigned**. Sideload with Xcode, Apple Configurator, or your preferred signing tool.
"""
    path.write_text(body)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_last = sub.add_parser("last-successful-commit")
    p_last.add_argument("--repo", required=True)
    p_last.add_argument("--workflow", required=True)
    p_last.add_argument("--branch", default="main")

    p_count = sub.add_parser("count-new-commits")
    p_count.add_argument("since_sha")

    p_changes = sub.add_parser("has-code-changes")
    p_changes.add_argument("since_sha")

    p_notes = sub.add_parser("write-notes")
    p_notes.add_argument("--output", required=True)
    p_notes.add_argument("--repo", required=True)
    p_notes.add_argument("--version", required=True)
    p_notes.add_argument("--build", required=True)
    p_notes.add_argument("--nightly-version", required=True)
    p_notes.add_argument("--commit", required=True)
    p_notes.add_argument("--last-success", default="")
    p_notes.add_argument("--run-id", required=True)
    p_notes.add_argument("--run-url", required=True)
    p_notes.add_argument("--asset-name", required=True)

    args = parser.parse_args()

    if args.cmd == "last-successful-commit":
        print(last_successful_commit(args.repo, args.workflow, args.branch))
        return 0
    if args.cmd == "count-new-commits":
        print(count_new_commits(args.since_sha))
        return 0
    if args.cmd == "has-code-changes":
        print(str(has_code_changes(args.since_sha)).lower())
        return 0
    if args.cmd == "write-notes":
        write_notes(
            Path(args.output),
            repo=args.repo,
            version=args.version,
            build=args.build,
            nightly_version=args.nightly_version,
            commit=args.commit,
            last_success=args.last_success,
            run_id=args.run_id,
            run_url=args.run_url,
            asset_name=args.asset_name,
        )
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
