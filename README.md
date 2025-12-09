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
git clone https://github.com/doggy8088/better-rm.git ~/better-rm
```

2. 設定別名，在 `~/.bashrc` 或 `~/.zshrc` 中加入以下內容：

```bash
# 使用 better-rm 替代 rm 命令
alias rm='~/better-rm/better-rm'
```

3. 重新載入設定檔：

```bash
source ~/.bashrc  # 或 source ~/.zshrc
```

4. 驗證安裝：

```bash
rm --version
```

應該會看到 `better-rm 1.0.0` 的版本資訊。

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

### 檔案名稱衝突處理

如果垃圾桶中已經存在相同路徑的檔案，`better-rm` 會自動在檔案名稱後加上時間戳記，例如：

```
~/.Trash/home/user/file.txt
~/.Trash/home/user/file.txt_20231209_143022
```

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

### 還原檔案

由於檔案保留了原始路徑結構，你可以輕鬆還原：

```bash
# 手動還原檔案
mv ~/.Trash/home/user/projects/myapp/file.txt /home/user/projects/myapp/
```

> **注意：** 未來版本計畫提供自動還原功能。

## 技術細節

### 相容性

- **作業系統**：Linux, macOS, Unix-like 系統
- **Shell**：Bash 4.0+
- **依賴**：基本的 Unix 工具（`mv`, `mkdir`, `readlink`/`realpath`）

### 限制

1. **跨檔案系統移動**：如果垃圾桶和原始檔案在不同的檔案系統（如不同的硬碟分割區），移動操作可能會比較慢。
2. **磁碟空間**：垃圾桶會佔用磁碟空間，需要定期清理。
3. **權限問題**：如果你沒有權限移動某個檔案，操作會失敗。

## 安全性考量

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

### 問題：找不到 rm 命令

**解決方法：**

1. 檢查 `~/bin` 是否在 PATH 中：
   ```bash
   echo $PATH
   ```

2. 重新載入設定檔：
   ```bash
   source ~/.bashrc  # 或 source ~/.zshrc
   ```

### 問題：提示權限被拒

**解決方法：**

確保腳本有執行權限：
```bash
chmod +x ~/bin/rm
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

或暫時停用別名：
```bash
\rm file.txt
```

## 未來計畫

- [ ] 實作還原功能（`rm --restore`）
- [ ] 自動清理過期的垃圾檔案
- [ ] 提供垃圾桶管理介面
- [ ] 支援更多自訂保護規則
- [ ] 加入設定檔支援

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

**警告：本工具不能取代完整的備份策略。請務必定期備份重要資料！**
