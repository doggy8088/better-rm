# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- `install-hooks.sh` 安裝 hook 時會偵測安裝當下提供 `node` 的 PATH 目錄，並寫入生成的 hook 指令（POSIX 寫成 `export PATH=<node 目錄>:"$PATH" && node …`；Copilot 的 PowerShell 變體以 `$env:PATH` 前綴，Windows 下並經 `cygpath` 轉換路徑）。先前指令只寫 `node …`，當 agent 以精簡 PATH 啟動 hook 時（例如 nvm 管理的 node 不在其中），hook 會以 `node: command not found` 非阻擋失敗，保護靜默失效。仍以 `node` 命令名呼叫，偵測到的目錄日後失效時會退回執行環境 PATH 上的其他 node。

## [1.8.0] - 2026-10-30

### Added
- `--purge` 的時間條件除天數外，新增週數（`2w`）、月數（`3m`，依日曆月份計算）與絕對日期時間（`2026-01-31`、`'2026-01-31 14:30'`、`2026-01-31T14:30:00`）；`--dry-run` 與確認提示會顯示實際截止時間。不存在的日期、超出範圍的時間與未來時間會被拒絕，純數字仍代表天數，行為與先前相同。
- 新增 `--purge-path <路徑>` 選項，依「原始路徑」前綴永久刪除垃圾桶項目：可單獨使用（不限時間），或與 `--purge <時間條件>` 並用（兩個條件都要符合）；可重複指定多個路徑，相對路徑以目前資料夾為基準。前綴以目錄為界（`/a/foo` 不會符合 `/a/foobar`），並會處理符號連結（如 macOS 的 `/tmp` → `/private/tmp`）與原目錄已不存在的情況。同樣會同步清除刪除日誌記錄，並支援 `--dry-run`。
- `--purge` 永久刪除項目後，會同步移除 `deletion.log` 與舊版 `$TRASH_DIR/.deletion_log` 中對應的刪除記錄（含被清除目錄內的項目）；`--dry-run` 會顯示預計清除的記錄數，且 `--dry-run`、取消確認或刪除失敗時不會修改日誌。
- 新增 `--list` 選項，列出垃圾桶中由 better-rm 移入的項目（刪除時間、大小、類型、原始路徑），依刪除時間由舊到新排序並顯示項目數、檔案/目錄/符號連結數與總佔用空間；可搭配 `--purge <時間條件>` 與 `--purge-path <路徑>` 當作篩選條件（只列出，不刪除）。項目輸出到 stdout、統計摘要輸出到 stderr，方便搭配管線。
- 新增 `--stats` 選項，顯示垃圾桶摘要統計：項目數與檔案/目錄/符號連結數、佔用空間、最早與最新刪除時間、依刪除時間分佈（1 天內、1–7 天、7–30 天、30–90 天、超過 90 天）以及依原始目錄統計的佔用空間前五名；可搭配 `--purge <時間條件>` 與 `--purge-path <路徑>` 當作篩選條件（只統計，不刪除）。

### Changed
- `--purge` 不加 `-f` 時，會先列出完整的待刪除項目清單（與 `--dry-run` 相同）再詢問 y/N 確認，避免只看到數量就誤刪；加 `-f` 的行為不變。

### Fixed
- 腳本結尾改為 `main "$@"; exit $?`：先前若在執行期間（例如 `--purge` 等待確認提示時）檔案被覆寫更新，bash 會在 `main` 結束後從舊的讀取位置繼續讀新內容，出現 `syntax error near unexpected token` 甚至執行到殘缺片段；現在 `main` 結束後立即結束，不再讀取後續內容。

## [1.7.1] - 2026-09-26

### Fixed
- 修正 `bump-and-release` 發佈腳本在自動提交版本變更後，仍以提交前的 commit 等待 `ci-release.yml`，導致等待逾時且未更新 Release Note 的問題。
- 修正 `bump-and-release` 發佈腳本未在 CHANGELOG 建立版本段落，導致 Release Note 重複列出歷史版本項目的問題；`bump` 與 `release --auto` 現在會將 `[Unreleased]` 項目移至 `## [<版本>] - <日期>` 段落，Release Note 也改為取自本版段落。
- 補上 CHANGELOG 中 1.7.0 的版本標題。

## [1.7.0] - 2026-09-26

### Added
- 新增 `--purge <天數>` 選項，依檔名中的刪除時間戳記永久刪除垃圾桶中超過指定天數的項目；預設先提示確認（`-f` 略過），`-v` 列出每個被刪除的項目，並會移除因此變空的路徑結構目錄。不符合 better-rm 檔名格式的檔案不受影響，且拒絕清除相對路徑或受保護的 `TRASH_DIR`。
- 新增 `--dry-run` 選項（搭配 `--purge`），只列出預計刪除的項目與各自大小並顯示預計釋放的磁碟空間，不實際刪除；確認提示與完成訊息也會顯示空間大小。

### Fixed
- 修復 `hooks/protect-important-paths.js` 在原生 Windows（Git Bash / MSYS / Cygwin）環境下 `/c/...` 與 `/cygdrive/c/...` 路徑未被正確轉為 Windows 磁碟機路徑解析而導致保護失效的問題，並增強 Windows 磁碟機根目錄（如 `C:\`、`D:\`）、系統目錄（`C:\Windows`、`C:\Program Files`、`C:\Users` 等）防護與不分大小寫比對 ([#14](https://github.com/doggy8088/better-rm/issues/14))。

## [1.6.0] - 2026-08-19

### Added
- 現代化多語系產品形象單頁（Landing Page）與 GitHub Pages 自動部署工作流程。
- 完整 SEO、OpenGraph 與 Twitter Card 標籤及 1200x630 社群分享縮圖。

### Fixed
- 修復 `hooks/protect-important-paths.js` 中換行符號未被當作命令分隔符號處理，導致多行指令（如 `echo ok\nrm -rf /usr`）繞過受保護路徑檢查的安全漏洞 ([#12](https://github.com/doggy8088/better-rm/pull/12))。
- 修復 Hook 在輸入無效時回傳 exit code 2，確保 Claude Code 能正確阻擋危險操作。
- 改用 `process.exitCode` 確保 stderr 訊息能在退出前正確輸出排空。

### Changed
- 更新 README 平台支援說明與維護者資訊。

## [1.5.0] - 2026-07-21

### Added
- 1.5.0: Prepare release 1.5.0

### Fixed
- Protected `/mnt` and its immediate mount roots by default to prevent deleting Windows drives from WSL ([#9](https://github.com/doggy8088/better-rm/issues/9)).
- Store deletion history outside `TRASH_DIR` to avoid macOS log write failures, while retaining legacy log fallback for restore operations ([#10](https://github.com/doggy8088/better-rm/issues/10)).

### Changed
- Added `BETTER_RM_STATE_DIR` and XDG state-directory support for `deletion.log`.
- Restricted newly created state directories and deletion logs to user-only access.

## [1.4.3] - 2026-07-12

### Added
- 1.4.3: Prepare release 1.4.3

## [1.4.2] - 2026-07-12

### Added
- 1.4.2: Prepare release 1.4.2

## [1.4.1] - 2026-07-12

### Added
- 1.4.1: Prepare release 1.4.1
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
