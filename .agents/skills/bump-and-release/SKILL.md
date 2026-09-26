---
name: bump-and-release
description: 自動化 better-rm 的版本提升與發佈前檢核，涵蓋版本字串同步、CHANGELOG 更新、必要測試、並輸出可重複執行的發佈步驟。
---

# bump-and-release

本技能適用於 `better-rm` 專案的版本流程，將版本提升、文件同步、發佈前檢查整合成可重複執行的流程。

## 使用時機

- 要求「minor / patch / major」版本提升。
- 針對新版本產生 `CHANGELOG` 下個版本項目。
- 準備 release 前要跑完整測試並驗證版本一致性。
- 需要列出發佈命令（提交、打標籤、推送）並讓 CI 建立 GitHub Release。

## 前置條件

- 目前工作目錄位於 `better-rm` 專案根目錄（或以 `--repo` 指定）。
- 需要安裝 `git`、`bash`、`node`。
- 需要安裝 `gh`（GitHub CLI），自動化 release 流程會用它更新 Release Note。
- `./test-better-rm.sh`、`./test-hooks.js`、`./test-install-hooks.sh` 可正常執行。

## 主要指令

### 0) 直接準備發版（預設行為）

```bash
./.agents/skills/bump-and-release/scripts/bump-and-release.sh
```

- 無參數時，預設會以 `release` 模式執行，並進入 `auto`，直接完成 release 流程（預設會嘗試 `add`、`commit`、`tag`、`push`）。
- 流程會先讀取目前 `better-rm` 版本並檢查 `refs/tags/<prefix><版本>` 是否已存在：
  - 若標籤已存在：直接停止，提醒先進行 bump。
  - 若標籤不存在：以目前版本進行 release 準備，不會再做版本位元調整。
  - 若 release 相關檔案無變更，將直接建立標籤；若有變更，會自動提交後再標籤。
- 若 `CHANGELOG.md` 尚無本版段落（例如 bump 時使用 `--skip-changelog`），會先將 `[Unreleased]` 的項目移至 `## [<版本>] - <日期>`，並一併納入 release commit。
- tag push 觸發後，流程會等待 `ci-release.yml` 在標籤指向的 commit 上完成，並在 Release 建立後自動使用 `gh release edit` 以**繁體中文**更新 Release Note；「重點更新」取自 `CHANGELOG.md` 的本版段落。
- 真正的 GitHub Release 物件建立仍由 GitHub Actions 的 `ci-release.yml` 負責。
- 預設會啟用 `--apply`，避免在本機工作目錄有未提交變更時中斷流程（這些變更若不在 release 檔案清單內，仍不會被提交到 release commit）。

```bash
./.agents/skills/bump-and-release/scripts/bump-and-release.sh --dry-run
./.agents/skills/bump-and-release/scripts/bump-and-release.sh --no-push
```

可用參數：

- `--auto`：明確指定自動執行 `release` 全流程。
- `--no-push`：保留提交與打標籤，但不推播到遠端。
- `--dry-run`：不實際寫入或執行，僅輸出預定動作。

### 1) 僅做版本更新與變更檔

```bash
./.agents/skills/bump-and-release/scripts/bump-and-release.sh bump --repo /path/to/better-rm <major|minor|patch>
./.agents/skills/bump-and-release/scripts/bump-and-release.sh bump --repo /path/to/better-rm --to 1.5.0
./.agents/skills/bump-and-release/scripts/bump-and-release.sh bump --repo /path/to/better-rm
```

- 會更新版本來源與驗證：
  - `better-rm`：`show_version` 顯示字串
  - `test-better-rm.sh`：`--version` 預期字串
  - `install.sh`：安裝指引中的版本字串
  - `install-hooks.sh`：`VERSION=` 字串
  - `README.md`：版本提示字串
- 預設會將 `CHANGELOG.md` 中 `[Unreleased]` 的項目移至新的 `## [<版本>] - <日期>` 段落，並保留空的 `[Unreleased]` 供後續使用，除非傳入 `--skip-changelog`。
  - 若 `[Unreleased]` 沒有任何項目，會自動加入 `Prepare release <版本>`。
  - `--changelog-note <文字>` 會將該文字加入本版段落的 `### Added` 區段。
  - 若本版段落已存在，則不做任何變更。
- 新版本計算錯誤或已存在於檔案中的版本會直接失敗，避免誤更新。

- 若不指定 `major` 或 `minor`，預設為 `patch`。
- 版本來源一律從 `better-rm` 讀取，避免手動輸入版本號。

### 2) 做版本提升並跑發佈前檢核

```bash
./.agents/skills/bump-and-release/scripts/bump-and-release.sh release --repo /path/to/better-rm
```

  先檢查 `git status` 是否乾淨與目前版本是否正確一致；若有未提交變更，`--apply` 允許繼續。`bump-and-release` 無參數啟動時會直接啟用類似自動流程，不再停在建議命令輸出。
- 依序執行：
  - `./test-better-rm.sh`
  - `node ./test-hooks.js`
  - `./test-install-hooks.sh`
- 若未指定 `--auto`，僅列出推薦發佈命令（包含 `git commit`、`git tag`、`git push`）。
- `git push` 會先觸發 CI 流程建立 GitHub Release，完成後腳本會改為直接更新對應 Release 的說明文字。
- 可搭配 `--dry-run` 僅檢查流程。

## 建議工作流程

1. `bump` 到目標版本並檢查 `git diff`，確認 `README.md`、`CHANGELOG.md`、版本輸出一致。
2. 進行提交與推播前，視需求執行 `release --repo <repo>` 取得建議發佈指令，或直接依流程提交。
3. 如需直接打 tag，執行輸出的 `git tag` 指令；發佈前再次檢查 `ci-release.yml` 是否無需額外修正。

## 參考資源

- 版本字串與更新目標：[`references/version-targets.md`](references/version-targets.md)

## 注意事項

- `ci-release.yml` 主要打包整個 git tree，不會逐一列舉要附加的發佈資產；此技能不修改 workflow。
- 版本字串的單位來源不採用 `package.json`，而是由 `better-rm` 腳本輸出與 `install-hooks.sh` 版本變數為準。
