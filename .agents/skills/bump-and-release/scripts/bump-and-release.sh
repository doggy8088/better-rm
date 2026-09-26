#!/usr/bin/env bash
# shellcheck shell=bash
# Bump version and run release checks for the better-rm project.

set -euo pipefail

PROJECT=""
MODE=""
BUMP_MODE="patch"
BUMP_MODE_EXPLICIT=0
TARGET_VERSION=""
CHANGELOG_NOTE=""
DRY_RUN=0
APPLY=0
VERSION_PREFIX="v"
SKIP_CHANGELOG=0
AUTO_RELEASE=0
PUSH=1
CI_WAIT_TIMEOUT_SECONDS=1800
CI_WAIT_INTERVAL_SECONDS=15
CI_WORKFLOW_FILE="ci-release.yml"

RELEASE_FILES=(
  "CHANGELOG.md"
  "better-rm"
  "test-better-rm.sh"
  "install.sh"
  "install-hooks.sh"
  "README.md"
)

show_help() {
  cat <<'EOF'
Usage:
  bump-and-release.sh            自動化完成發佈建議流程（release + 檔案提交/打標籤/推播）
  bump-and-release.sh bump [options] [major|minor|patch]
  bump-and-release.sh bump [options] --to <version>
  bump-and-release.sh release [options]

Options:
  -r, --repo <path>        Git repository root (default: current Git root)
  -n, --dry-run            Show planned actions without writing files
  -a, --apply              Enable potentially destructive actions
  --auto                   Run full release flow automatically (add, commit, tag, push)
  --no-push                Skip push step in auto release flow
  --to <version>           Explicit target version for bump mode (e.g. 1.5.0)
  --skip-changelog         Skip moving [Unreleased] entries into a new version section
  --changelog-note <text>  Extra entry for the version section (default: "Prepare release <version>"
                           only when [Unreleased] has no entries)
  --tag-prefix <prefix>    Tag prefix for release (default: v)
  -h, --help               Show this help

  Note:
  若未指定 bump 類型，預設使用 patch。
  目前版本直接從 better-rm 取得，避免手動輸入。
  不輸入 mode 時預設執行 release；若當前版本標籤已存在，將停止並要求先 bump。
  不輸入其它參數時，會預設啟用 auto 模式，直接完成發佈流程（不再只是列出建議命令）。
  release 僅會完成測試、標記與推播；推播後會等待 `.github/workflows/ci-release.yml` 執行完成，
  並以繁中 Release Note 更新 Release 內容。

Examples:
  bump-and-release.sh                     # 一鍵走完整發佈流程
  bump-and-release.sh --no-push            # 一鍵走完但不推播
  bump-and-release.sh bump --repo ~/projects/better-rm minor
  bump-and-release.sh bump --repo ~/projects/better-rm
  bump-and-release.sh bump --repo ~/projects/better-rm --to 1.5.0
  bump-and-release.sh release --repo ~/projects/better-rm
  bump-and-release.sh release --repo ~/projects/better-rm --auto --no-push
EOF
}

parse_args() {
  if [[ $# -lt 1 ]]; then
    MODE="release"
    AUTO_RELEASE=1
    APPLY=1
    return
  fi

  if [[ "$1" == -* ]]; then
    MODE="release"
    APPLY=1
  else
    MODE="$1"
    shift
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -r|--repo)
        PROJECT="$2"
        shift 2
        ;;
      -n|--dry-run)
        DRY_RUN=1
        shift
        ;;
      -a|--apply)
        APPLY=1
        shift
        ;;
      --auto)
        AUTO_RELEASE=1
        shift
        ;;
      --no-push)
        PUSH=0
        shift
        ;;
      --skip-changelog)
        SKIP_CHANGELOG=1
        shift
        ;;
      --changelog-note)
        CHANGELOG_NOTE="$2"
        shift 2
        ;;
      --tag-prefix)
        VERSION_PREFIX="$2"
        shift 2
        ;;
      --to)
        TARGET_VERSION="$2"
        shift 2
        ;;
      -h|--help)
        show_help
        exit 0
        ;;
      major|minor|patch)
        if [[ "$BUMP_MODE_EXPLICIT" -eq 1 ]]; then
          echo "Duplicate bump mode: $1" >&2
          exit 2
        fi
        BUMP_MODE_EXPLICIT=1
        BUMP_MODE="$1"
        shift
        ;;
      *)
        echo "未知參數：$1" >&2
        exit 2
        ;;
    esac
  done
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "缺少指令：$1" >&2
    exit 2
  }
}

require_repo() {
  if [[ -z "$PROJECT" ]]; then
    PROJECT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  else
    PROJECT="$(cd "$PROJECT" && pwd)"
  fi
  if [[ -z "$PROJECT" ]]; then
    echo "請在 Git repository 中執行，或透過 --repo 指定專案路徑" >&2
    exit 2
  fi
  if ! git -C "$PROJECT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "不是有效的 Git 專案：$PROJECT" >&2
    exit 2
  fi
}

current_version() {
  local file="$PROJECT/better-rm"
  local version
  version="$(grep -m1 -E 'better-rm [0-9]+\.[0-9]+\.[0-9]+' "$file" | sed -E 's/.*better-rm ([0-9]+\.[0-9]+\.[0-9]+).*/\1/' || true)"
  if [[ -z "$version" ]]; then
    echo "無法在 better-rm 讀取目前版本" >&2
    exit 2
  fi
  echo "$version"
}

validate_version() {
  [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
    echo "版本格式必須為 x.y.z：$1" >&2
    exit 2
  }
}

next_version() {
  local current="$1"
  local mode="$2"
  IFS='.' read -r major minor patch <<< "$current"
  case "$mode" in
    major)
      major=$((major + 1))
      minor=0
      patch=0
      ;;
    minor)
      minor=$((minor + 1))
      patch=0
      ;;
    patch)
      patch=$((patch + 1))
      ;;
    *)
      echo "未知 bump 類型：$mode" >&2
      exit 2
      ;;
  esac
  echo "${major}.${minor}.${patch}"
}

replace_version() {
  local file="$1"
  local old_version="$2"
  local new_version="$3"

  if [[ ! -f "$file" ]]; then
    echo "缺少檔案：$file" >&2
    exit 2
  fi

  case "$file" in
    *better-rm)
      perl -0pi -e "s/echo \\\"better-rm ${old_version}\\\"/echo \\\"better-rm ${new_version}\\\"/" "$file"
      ;;
    *test-better-rm.sh)
      perl -0pi -e "s/better-rm ${old_version}/better-rm ${new_version}/g" "$file"
      ;;
    *install.sh|*README.md)
      perl -0pi -e "s/better-rm ${old_version}/better-rm ${new_version}/g" "$file"
      ;;
    *install-hooks.sh)
      OLD_VERSION="$old_version" NEW_VERSION="$new_version" \
        perl -0pi -e 's/(VERSION=")\Q$ENV{OLD_VERSION}\E(")/$1$ENV{NEW_VERSION}$2/' "$file"
      ;;
    *)
      perl -0pi -e "s/${old_version}/${new_version}/g" "$file"
      ;;
  esac
}

# 判斷 CHANGELOG 是否已有指定版本的段落標題（例如 "## [1.7.0] - 2026-09-26"）
changelog_has_version() {
  awk -v h="## [$1]" 'index($0, h) == 1 { found = 1; exit } END { exit !found }' "$PROJECT/CHANGELOG.md"
}

# 輸出 CHANGELOG 指定段落（版本號或 Unreleased）的內容，不含段落標題
changelog_section() {
  awk -v h="## [$1]" '
    index($0, h) == 1 { in_section = 1; next }
    in_section && /^## \[/ { exit }
    in_section { print }
  ' "$PROJECT/CHANGELOG.md"
}

# 將 [Unreleased] 的項目移至新的版本段落，並保留空的 [Unreleased] 段落供後續使用。
# 若未建立版本段落，下次發佈擷取 [Unreleased] 作為 Release Note 時會重複列出本版項目。
# 已有該版本段落時不做任何變更；note 非空時會加入該版本的 ### Added 區段，
# [Unreleased] 沒有任何項目時預設加入 "Prepare release <version>"。
cut_changelog_release() {
  local version="$1"
  local note="$2"
  local file="$PROJECT/CHANGELOG.md"
  local release_date
  local tmp

  if changelog_has_version "$version"; then
    echo "CHANGELOG 已有 ${version} 版本段落，略過建立。"
    return 0
  fi
  if ! grep -Fxq "## [Unreleased]" "$file"; then
    echo "未找到 Unreleased 段落，更新失敗" >&2
    return 1
  fi

  if [[ -z "$note" ]] && ! changelog_section "Unreleased" | grep -Eq '^[-*] '; then
    note="Prepare release ${version}"
  fi

  release_date="$(date '+%Y-%m-%d')"
  tmp="$(mktemp)"
  if ! awk -v v="$version" -v d="$release_date" -v n="$note" '
    $0 == "## [Unreleased]" && !inserted {
      print
      print ""
      print "## [" v "] - " d
      inserted = 1
      in_section = 1
      next
    }
    in_section && n != "" && $0 == "### Added" {
      print
      print "- " n
      n = ""
      next
    }
    in_section && /^## \[/ {
      if (n != "") {
        print "### Added"
        print "- " n
        print ""
        n = ""
      }
      in_section = 0
    }
    { print }
    END {
      if (in_section && n != "") {
        print ""
        print "### Added"
        print "- " n
      }
      if (!inserted) { exit 1 }
    }
  ' "$file" > "$tmp"; then
    echo "更新 CHANGELOG 失敗，未找到插入點" >&2
    rm -f "$tmp"
    return 1
  fi

  mv "$tmp" "$file"
  echo "已在 CHANGELOG 建立 ${version} 版本段落。"
}

run_bump() {
  local current next
  current="$(current_version)"
  if [[ -n "$TARGET_VERSION" ]]; then
    validate_version "$TARGET_VERSION"
    next="$TARGET_VERSION"
  elif [[ -n "$BUMP_MODE" ]]; then
    next="$(next_version "$current" "$BUMP_MODE")"
  else
    echo "請指定 bump 類型或 --to 版本" >&2
    exit 2
  fi

  if [[ "$current" == "$next" ]]; then
    echo "目前版本已是目標版本：$next"
    exit 2
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "DRY-RUN: ${current} -> ${next}"
    return 0
  fi

  for file in \
    "$PROJECT/better-rm" \
    "$PROJECT/test-better-rm.sh" \
    "$PROJECT/install.sh" \
    "$PROJECT/install-hooks.sh" \
    "$PROJECT/README.md"; do
    replace_version "$file" "$current" "$next"
  done

  if [[ "$SKIP_CHANGELOG" -eq 0 ]]; then
    cut_changelog_release "$next" "$CHANGELOG_NOTE"
  fi

  if ! grep -q "better-rm $next" "$PROJECT/better-rm"; then
    echo "版本更新失敗，請檢查檔案寫入" >&2
    exit 2
  fi
  echo "版本已更新：${current} -> ${next}"
}

run_release_checks() {
  require_command node
  if [[ -n "$(git -C "$PROJECT" status --porcelain)" ]]; then
    echo "發現未提交變更，建議先完成版本 bump 與暫存清單" >&2
    if [[ "$APPLY" -ne 1 ]]; then
      if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "DRY-RUN 模式：仍然會列出建議指令，但實際發佈前請先確保工作目錄乾淨" >&2
        return 0
      fi
      exit 2
    fi
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "DRY-RUN: 跳過測試執行"
    return 0
  fi

  (
    cd "$PROJECT"
    set -x
    ./test-better-rm.sh
    node ./test-hooks.js
    ./test-install-hooks.sh
  )
}

release_tag_exists() {
  local version="$1"
  local tag="${VERSION_PREFIX}${version}"
  if git -C "$PROJECT" show-ref --verify --quiet "refs/tags/${tag}"; then
    return 0
  fi
  return 1
}

run_release() {
  local version
  version="$(current_version)"
  local tag="${VERSION_PREFIX}${version}"
  local previous_tag
  previous_tag="$(git -C "$PROJECT" tag --sort=-creatordate | grep -m 1 "^${VERSION_PREFIX}[0-9]\+\.[0-9]\+\.[0-9]\+$" || true)"
  local previous_tag_or_head=""
  local changed
  local -a push_cmd=(git -C "$PROJECT" push origin HEAD --follow-tags)
  local branch
  local sha
  local release_notes_file
  local commit_summary
  local run_info
  local ci_run_status
  local ci_conclusion
  local ci_url
  local deadline
  local run_count=0
  local release_body
  local release_ready=0
  local release_files_list
  local commit_count
  local release_url

  branch="$(git -C "$PROJECT" rev-parse --abbrev-ref HEAD)"

  if release_tag_exists "$version"; then
    echo "目前版本 ${version} 已存在標籤 ${tag}，請先執行 bump 後再做 release。"
    exit 2
  fi

  run_release_checks

  # 確保 CHANGELOG 有本版段落，Release Note 才只會列出本版項目
  if ! changelog_has_version "$version"; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "DRY-RUN: CHANGELOG 尚無 ${version} 版本段落，將把 [Unreleased] 項目移至 ## [${version}]。"
    elif [[ "$AUTO_RELEASE" -eq 1 ]]; then
      cut_changelog_release "$version" "$CHANGELOG_NOTE"
    else
      echo "提醒：CHANGELOG 尚無 ${version} 版本段落，請先建立，以免下次 Release Note 重複列出本版項目。" >&2
    fi
  fi

  changed="$(git -C "$PROJECT" status --short -- "${RELEASE_FILES[@]}" || true)"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    if [[ -n "$changed" ]]; then
      echo "DRY-RUN: 要新增並提交 release 檔案如下："
      echo "$changed"
      echo "DRY-RUN: git -C \"$PROJECT\" add ${RELEASE_FILES[*]}"
      echo "DRY-RUN: git -C \"$PROJECT\" commit -m \"chore(release): bump to ${version}\""
    else
      echo "DRY-RUN: 目前版本檔案無待提交差異，將直接標記標籤。"
    fi
    echo "DRY-RUN: git -C \"$PROJECT\" tag -a \"${tag}\" -m \"Release ${tag}\""
    if [[ "$PUSH" -eq 1 ]]; then
      echo "DRY-RUN: ${push_cmd[*]}   # 推播後由 CI 建立 GitHub Release"
    else
      echo "DRY-RUN: 已設定 --no-push，跳過推播。"
    fi
    return 0
  fi

  if [[ "$AUTO_RELEASE" -eq 1 ]]; then
    if [[ -n "$changed" ]]; then
      git -C "$PROJECT" add "${RELEASE_FILES[@]}"
      if ! git -C "$PROJECT" diff --cached --quiet -- "${RELEASE_FILES[@]}"; then
        echo "發現版本相關變更，將自動提交："
        git -C "$PROJECT" commit -m "chore(release): bump to ${version}"
      else
        echo "未偵測到需提交的 release 變更。"
      fi
    else
      echo "未偵測到 release 相關未提交變更，將直接進行打標籤。"
    fi

    git -C "$PROJECT" tag -a "${tag}" -m "Release ${tag}"
    echo "已建立標籤：${tag}"
    # 必須在自動提交之後才取得 commit，CI 是在標籤指向的 commit 上執行
    sha="$(git -C "$PROJECT" rev-parse "${tag}^{commit}")"
    if [[ "$PUSH" -eq 1 ]]; then
      require_command gh
      echo "開始推播..."
      "${push_cmd[@]}"
      echo "已完成推播。CI 發佈流程會基於標籤建立 GitHub Release。"

      echo "等待 ${CI_WORKFLOW_FILE} CI 完成（標籤 ${tag}）。"
      deadline=$((SECONDS + CI_WAIT_TIMEOUT_SECONDS))
      while [[ $SECONDS -lt $deadline ]]; do
        run_count=$((run_count + 1))
        run_info="$(gh run list \
          --workflow "$CI_WORKFLOW_FILE" \
          --limit 20 \
          --json status,conclusion,url,headSha,createdAt \
          --jq 'map(select(.headSha == "'"$sha"'")) | sort_by(.createdAt) | reverse | if length > 0 then (.[0].status + "\t" + (.[0].conclusion // "") + "\t" + (.[0].url // "")) else "" end' \
          || true)"

        ci_run_status=""
        ci_conclusion=""
        ci_url=""
        if [[ -n "$run_info" ]]; then
          IFS=$'\t' read -r ci_run_status ci_conclusion ci_url <<< "$run_info"
        fi

        if [[ -z "$ci_run_status" ]]; then
          echo "未找到對應的 ci-release workflow 執行紀錄，稍後再查（已檢查 ${run_count} 次）。"
        elif [[ "$ci_run_status" == "completed" ]]; then
          if [[ "$ci_conclusion" == "success" ]]; then
            echo "CI 已完成，流程網址：${ci_url}"
            break
          fi
          echo "CI 結束但未成功，status=${ci_run_status}, conclusion=${ci_conclusion}。請先在 GitHub Actions 檢查後重試。"
          exit 2
        else
          echo "CI 執行中（status=${ci_run_status}，第 ${run_count} 次檢查）。"
        fi

        sleep "$CI_WAIT_INTERVAL_SECONDS"
      done

      if [[ -z "${ci_run_status-}" || "${ci_run_status}" != "completed" ]]; then
        echo "等待 CI 完成逾時（$CI_WAIT_TIMEOUT_SECONDS 秒）。"
        exit 2
      fi

      echo "確認 Release 物件建立中（標籤 ${tag}）。"
      deadline=$((SECONDS + CI_WAIT_TIMEOUT_SECONDS))
      while [[ $SECONDS -lt $deadline ]]; do
        if gh release view "${tag}" --json id >/dev/null 2>&1; then
          release_ready=1
          break
        fi
        echo "Release 尚未建立，等待中（第 ${run_count} 次）..."
        sleep "$CI_WAIT_INTERVAL_SECONDS"
        run_count=$((run_count + 1))
      done

      if [[ "$release_ready" -ne 1 ]]; then
        echo "等待 Release 建立逾時（$CI_WAIT_TIMEOUT_SECONDS 秒）。"
        exit 2
      fi

      previous_tag_or_head="$previous_tag"
      if [[ -z "$previous_tag_or_head" ]]; then
        previous_tag_or_head="${VERSION_PREFIX}${version}^"
      fi

      # 優先使用本版段落；未使用 --auto 建立版本段落時退回 [Unreleased]
      release_body="$(changelog_section "$version")"
      if [[ -z "$release_body" ]]; then
        release_body="$(changelog_section "Unreleased")"
      fi

      if [[ -z "$release_body" ]]; then
        release_body="- 尚未在 CHANGELOG.md 記錄本版變更，請以對應 PR 記錄補充。"
      fi

      if [[ -n "$previous_tag" ]]; then
        commit_summary="$(git -C "$PROJECT" log --no-color --pretty=format:"- %h %s" "$previous_tag_or_head..$tag" || true)"
        commit_count="$(git -C "$PROJECT" rev-list --count "$previous_tag_or_head..$tag" || true)"
      else
        commit_summary="$(git -C "$PROJECT" log --no-color --pretty=format:"- %h %s" -n 20 || true)"
        commit_count="$(git -C "$PROJECT" rev-list --count --max-count=20 "$previous_tag_or_head..$tag" || true)"
      fi
      release_files_list="$(git -C "$PROJECT" diff --name-only "$previous_tag_or_head..$tag" || true)"
      if [[ -z "$release_files_list" ]]; then
        release_files_list="- 無可追蹤變更檔案"
      fi
      release_url="$(gh release view "$tag" --json url --jq '.url' || true)"

      release_notes_file="$(mktemp)"
      {
        echo "## better-rm ${version} 發佈說明"
        echo ""
        echo "### 版本資訊"
        echo "- 版本：${version}"
        echo "- 標籤：${tag}"
        echo "- 發行分支：${branch}"
        echo "- Commit：${sha}"
        if [[ -n "$release_url" ]]; then
          echo "- Release 連結：${release_url}"
        fi
        echo "- Commit 數：${commit_count:-0}"
        echo "- 產生時間（UTC）：$(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        echo ""
        echo "### 重點更新"
        echo "$release_body"
        echo ""
        echo "### 變更檔案（版本內容）"
        while IFS= read -r file; do
          echo "- ${file}"
        done <<< "$release_files_list"
        echo ""
        echo "### 本次發布相關檔案"
        for file in "${RELEASE_FILES[@]}"; do
          echo "- ${file}"
        done
        echo ""
        echo "### Commit 摘要"
        if [[ -n "$commit_summary" ]]; then
          echo "$commit_summary"
        else
          echo "- 無可追蹤 commit 摘要"
        fi
      } > "$release_notes_file"

      echo "更新 GitHub Release 內容：${tag}"
      gh release edit "${tag}" --notes-file "$release_notes_file"
      rm -f "$release_notes_file"

      echo "Release Note 更新完成。"
    else
      echo "已設定 --no-push，已跳過推播。"
    fi
    return 0
  fi

  echo "版本檢查通過，建議後續指令："
  echo "  git -C \"$PROJECT\" add ${RELEASE_FILES[*]}"
  echo "  git -C \"$PROJECT\" commit -m \"chore(release): bump to ${version}\""
  echo "  git -C \"$PROJECT\" tag -a ${tag} -m \"Release ${tag}\""
  if [[ "$PUSH" -eq 1 ]]; then
    echo "  git -C \"$PROJECT\" push origin HEAD --follow-tags   # 推播後由 CI 建立 GitHub Release"
  else
    echo "  git -C \"$PROJECT\" push origin HEAD --follow-tags   # 已設定 --no-push，需手動改執行"
  fi
  echo "如不直接提交，請先確認已在 git diff 中檢視版本同步情形。"
}

main() {
  parse_args "$@"
  require_repo

  case "$MODE" in
    bump)
      run_bump
      ;;
    release)
      run_release
      ;;
    *)
      echo "不支援的模式：$MODE" >&2
      show_help
      exit 2
      ;;
  esac
}

main "$@"
