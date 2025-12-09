# Better-RM 測試腳本說明
# Better-RM Test Script Documentation

## 概述 (Overview)

`test-better-rm.sh` 是一個完整的測試腳本，用於驗證 better-rm 的所有功能與特性。

## 使用方式 (Usage)

### 基本執行 (Basic Execution)

```bash
./test-better-rm.sh
```

### 在容器環境中執行 (Run in Container Environment)

```bash
# Docker
docker run -v $(pwd):/app ubuntu:latest bash /app/test-better-rm.sh

# Podman
podman run -v $(pwd):/app:z ubuntu:latest bash /app/test-better-rm.sh
```

## 測試項目 (Test Items)

### 測試 1: 版本與說明資訊
- 測試 `--version` 參數
- 測試 `--help` 參數

### 測試 2: 基本檔案刪除功能
- 刪除單一檔案
- 刪除多個檔案

### 測試 3: 目錄刪除功能
- 遞迴刪除目錄 (-r)
- 刪除空目錄
- 不加 -r 刪除目錄應失敗

### 測試 4: 特殊字元檔名處理
- 檔名含空格
- 檔名含特殊字元
- 中文檔名

### 測試 5: 符號連結處理
- 刪除符號連結（目標檔案應保留）

### 測試 6: 時間戳記與內容 Hash
- 檔名包含時間戳記和 Hash
- 相同檔名但不同內容產生不同 Hash
- 空檔案的 Hash

### 測試 7: 刪除日誌功能
- 日誌檔案自動創建
- 日誌記錄檔案刪除
- 日誌記錄目錄刪除
- 日誌記錄符號連結
- 日誌格式正確

### 測試 8: 命令參數選項
- 詳細模式 (-v)
- 強制模式 (-f)
- 組合參數 (-rf)

### 測試 9: 受保護目錄
- 拒絕刪除根目錄 (/)
- 拒絕刪除 /home
- 拒絕刪除 .git 目錄

### 測試 10: 快速連續刪除
- 測試奈秒時間戳記避免檔名衝突

### 測試 11: 垃圾桶路徑結構保留
- 深層目錄結構保留

### 測試 12: 自訂垃圾桶目錄
- 使用自訂 TRASH_DIR 環境變數

## 測試結果 (Test Results)

測試腳本會顯示：
- 總測試數
- 通過測試數
- 失敗測試數

如果所有測試通過，返回 exit code 0；否則返回 exit code 1。

## 環境需求 (Requirements)

- Bash 4.0+
- 基本 Unix 工具（find, grep, awk, wc 等）
- md5sum 或 sha256sum

## 測試目錄 (Test Directories)

測試腳本會使用以下臨時目錄：
- `/tmp/better-rm-test-trash` - 測試用垃圾桶目錄
- `/tmp/better-rm-test-work` - 測試工作目錄

測試完成後會自動清理。

## 故障排除 (Troubleshooting)

### 測試失敗
如果某個測試失敗，檢查：
1. better-rm 腳本是否有執行權限
2. 是否有足夠的磁碟空間
3. 是否有必要的系統工具（md5sum, find 等）

### 容器環境注意事項
在容器中執行時：
1. 確保掛載的目錄有執行權限
2. 容器需要有 bash 環境
3. 需要安裝 coreutils 套件

## 範例輸出 (Example Output)

```
Better-RM 完整測試套件
Better-RM Comprehensive Test Suite

測試腳本: /path/to/better-rm
垃圾桶目錄: /tmp/better-rm-test-trash
工作目錄: /tmp/better-rm-test-work

========================================
測試 1: 版本與說明資訊
========================================
[測試 0] 測試 --version 參數
✓ 通過: --version 顯示正確版本
...

========================================
測試結果統計 (Test Results Summary)
========================================

總測試數 (Total Tests): 28
通過測試 (Passed): 28
失敗測試 (Failed): 0

✓ 所有測試通過！(All tests passed!)
```

## 貢獻 (Contributing)

如需添加新的測試項目：
1. 在適當的測試區塊中添加新的測試函數
2. 使用 `test_item` 描述測試項目
3. 使用 `test_pass` 或 `test_fail` 記錄結果
4. 確保測試結束後清理所有臨時檔案

## 授權 (License)

與 better-rm 專案相同的授權條款。
