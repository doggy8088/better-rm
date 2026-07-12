# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- Protected `/mnt` and its immediate mount roots by default to prevent deleting Windows drives from WSL ([#9](https://github.com/doggy8088/better-rm/issues/9)).

### Added
- 1.4.3: Prepare release 1.4.3


### Added
- 1.4.2: Prepare release 1.4.2


### Added
- 1.4.1: Prepare release 1.4.1


### Added
- Added `install-hooks.sh` with `-a`/`--agent` selection and Claude Code support.
- Added project-level and `-g`/`--global` Claude Code hook installation with preserving JSON merges, backups, and idempotent updates.
- Added isolated installer integration tests in `test-install-hooks.sh`.
- Extended `install-hooks.sh` with `codex` agent support for project-level `.codex/hooks.json` installation (global mode not supported).
- Extended `install-hooks.sh` with `cursor` agent support for project-level `.cursor/hooks.json` installation (global mode not supported).

## [1.4.0] - 2026-07-12

### Added
- Bumped minor version to 1.4.0.

## [1.3.0] - 2026-07-11

### Added
- File restore capability (`rm --restore <file>`) to restore the last deleted version of a file to the current folder.
- Interactive overwrite prompts if a file with the same name already exists in the destination folder.
- `-f` (force) flag integration to automatically overwrite existing destination files without prompts.
- Expanded the test suite with a new section "測試 13: 還原功能" covering core restore operations, overwrite handling, and force mode.

## [1.2.1] - 2026-07-11

### Added
- Cross-agent hooks support for Cursor (`.cursor/hooks.json`), OpenCode (`.opencode/plugins/protect-important-paths.ts`), and Grok Build (`.grok/hooks/better-rm.json`)
- Added Cursor and Grok Build test suites to `test-hooks.js`

## [1.2.0] - 2026-07-11

### Added
- Cross-agent `PreToolUse` hooks for Claude Code, Codex, GitHub Copilot, Qoder, Google Antigravity (CLI / 2.0), and Pi coding agent
- Shared protected-directory policy for destructive `rm` and `rmdir` commands
- `BETTER_RM_PROTECTED_DIRS` support for adding project-specific protected paths
- Hook protocol and policy tests in `test-hooks.js` including Antigravity and Pi payload support
- Workspace configuration `.agents/hooks.json` for Google Antigravity
- Native TypeScript hook `.omp/hooks/pre/protect-important-paths.ts` and JSON configuration `.pi/hooks.json` for Pi coding agent

## [1.1.0] - 2025-12-09

### Added
- Timestamp and content hash appended to trashed filenames for better tracking and deduplication
- Filename format in trash: `filename__YYYYMMDD_HHMMSS_NNNNNNNNN__hash`
- MD5 hash calculation for file content (with SHA256 fallback)
- Directory hash calculation based on all contained files
- Nanosecond-precision timestamps to prevent filename collisions during rapid deletions
- Deletion log file (`.deletion_log`) in TRASH_DIR that records all deletion operations
  - Logs timestamp, original path, trash path, hash, and file type for each deletion
  - Format: `TIMESTAMP | ORIGINAL_PATH | TRASH_PATH | HASH | FILE_TYPE`
- Comprehensive test script (`test-better-rm.sh`) for validating all features
  - 28 test cases covering all functionality
  - Container-compatible for CI/CD integration
  - Detailed test documentation in TEST_README.md

### Changed
- Trashed files now always include timestamp and hash suffix (previously only added on conflicts)
- Improved directory hash calculation with secure handling of special characters

### Security
- Use `find -print0`, `sort -z`, and `xargs -0 -r` to safely handle filenames with special characters
- Prevent filename injection attacks when calculating directory hashes

### Fixed
- Empty directory hash calculation now works correctly
- Special characters in filenames are handled safely during hash calculation

## [1.0.0] - 2023-12-09

### Added
- Initial release of better-rm
- Safe file deletion by moving files to trash instead of permanent deletion
- Protected directory list to prevent accidental deletion of critical system directories
- Preserve original directory structure in trash
- Support for all common `rm` parameters (`-r`, `-f`, `-i`, `-v`, etc.)
- Customizable trash directory via `TRASH_DIR` environment variable
- Colored output for better user experience
- Protection for important directories (system, user home, Git repositories)

### Features
- Move files to `~/.Trash` instead of permanent deletion
- Maintain full path structure in trash for easy recovery
- Timestamp-based conflict resolution (legacy behavior, replaced in 1.1.0)
- Interactive and force modes
- Verbose output option
- Compatible with standard `rm` command syntax
