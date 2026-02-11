# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## ⚡ Auto-Generated Releases

**Starting from v0.1.0**, release changelogs are **automatically generated** from commit messages using [Conventional Commits](https://www.conventionalcommits.org/).

**You don't need to manually update this file anymore!** The workflow will:
- Parse your commit types (`feat:`, `fix:`, etc.)
- Auto-bump the version (major/minor/patch)
- Generate a formatted changelog for each release

See [CONTRIBUTING.md](CONTRIBUTING.md) for commit message format.

---

## [Unreleased]

### Added
- (None yet)

### Changed
- (None yet)

### Fixed
- (None yet)

---

## [v0.1.0] - 2026-02-10

### Added
- Initial release of F3L Lua Training Script
- Working time tracking (9:00 total)
- Flight window tracking (6:00 max flight time)
- Landing detection and flight duration calculation
- Multiple flights per working time with double-press reset
- Voice announcements for flight time milestones
- Voice announcement for remaining working time (SF button)
- Working time end with triple-beep pattern
- Landing safety feature preventing instant re-launch

### Features
- Clean 1 Hz voice announcement logic
- FAI rule-compliant SC4 Vol F3 Soaring timing
- Minimal pilot distraction design
- Contest-oriented training workflow
- Display with tenths on screen

---

## Quick Reference

When you merge a PR using these commits:

| Commit Type | Version Change | Release Title |
|-------------|---|---|
| `feat:` | 0.1.0 → 0.2.0 | Minor bump |
| `fix:` | 0.1.0 → 0.1.1 | Patch bump |
| `BREAKING CHANGE:` | 0.1.0 → 1.0.0 | Major bump |

The release changelog is auto-generated in the GitHub Release page.

