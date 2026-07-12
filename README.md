# better-rm

給你一個更好、更安全的 `rm` 命令

## 專案簡介

`better-rm` 是一個 Linux/Unix 下的 `rm` 命令替代方案，主要目的是防止誤刪重要檔案與目錄。與傳統的 `rm` 命令不同，`better-rm` 不會永久刪除檔案，而是將檔案移至垃圾桶目錄，讓你有機會救回誤刪的檔案。

### 主要特色

- 🛡️ **安全保護**：防止刪除重要的系統目錄和專案目錄（如 `/`, `/home`, `/usr`, `.git` 等）
- ♻️ **垃圾桶機制**：將檔案移至垃圾桶而非永久刪除
- 📁 **保留目錄結構**：在垃圾桶中維持原始的完整路徑結構，方便日後還原
- 🔧 **完整相容**：支援所有常見的 `rm` 參數（`-r`, `-f`, `-i`, `-v` 等）
- ⚙️ **可自訂**：透過環境變數自訂垃圾桶位置
- 🎨 **友善介面**：彩色輸出，清楚顯示操作狀態

## 安裝方式

### 快速安裝（推薦）⚡

只需一行命令即可自動安裝：

```bash
curl -sSL https://raw.githubusercontent.com/doggy8088/better-rm/main/install.sh | bash
```

或使用 wget：

```bash
wget -qO- https://raw.githubusercontent.com/doggy8088/better-rm/main/install.sh | bash
```

安裝腳本會自動：
- ✅ 下載 better-rm 到 `~/.better-rm` 目錄
- ✅ 偵測你的 shell (bash/zsh) 並設定別名
- ✅ 加入 `alias rm='~/.better-rm/better-rm'` 到你的 shell 設定檔
- ✅ 提供清楚的後續步驟說明

安裝完成後，執行以下命令啟用：

```bash
source ~/.bashrc  # 如果使用 bash
# 或
source ~/.zshrc   # 如果使用 zsh
```

驗證安裝：

```bash
rm --version
```

---

### 方法一：手動使用別名

這種方法最安全，不會覆蓋系統原生的 `rm` 命令，需要時仍可使用 `/bin/rm` 存取原始命令。

1. 複製專案到本地目錄：

```bash
git clone https://github.com/doggy8088/better-rm.git ~/.better-rm
```

2. 設定別名，在 `~/.bashrc` 或 `~/.zshrc` 中加入以下內容：

```bash
# 使用 better-rm 替代 rm 命令
alias rm='~/.better-rm/better-rm'
```

3. 重新載入設定檔：

```bash
source ~/.bashrc  # 或 source ~/.zshrc
```

4. 驗證安裝：

```bash
rm --version
```

應該會看到 `better-rm 1.4.3` 的版本資訊。

**提示**：如果需要使用系統原生的 `rm` 命令，可以使用完整路徑 `/bin/rm` 或用反斜線 `\rm`。

### 方法二：手動複製到 PATH 目錄

如果你想讓 `better-rm` 可以直接執行（不只是透過 `rm` 別名），可以將它複製到 PATH 目錄：

```bash
# 下載專案
git clone https://github.com/doggy8088/better-rm.git
cd better-rm

# 複製到 /usr/local/bin（需要 sudo 權限）
sudo cp better-rm /usr/local/bin/
sudo chmod +x /usr/local/bin/better-rm

# 或複製到使用者的 bin 目錄（不需要 sudo）
mkdir -p ~/bin
cp better-rm ~/bin/
chmod +x ~/bin/better-rm

# 確保 ~/bin 在 PATH 中（在 ~/.bashrc 或 ~/.zshrc 加入）
export PATH="$HOME/bin:$PATH"
```

然後可以選擇性設定別名：

```bash
# 在 ~/.bashrc 或 ~/.zshrc 中加入
alias rm='better-rm'
```

重新載入設定檔：

```bash
source ~/.bashrc  # 或 source ~/.zshrc
```

## 使用方式

### 基本語法

```bash
rm [選項] [檔案或目錄...]
```

### 支援的選項

| 選項 | 說明 |
|------|------|
| `-r`, `-R`, `--recursive` | 遞迴刪除目錄及其內容 |
| `-f`, `--force` | 強制刪除，忽略不存在的檔案，不提示 |
| `-i` | 每次刪除前提示確認 |
| `-I` | 刪除超過三個檔案或遞迴刪除前提示一次 |
| `-v`, `--verbose` | 顯示詳細操作過程 |
| `--help` | 顯示說明訊息 |
| `--version` | 顯示版本資訊 |

### 使用範例

#### 刪除單一檔案

```bash
rm file.txt
```

#### 刪除目錄

```bash
rm -r directory/
```

#### 強制刪除（不提示）

```bash
rm -rf old_project/
```

#### 互動式刪除（每次都會詢問）

```bash
rm -i important_file.txt
```

#### 顯示詳細過程

```bash
rm -rv temp_folder/
```

#### 使用自訂垃圾桶目錄

```bash
TRASH_DIR=/tmp/my-trash rm file.txt
```

## 垃圾桶機制

### 預設位置

垃圾桶預設位於 `~/.Trash` 目錄。

### 目錄結構保留

當你刪除一個檔案時，`better-rm` 會在垃圾桶中保留原始的完整路徑結構。

**範例：**

如果你刪除 `/home/user/projects/myapp/src/main.js`，該檔案會被移動到：

```
~/.Trash/home/user/projects/myapp/src/main.js
```

這樣做的好處：
- 可以清楚知道檔案原本的位置
- 方便日後開發還原功能
- 避免不同路徑下同名檔案的衝突

### 檔案名稱格式

從 v1.1.0 開始，垃圾桶中的檔案名稱會自動加上時間戳記和內容雜湊值：

```
原始檔案: file.txt
垃圾桶中: file.txt__20251209_143052_123456789__e59ff97941044f85df5297e1c302d260
格式說明: filename__YYYYMMDD_HHMMSS_NNNNNNNNN__hash
```

這樣的設計有以下好處：
- 時間戳記包含奈秒精度，避免快速刪除時的檔名衝突
- 內容雜湊值可用於識別檔案內容，方便重複檔案的管理
- 可追蹤檔案的刪除時間

### 刪除日誌

`better-rm` 會在垃圾桶目錄中維護一個 `.deletion_log` 檔案，記錄所有刪除操作：

```bash
# 查看刪除日誌
cat ~/.Trash/.deletion_log
```

日誌格式：
```
TIMESTAMP | ORIGINAL_PATH | TRASH_PATH | HASH | FILE_TYPE
```

範例：
```
20251209_084530_429345278 | /home/user/file.txt | /home/user/.Trash/.../file.txt__...__hash | d6eb320... | file
20251209_084547_505346836 | /home/user/mydir | /home/user/.Trash/.../mydir__...__hash | c55e1b8... | directory
```

這個日誌可以幫助你：
- 追蹤所有刪除的檔案
- 找出特定檔案的刪除時間
- 確認檔案在垃圾桶中的位置
- 根據內容雜湊值找出重複的檔案

### 自訂垃圾桶位置

你可以透過 `TRASH_DIR` 環境變數來自訂垃圾桶位置：

```bash
# 暫時設定（單次使用）
TRASH_DIR=/tmp/trash rm file.txt

# 永久設定（在 ~/.bashrc 或 ~/.zshrc 中加入）
export TRASH_DIR="$HOME/MyTrash"
```

## 受保護的目錄

為了防止災難性的誤刪，`better-rm` 會拒絕刪除以下重要目錄：

### 系統目錄

- `/` - 根目錄
- `/bin` - 系統二進位檔案
- `/boot` - 開機相關檔案
- `/dev` - 裝置檔案
- `/etc` - 系統設定檔
- `/home` - 使用者主目錄根目錄
- `/lib`, `/lib64` - 系統函式庫
- `/mnt` 與其第一層掛載根目錄 - 掛載磁碟（例如 WSL 的 `/mnt/c`、`/mnt/d`、`/mnt/wsl`、`/mnt/wslg`）
- `/opt` - 第三方軟體
- `/proc` - 程序資訊
- `/root` - root 使用者的家目錄
- `/sbin` - 系統管理二進位檔案
- `/sys` - 系統資訊
- `/usr` - 使用者程式
- `/var` - 變動資料

### 使用者目錄

- `~` 或 `$HOME` - 你的家目錄（整個目錄）

### 專案目錄

- `.git` - Git 版本控制目錄（任何位置的 .git 目錄）

`/mnt` 的保護只涵蓋掛載根本身；仍可正常移除 `/mnt/c/project/tmp` 等掛載磁碟內的項目。
WSL 可透過 `/etc/wsl.conf` 更改 Windows 磁碟的 automount root；非預設位置不在本規則的保護範圍內。

## Coding agent hooks

本專案提供共用的 `PreToolUse` 防護程式，讓支援 hooks 的 coding agent 在執行
`rm` 或 `rmdir` 前檢查目標路徑。下列專案層級設定會自動載入同一支程式：

| Coding agent | 設定檔 |
|---|---|
| Claude Code | `.claude/settings.json` |
| Codex | `.codex/hooks.json` |
| GitHub Copilot CLI／cloud agent | `.github/hooks/better-rm.json` |
| Antigravity CLI／2.0 | `.agents/hooks.json` |
| Qoder | `.qoder/settings.json` |
| Pi | `.omp/hooks/pre/protect-important-paths.ts` (native) / `.pi/hooks.json` (JSON) |
| Cursor | `.cursor/hooks.json` |
| OpenCode | `.opencode/plugins/protect-important-paths.ts` |
| Grok Build | `.grok/hooks/better-rm.json` |

預設保護範圍與 `better-rm` 相同：系統根目錄、使用者家目錄，以及任何位置的
`.git` 目錄。若要加入其他重要目錄，請以平台的 PATH 分隔字元設定
`BETTER_RM_PROTECTED_DIRS`：

```bash
export BETTER_RM_PROTECTED_DIRS="/srv/data:/workspace/secrets"
```

hooks 執行時需要 `node` 可用。Codex 還會要求使用者透過 `/hooks` 審閱並信任
專案 hook；其他代理也可能依各自的安全設定要求確認。

### 自動安裝 Coding Agent hooks / Automatic Coding Agent hook installation

`install-hooks.sh` 目前已支援下列 Agent：`claude`、`codex`、`cursor`、`copilot`、`antigravity`、`qoder`、`pi`、`opencode`、`grok`。

推薦用一行指令（自動抓取最新 Release）：

```bash
curl -sSL https://github.com/doggy8088/better-rm/releases/latest/download/install-hooks.sh | bash -s -- -a claude
```

如果有需要全域安裝 Claude 設定：

```bash
curl -sSL https://github.com/doggy8088/better-rm/releases/latest/download/install-hooks.sh | bash -s -- -a claude --global
```

使用 `-a` 或 `--agent` 指定 Agent；預設會安裝到目前目錄所屬 Git 專案的對應設定檔：

```bash
# 安裝到目前 Git 專案 / Install into the current Git project
~/.better-rm/install-hooks.sh -a claude
~/.better-rm/install-hooks.sh --agent codex
~/.better-rm/install-hooks.sh --agent cursor
~/.better-rm/install-hooks.sh --agent copilot
~/.better-rm/install-hooks.sh --agent antigravity
~/.better-rm/install-hooks.sh --agent qoder
~/.better-rm/install-hooks.sh --agent pi
~/.better-rm/install-hooks.sh --agent opencode
~/.better-rm/install-hooks.sh --agent grok

# 安裝到 Claude Code 全域設定 / Install into Claude Code global settings（僅此支援 --global）
~/.better-rm/install-hooks.sh --agent claude --global
```

專案模式可從 Git 儲存庫內的任何子目錄執行。`--global` 目前僅 Claude Code 支援；其他 Agent 僅可在專案模式。
Claude Code 的全域模式會寫入
`${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json`，且不要求目前目錄是 Git
儲存庫。其他 Agent 會寫入專案根目錄對應設定檔：`.claude/settings.json`（claude）、`.codex/hooks.json`（codex）、`.cursor/hooks.json`（cursor）、`.github/hooks/better-rm.json`（copilot）、`.agents/hooks.json`（antigravity）、`.qoder/settings.json`（qoder）、`.pi/hooks.json`（pi）、`.opencode/plugins/protect-important-paths.ts`（opencode）與`.grok/hooks/better-rm.json`（grok）。
安裝程式會保留其他設定與 hooks，只新增或更新目標 hook；修改既有檔案前會建立時間戳備份，重複執行時不會加入重複項目或重寫已是最新狀態的檔案。

自動安裝的 hook 會放在設定檔同目錄，例如
`.claude/settings.json` 對應 `.claude/protect-important-paths.js`，
`.codex/hooks.json` 對應 `.codex/protect-important-paths.js`。  
建議不再依賴 `install-hooks.sh` 執行路徑，已安裝的 hook 僅依賴各 Agent 的
設定目錄中對應的 `protect-important-paths.js`，若移動或刪除該目錄需重跑安裝程式。
`install.sh` 與 `install-hooks.sh` 是分開的步驟，不會在安裝 `rm` 別名時自動修改
Agent 設定。變更設定後，可能需要重新啟動相應 Agent 或開啟新的 session。

下方手動設定範例仍適用於 hook 檔案已提交在目標專案中的情況；其中
`git rev-parse --show-toplevel` 會從該專案載入 hook。對於 OpenCode，請參考下方 plugin 範例。

### 各個 Coding Agent 的安裝與設定說明 / Detailed Agent Configurations

本專案支援將防護機制嵌入多種熱門的 AI Coding Agent。以下是為各代理設定 `PreToolUse` 的詳細說明：

#### 1. Claude Code
* **設定檔位置**：`.claude/settings.json`
* **設定內容**：
  ```json
  {
    "hooks": {
      "PreToolUse": [
        {
          "matcher": "Bash",
          "hooks": [
            {
              "type": "command",
              "command": "node \"$(git rev-parse --show-toplevel)/hooks/protect-important-paths.js\"",
              "timeout": 5,
              "statusMessage": "Checking protected directories..."
            }
          ]
        }
      ]
    }
  }
  ```
* **說明**：Claude Code 在執行 `Bash` 工具前，會先呼叫此 hook 檢查指令是否包含刪除受保護目錄的指令。

#### 2. Codex
* **設定檔位置**：`.codex/hooks.json`
* **設定內容**：結構與 Claude Code 相同。
* **說明**：載入設定檔後，請在 Codex 介面中執行 `/hooks` 來審閱並信任此專案 hook，以使防護生效。

#### 3. GitHub Copilot CLI / Cloud Agent
* **設定檔位置**：`.github/hooks/better-rm.json`
* **設定內容**：
  ```json
  {
    "version": 1,
    "hooks": {
      "preToolUse": [
        {
          "type": "command",
          "bash": "node \"$(git rev-parse --show-toplevel)/hooks/protect-important-paths.js\"",
          "powershell": "node \"$(git rev-parse --show-toplevel)\\hooks\\protect-important-paths.js\"",
          "matcher": "bash|powershell",
          "timeoutSec": 5
        }
      ]
    }
  }
  ```
* **說明**：Copilot 會依據作業系統選擇執行 `bash` 或 `powershell` 版指令。

#### 4. Antigravity CLI / Antigravity 2.0
* **設定檔位置**：`.agents/hooks.json`
* **設定內容**：
  ```json
  {
    "better-rm-protection": {
      "PreToolUse": [
        {
          "matcher": "run_command",
          "hooks": [
            {
              "type": "command",
              "command": "node \"$(git rev-parse --show-toplevel)/hooks/protect-important-paths.js\"",
              "timeout": 5
            }
          ]
        }
      ]
    }
  }
  ```
* **說明**：Antigravity 透過攔截 `run_command` 工具來防止對受保護目錄的刪除動作。若被阻擋會直接向 agent 回傳拒絕訊息。

#### 5. Qoder
* **設定檔位置**：`.qoder/settings.json`
* **設定內容**：
  ```json
  {
    "hooks": {
      "PreToolUse": [
        {
          "matcher": "Bash",
          "hooks": [
            {
              "type": "command",
              "command": "node \"$(git rev-parse --show-toplevel)/hooks/protect-important-paths.js\""
            }
          ]
        }
      ]
    }
  }
  ```

#### 6. Pi Coding Agent
Pi 支援兩種整合方式，您可以選擇其中一種：
* **方式 A：原生 TypeScript Hook (推薦)**
  * **路徑**：`.omp/hooks/pre/protect-important-paths.ts`
  * **內容**：
    ```typescript
    import type { HookAPI } from "@oh-my-pi/pi-coding-agent/extensibility/hooks";
    // @ts-ignore
    import { evaluate } from "../../../hooks/protect-important-paths";

    export default function hook(pi: HookAPI): void {
      pi.on("tool_call", async (event, ctx) => {
        if (event.toolName === "bash") {
          const command = event.input.command as string;
          const cwd = (ctx as any)?.cwd || process.cwd();

          const payload = {
            tool_input: { command },
            cwd
          };

          const result = evaluate(payload);
          if (result && result.hookSpecificOutput?.permissionDecision === "deny") {
            return {
              block: true,
              reason: result.hookSpecificOutput.permissionDecisionReason
            };
          }
        }
      });
    }
    ```
* **方式 B：JSON 設定檔 (透過社群擴充套件如 `pi-hooks`)**
  * **路徑**：`.pi/hooks.json`
  * **內容**：
    ```json
    {
      "hooks": {
        "PreToolUse": [
          {
            "matcher": "Bash",
            "hooks": [
              {
                "type": "command",
                "command": "node \"$(git rev-parse --show-toplevel)/hooks/protect-important-paths.js\"",
                "timeout": 5,
                "statusMessage": "Checking protected directories..."
              }
            ]
          }
        ]
      }
    }
    ```

#### 7. Cursor
* **設定檔位置**：`.cursor/hooks.json`
* **設定內容**：
  ```json
  {
    "version": 1,
    "hooks": {
      "beforeShellExecution": [
        {
          "command": "node \"$(git rev-parse --show-toplevel)/hooks/protect-important-paths.js\"",
          "matcher": ".*"
        }
      ]
    }
  }
  ```
* **說明**：Cursor 在執行 `beforeShellExecution` 生命週期事件前會先執行此 hook。當判定為高風險時，回傳 `permission: "deny"` 將其完全阻擋。

#### 8. OpenCode
* **路徑**：`.opencode/plugins/protect-important-paths.ts`
* **補充**：`install-hooks.sh -a opencode` 會一併安裝共用 runtime 到專案 `hooks/protect-important-paths.js`，供插件在 `../../hooks/protect-important-paths` 匯入。
* **內容**：
  ```typescript
  import type { Plugin } from "@opencode-ai/plugin";
  // @ts-ignore
  import { evaluate } from "../../hooks/protect-important-paths";

  export const ProtectImportantPathsPlugin: Plugin = async (ctx) => {
    return {
      "tool.execute.before": async (input, output) => {
        if (input.tool === "bash") {
          const command = output.args.command;
          const cwd = (ctx as any)?.directory || process.cwd();

          const payload = {
            tool_input: { command },
            cwd
          };

          const result = evaluate(payload);
          if (result && result.hookSpecificOutput?.permissionDecision === "deny") {
            throw new Error(result.hookSpecificOutput.permissionDecisionReason);
          }
        }
      },
    };
  };

  export default ProtectImportantPathsPlugin;
  ```
* **說明**：OpenCode 會在啟動時自動載入此 TypeScript 插件。該插件會在執行 `bash` 工具前攔截指令並執行檢查，若判定為高風險刪除動作將拋出錯誤以阻止執行。

#### 9. Grok Build
* **設定檔位置**：`.grok/hooks/better-rm.json`
* **設定內容**：
  ```json
  {
    "hooks": {
      "PreToolUse": [
        {
          "matcher": "Bash",
          "hooks": [
            {
              "type": "command",
              "command": "node \"$(git rev-parse --show-toplevel)/hooks/protect-important-paths.js\"",
              "timeout": 5
            }
          ]
        }
      ]
    }
  }
  ```
* **說明**：Grok Build 會讀取 `.grok/hooks/` 目錄下的所有 JSON 檔以載入 hooks。當偵測到危險指令時，本防護程式會回傳 `{"decision": "deny", "reason": "..."}` 供其阻擋指令的執行。請注意，專案層級的 hooks 首次執行時可能需要藉由 TUI 中的 `/hooks-trust` 或是帶有 `--trust` 參數啟動以取得授權。



這些 hooks 是額外防護欄，不是作業系統層級的安全邊界。目前只檢查 coding
agent 透過已支援 shell 工具送出的 `rm` 與 `rmdir` 命令；無法防止代理未攔截
的工具路徑、停用 hooks 後的操作，或使用者在代理外直接執行的命令。

### 保護機制

當你嘗試刪除受保護的目錄時，`better-rm` 會：

1. 顯示錯誤訊息
2. 拒絕執行刪除操作
3. 提示這是重要的系統或專案目錄

**範例：**

```bash
$ rm -rf /
錯誤 (Error): 拒絕刪除受保護的目錄: '/'
錯誤 (Error): Refused to remove protected directory: '/'
錯誤 (Error): 這是一個重要的系統目錄或專案目錄！
錯誤 (Error): This is a critical system or project directory!
```

## 清理垃圾桶

`better-rm` 目前不會自動清理垃圾桶，你可以手動清理：

### 檢視垃圾桶內容

```bash
ls -la ~/.Trash/
```

### 清空垃圾桶

```bash
# 使用系統原生的 rm 命令（請小心！）
/bin/rm -rf ~/.Trash/*
```

### 還原檔案 / Restore Files

`better-rm` 提供了自動與手動還原功能：

#### 1. 自動還原（推薦）
您可以使用 `--restore` 選項來將最後一次刪除的檔案或目錄還原至**目前資料夾**：

```bash
rm --restore LICENSE
```

- **重名保護機制**：若目前資料夾已存在同名檔案或目錄，`better-rm` 會提示您是否確認覆蓋（`y/N`）。
- **強制覆蓋**：如果您希望直接覆蓋而不顯示提示，可以加上 `-f` 參數：
  ```bash
  rm -f --restore LICENSE
  ```

#### 2. 手動還原
由於被刪除的檔案在垃圾桶中仍保留了原始的完整路徑結構，您也可以使用系統原生的 `mv` 命令手動移回。
請至 `~/.Trash/.deletion_log` 或垃圾桶中找到您的檔案，然後手動移動：

```bash
# 手動還原範例
mv ~/.Trash/home/user/projects/myapp/file.txt__20251209_143052_123456789__hash /home/user/projects/myapp/file.txt
```

## 技術細節

### 相容性

- **作業系統**：Linux, macOS, Unix-like 系統
- **Shell**：Bash 4.0+
- **依賴**：基本的 Unix 工具（`mv`, `mkdir`, `readlink`/`realpath`）

### 限制

1. **跨檔案系統移動**：如果垃圾桶和原始檔案在不同的檔案系統（如不同的硬碟分割區），移動操作可能會比較慢。
2. **磁碟空間**：垃圾桶會佔用磁碟空間，需要定期清理。
3. **權限問題**：如果你沒有權限移動某個檔案，操作會失敗。

## 安全性考量 / Security Considerations

### ⚠️ 使用限制與風險 / Limitations and Risks

**重要：請在使用前充分了解以下限制**

1. **不是完整備份解決方案**
   - 垃圾桶機制僅提供基本的誤刪保護
   - 無法防護硬碟故障、系統故障、惡意軟體等風險
   - 重要資料必須有獨立的備份策略

2. **磁碟空間限制**
   - 垃圾桶會持續佔用磁碟空間
   - 可能導致磁碟空間不足的問題
   - 需要定期手動清理

3. **跨檔案系統限制**
   - 跨不同檔案系統的移動會較慢（需要複製而非移動）
   - 可能會遇到權限問題

4. **無保證性**
   - 本工具按「現況」提供，無任何保證
   - 作者不對任何資料遺失負責
   - 使用者需自行承擔風險

**Important: Please fully understand the following limitations before use**

1. **Not a Complete Backup Solution**
   - Trash mechanism only provides basic accidental deletion protection
   - Cannot protect against drive failure, system failure, malware, etc.
   - Important data must have an independent backup strategy

2. **Disk Space Limitation**
   - Trash continuously occupies disk space
   - May cause disk space shortage
   - Requires regular manual cleanup

3. **Cross-Filesystem Limitation**
   - Moving across different filesystems is slower (requires copy instead of move)
   - May encounter permission issues

4. **No Warranty**
   - This tool is provided "AS IS" without any warranty
   - Author is not responsible for any data loss
   - Users assume all risks

### 為什麼需要 better-rm？

在使用 AI 輔助編程工具（如 Claude Code, GitHub Copilot 等）時，AI 可能會建議執行一些危險的命令，例如：

```bash
rm -rf ~/  # 刪除整個家目錄！
rm -rf /   # 刪除整個系統！
```

這些命令一旦執行，後果不堪設想。`better-rm` 提供了一層防護網，即使不小心執行了這些命令，也不會造成永久性損害。

### 最佳實踐

1. **謹慎使用 `-f` 選項**：強制模式會跳過確認，建議先不加 `-f` 測試。
2. **定期清理垃圾桶**：避免佔用過多磁碟空間。
3. **重要檔案另外備份**：雖然有垃圾桶，但重要資料還是要有完整的備份策略。
4. **了解保護清單**：知道哪些目錄受到保護，避免驚訝。

## 疑難排解

### 問題：找不到 rm 命令 / Command not found

**解決方法：**

1. 如果您使用**快速安裝（推薦）**或**方法一（手動別名）**，可能是因為尚未重新載入 shell 設定檔。請執行以下命令以重新載入，或重啟終端機：
   ```bash
   source ~/.bashrc  # 如果使用 bash
   # 或
   source ~/.zshrc   # 如果使用 zsh
   ```

2. 如果您使用**方法二（複製到 PATH）**：
   - 請檢查 `~/bin` 或 `/usr/local/bin` 是否已加入 `PATH` 中（可以使用 `echo $PATH` 檢視）。
   - 確保已重新載入設定檔。

### 問題：提示權限被拒 / Permission denied

**解決方法：**

請確保 `better-rm` 檔案具備執行權限。依據您的安裝方式，執行對應的指令：

- 若使用**快速安裝**或**方法一（手動別名）**：
  ```bash
  chmod +x ~/.better-rm/better-rm
  ```
- 若使用**方法二（複製到 PATH）**：
  ```bash
  chmod +x ~/bin/better-rm
  # 或如果是複製到 /usr/local/bin（需要 sudo）
  sudo chmod +x /usr/local/bin/better-rm
  ```

### 問題：垃圾桶佔用太多空間

**解決方法：**

定期清理垃圾桶：
```bash
# 清理 30 天前的檔案
find ~/.Trash -mtime +30 -delete
```

### 問題：想要使用原生的 rm 命令

**解決方法：**

使用完整路徑呼叫系統原生的 rm：
```bash
/bin/rm file.txt
```

或用反斜線暫時繞過別名（bypass alias）：
```bash
\rm file.txt
```

## 未來計畫

- [x] 實作還原功能（`rm --restore`）
- [ ] 自動清理過期的垃圾檔案
- [ ] 提供垃圾桶管理介面
- [ ] 支援更多自訂保護規則
- [ ] 加入設定檔支援

## 測試

本專案包含完整的測試腳本，可在容器環境下測試所有功能：

```bash
# 執行測試
./test-better-rm.sh

# 在 Docker 容器中測試
docker run -v $(pwd):/app ubuntu:latest bash /app/test-better-rm.sh
```

測試涵蓋：
- ✅ 基本檔案與目錄刪除
- ✅ 特殊字元檔名處理
- ✅ 時間戳記與內容 Hash
- ✅ 刪除日誌功能
- ✅ 受保護目錄
- ✅ 快速連續刪除
- ✅ 符號連結處理
- ✅ 命令參數選項

詳細測試說明請參考 [TEST_README.md](TEST_README.md)

## 貢獻

歡迎提交 Issue 和 Pull Request！

### 開發指南

1. Fork 本專案
2. 建立你的特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交你的變更 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 開啟 Pull Request

## 授權

本專案採用 MIT 授權條款 - 詳見 [LICENSE](LICENSE) 檔案

## 致謝

感謝所有為更安全的命令列環境做出貢獻的開發者。

## 聯絡方式

如有任何問題或建議，歡迎透過 GitHub Issues 與我們聯繫。

---
## ⚠️ 重要免責聲明 / Important Disclaimer

**使用本工具前請務必詳讀以下聲明：**

🔴 **本工具僅提供基本的安全防護層，不能取代完整的備份策略**
- 此工具將檔案移至垃圾桶，但垃圾桶仍在同一個檔案系統上
- 硬碟故障、系統損壞、意外格式化等情況仍會導致資料永久遺失
- **請務必定期備份重要資料到外部儲存裝置或雲端服務**

🔴 **本工具按「現況」提供，不提供任何明示或暗示的保證**
- 作者不對使用本工具造成的任何資料遺失或損害負責
- 本工具可能存在未知的 bug 或相容性問題
- 使用者需自行承擔使用風險

🔴 **本工具不應在生產環境或關鍵系統上使用，除非您完全了解其運作方式**
- 建議先在測試環境中充分測試
- 了解垃圾桶機制的限制（如磁碟空間、跨檔案系統移動等）
- 確保您知道如何使用原生 `rm` 命令（`/bin/rm` 或 `\rm`）

🔴 **垃圾桶不會自動清理，需要定期手動管理**
- 垃圾桶會持續佔用磁碟空間
- 建議定期檢查和清理垃圾桶內容
- 長期累積可能導致磁碟空間不足

**English Version:**

🔴 **This tool provides only basic safety protection and CANNOT replace a complete backup strategy**
- Files are moved to trash, but the trash is still on the same filesystem
- Hard drive failure, system corruption, or accidental formatting can still cause permanent data loss
- **Always maintain regular backups of important data to external storage or cloud services**

🔴 **This tool is provided "AS IS" without any warranties, express or implied**
- The author is not responsible for any data loss or damage caused by using this tool
- This tool may contain unknown bugs or compatibility issues
- Users assume all risks associated with its use

🔴 **This tool should NOT be used in production or critical systems unless you fully understand how it works**
- Test thoroughly in a non-production environment first
- Understand the limitations of the trash mechanism (disk space, cross-filesystem moves, etc.)
- Ensure you know how to use the native `rm` command (`/bin/rm` or `\rm`)

🔴 **The trash is NOT automatically cleaned and requires manual management**
- Trash continuously occupies disk space
- Regularly check and clean trash contents
- Long-term accumulation may lead to insufficient disk space

---

## ⚠️ 再次提醒 / Final Reminder

**本工具不能也不應該取代完整的備份策略！**

- ✅ **請做好**：定期備份重要資料到外部儲存或雲端
- ✅ **請做好**：了解工具的限制和風險
- ✅ **請做好**：在測試環境先充分測試
- ✅ **請做好**：定期清理垃圾桶
- ❌ **請勿**：依賴垃圾桶作為唯一的資料保護措施
- ❌ **請勿**：在關鍵生產系統上未經測試就使用
- ❌ **請勿**：假設垃圾桶中的資料永遠安全

**This tool CANNOT and SHOULD NOT replace a complete backup strategy!**

- ✅ **DO**: Regularly backup important data to external storage or cloud
- ✅ **DO**: Understand the tool's limitations and risks
- ✅ **DO**: Test thoroughly in a test environment first
- ✅ **DO**: Regularly clean the trash
- ❌ **DON'T**: Rely on the trash as your only data protection measure
- ❌ **DON'T**: Use in critical production systems without testing
- ❌ **DON'T**: Assume data in trash is permanently safe

**使用本工具即表示您已閱讀、理解並同意上述所有免責聲明和限制。**

**By using this tool, you acknowledge that you have read, understood, and agreed to all the disclaimers and limitations stated above.**
