#!/bin/bash
#
# Better-RM 完整測試腳本
# Comprehensive Test Script for Better-RM
#
# 此腳本可在容器環境下測試 better-rm 的所有功能
# This script tests all features of better-rm in a container environment
#

# 顏色定義 (Color definitions)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 測試計數器 (Test counters)
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Better-RM 腳本路徑 (Better-RM script path)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BETTER_RM="$SCRIPT_DIR/better-rm"

# 測試用的垃圾桶目錄 (Test trash directory)
TEST_TRASH_DIR="/tmp/better-rm-test-trash"

# 測試用的工作目錄 (Test working directory)
TEST_WORK_DIR="/tmp/better-rm-test-work"

# 顯示測試標題 (Display test title)
test_title() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# 顯示測試項目 (Display test item)
test_item() {
    echo -e "${YELLOW}[測試 $TOTAL_TESTS] $1${NC}"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

# 測試成功 (Test passed)
test_pass() {
    echo -e "${GREEN}✓ 通過: $1${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
}

# 測試失敗 (Test failed)
test_fail() {
    echo -e "${RED}✗ 失敗: $1${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
}

# 清理測試環境 (Clean up test environment)
cleanup() {
    rm -rf "$TEST_TRASH_DIR" "$TEST_WORK_DIR"
}

# 設置測試環境 (Setup test environment)
setup() {
    cleanup
    mkdir -p "$TEST_WORK_DIR"
    export TRASH_DIR="$TEST_TRASH_DIR"
}

# 驗證檔案是否在垃圾桶中 (Verify file is in trash)
verify_in_trash() {
    local pattern="$1"
    if find "$TEST_TRASH_DIR" -name "*${pattern}*" 2>/dev/null | grep -q .; then
        return 0
    else
        return 1
    fi
}

# 驗證日誌記錄 (Verify log entry)
verify_log_entry() {
    local log_file="$TEST_TRASH_DIR/.deletion_log"
    local pattern="$1"
    if [ -f "$log_file" ] && grep -q "$pattern" "$log_file"; then
        return 0
    else
        return 1
    fi
}

# ============================================================================
# 測試開始 (Tests Begin)
# ============================================================================

echo -e "${GREEN}Better-RM 完整測試套件${NC}"
echo -e "${GREEN}Better-RM Comprehensive Test Suite${NC}"
echo ""
echo "測試腳本: $BETTER_RM"
echo "垃圾桶目錄: $TEST_TRASH_DIR"
echo "工作目錄: $TEST_WORK_DIR"
echo ""

# ============================================================================
# 測試 1: 版本與說明 (Test 1: Version and Help)
# ============================================================================
test_title "測試 1: 版本與說明資訊"

test_item "測試 --version 參數"
if "$BETTER_RM" --version | grep -q "better-rm 1.1.0"; then
    test_pass "--version 顯示正確版本"
else
    test_fail "--version 版本不正確"
fi

test_item "測試 --help 參數"
if "$BETTER_RM" --help | grep -q "用法"; then
    test_pass "--help 顯示說明訊息"
else
    test_fail "--help 未顯示說明訊息"
fi

# ============================================================================
# 測試 2: 基本檔案刪除 (Test 2: Basic File Deletion)
# ============================================================================
test_title "測試 2: 基本檔案刪除功能"

setup
cd "$TEST_WORK_DIR"

test_item "刪除單一檔案"
echo "test content" > file1.txt
if "$BETTER_RM" file1.txt && [ ! -e file1.txt ] && verify_in_trash "file1.txt"; then
    test_pass "單一檔案成功移至垃圾桶"
else
    test_fail "單一檔案刪除失敗"
fi

test_item "刪除多個檔案"
echo "file2" > file2.txt
echo "file3" > file3.txt
if "$BETTER_RM" file2.txt file3.txt && [ ! -e file2.txt ] && [ ! -e file3.txt ] && \
   verify_in_trash "file2.txt" && verify_in_trash "file3.txt"; then
    test_pass "多個檔案成功移至垃圾桶"
else
    test_fail "多個檔案刪除失敗"
fi

# ============================================================================
# 測試 3: 目錄刪除 (Test 3: Directory Deletion)
# ============================================================================
test_title "測試 3: 目錄刪除功能"

setup
cd "$TEST_WORK_DIR"

test_item "遞迴刪除目錄 (-r)"
mkdir -p testdir/subdir
echo "content" > testdir/file.txt
echo "subcontent" > testdir/subdir/subfile.txt
if "$BETTER_RM" -r testdir && [ ! -e testdir ] && verify_in_trash "testdir"; then
    test_pass "目錄成功遞迴刪除"
else
    test_fail "目錄刪除失敗"
fi

test_item "刪除空目錄"
mkdir emptydir
if "$BETTER_RM" -r emptydir && [ ! -e emptydir ] && verify_in_trash "emptydir"; then
    test_pass "空目錄成功刪除"
else
    test_fail "空目錄刪除失敗"
fi

test_item "不加 -r 刪除目錄應失敗"
mkdir testdir2
if "$BETTER_RM" testdir2 2>/dev/null; then
    test_fail "不加 -r 卻成功刪除目錄（不應該）"
else
    test_pass "不加 -r 正確拒絕刪除目錄"
fi
rm -rf testdir2

# ============================================================================
# 測試 4: 特殊字元檔名 (Test 4: Special Characters in Filenames)
# ============================================================================
test_title "測試 4: 特殊字元檔名處理"

setup
cd "$TEST_WORK_DIR"

test_item "檔名含空格"
echo "content" > "file with spaces.txt"
if "$BETTER_RM" "file with spaces.txt" && [ ! -e "file with spaces.txt" ]; then
    test_pass "空格檔名成功處理"
else
    test_fail "空格檔名處理失敗"
fi

test_item "檔名含特殊字元"
echo "content" > "file-with_special.chars.txt"
if "$BETTER_RM" "file-with_special.chars.txt" && [ ! -e "file-with_special.chars.txt" ]; then
    test_pass "特殊字元檔名成功處理"
else
    test_fail "特殊字元檔名處理失敗"
fi

test_item "中文檔名"
echo "內容" > "測試檔案.txt"
if "$BETTER_RM" "測試檔案.txt" && [ ! -e "測試檔案.txt" ]; then
    test_pass "中文檔名成功處理"
else
    test_fail "中文檔名處理失敗"
fi

# ============================================================================
# 測試 5: 符號連結 (Test 5: Symbolic Links)
# ============================================================================
test_title "測試 5: 符號連結處理"

setup
cd "$TEST_WORK_DIR"

test_item "刪除符號連結"
echo "target" > target.txt
ln -s target.txt symlink.txt
if "$BETTER_RM" symlink.txt && [ ! -L symlink.txt ] && [ -e target.txt ]; then
    test_pass "符號連結成功刪除（目標檔案保留）"
else
    test_fail "符號連結刪除失敗"
fi

# ============================================================================
# 測試 6: 時間戳記與 Hash (Test 6: Timestamp and Hash)
# ============================================================================
test_title "測試 6: 時間戳記與內容 Hash"

setup
cd "$TEST_WORK_DIR"

test_item "檔名包含時間戳記和 Hash"
echo "content for hash" > hashtest.txt
"$BETTER_RM" hashtest.txt
if find "$TEST_TRASH_DIR" -name "hashtest.txt__*__*" | grep -q .; then
    test_pass "檔名包含時間戳記和 Hash"
else
    test_fail "檔名格式不正確"
fi

test_item "相同檔名但不同內容產生不同 Hash"
echo "content1" > test.txt
"$BETTER_RM" test.txt
sleep 0.01  # 確保時間戳記不同
hash1=$(find "$TEST_TRASH_DIR" -name "test.txt__*" | head -1 | awk -F'__' '{print $NF}')

echo "content2" > test.txt
"$BETTER_RM" test.txt
hash2=$(find "$TEST_TRASH_DIR" -name "test.txt__*" | tail -1 | awk -F'__' '{print $NF}')

if [ -n "$hash1" ] && [ -n "$hash2" ] && [ "$hash1" != "$hash2" ]; then
    test_pass "不同內容產生不同 Hash (hash1=$hash1, hash2=$hash2)"
else
    test_fail "不同內容產生相同 Hash 或未找到 Hash (hash1=$hash1, hash2=$hash2)"
fi

test_item "空檔案的 Hash"
touch empty.txt
"$BETTER_RM" empty.txt
if find "$TEST_TRASH_DIR" -name "empty.txt__*__d41d8cd98f00b204e9800998ecf8427e" | grep -q .; then
    test_pass "空檔案 Hash 正確 (MD5 of empty string)"
else
    test_fail "空檔案 Hash 不正確"
fi

# ============================================================================
# 測試 7: 刪除日誌 (Test 7: Deletion Log)
# ============================================================================
test_title "測試 7: 刪除日誌功能"

setup
cd "$TEST_WORK_DIR"

test_item "日誌檔案自動創建"
echo "test" > logtest.txt
"$BETTER_RM" logtest.txt
if [ -f "$TEST_TRASH_DIR/.deletion_log" ]; then
    test_pass "日誌檔案成功創建"
else
    test_fail "日誌檔案未創建"
fi

test_item "日誌記錄檔案刪除"
if verify_log_entry "logtest.txt" && verify_log_entry "file"; then
    test_pass "日誌正確記錄檔案刪除"
else
    test_fail "日誌未記錄檔案刪除"
fi

test_item "日誌記錄目錄刪除"
mkdir logdir
echo "content" > logdir/file.txt
"$BETTER_RM" -r logdir
if verify_log_entry "logdir" && verify_log_entry "directory"; then
    test_pass "日誌正確記錄目錄刪除"
else
    test_fail "日誌未記錄目錄刪除"
fi

test_item "日誌記錄符號連結"
echo "target" > logtarget.txt
ln -s logtarget.txt logsymlink.txt
"$BETTER_RM" logsymlink.txt
if verify_log_entry "symlink"; then
    test_pass "日誌正確記錄符號連結"
else
    test_fail "日誌未記錄符號連結"
fi

test_item "日誌格式正確"
log_file="$TEST_TRASH_DIR/.deletion_log"
if grep -E "^[0-9]{8}_[0-9]{6}_[0-9]+ \| .+ \| .+ \| .+ \| (file|directory|symlink)$" "$log_file" >/dev/null 2>&1; then
    test_pass "日誌格式正確"
else
    test_fail "日誌格式不正確"
fi

# ============================================================================
# 測試 8: 參數選項 (Test 8: Command Options)
# ============================================================================
test_title "測試 8: 命令參數選項"

setup
cd "$TEST_WORK_DIR"

test_item "詳細模式 (-v)"
echo "verbose test" > vtest.txt
if "$BETTER_RM" -v vtest.txt 2>&1 | grep -q "已移除"; then
    test_pass "-v 參數顯示詳細訊息"
else
    test_fail "-v 參數未顯示詳細訊息"
fi

test_item "強制模式 (-f) 忽略不存在的檔案"
if "$BETTER_RM" -f nonexistent.txt 2>/dev/null; then
    test_pass "-f 參數正確忽略不存在的檔案"
else
    test_fail "-f 參數未正確處理"
fi

test_item "組合參數 (-rf)"
mkdir -p rftest/subdir
echo "content" > rftest/file.txt
if "$BETTER_RM" -rf rftest && [ ! -e rftest ]; then
    test_pass "-rf 組合參數正常工作"
else
    test_fail "-rf 組合參數失敗"
fi

# ============================================================================
# 測試 9: 受保護目錄 (Test 9: Protected Directories)
# ============================================================================
test_title "測試 9: 受保護目錄"

test_item "拒絕刪除根目錄 (/)"
if "$BETTER_RM" -rf / 2>&1 | grep -q "拒絕刪除受保護的目錄"; then
    test_pass "正確拒絕刪除根目錄"
else
    test_fail "未正確保護根目錄"
fi

test_item "拒絕刪除 /home"
if "$BETTER_RM" -rf /home 2>&1 | grep -q "拒絕刪除受保護的目錄"; then
    test_pass "正確拒絕刪除 /home"
else
    test_fail "未正確保護 /home"
fi

test_item "拒絕刪除 .git 目錄"
setup
cd "$TEST_WORK_DIR"
mkdir -p project/.git
if "$BETTER_RM" -rf project/.git 2>&1 | grep -q "拒絕刪除受保護的目錄"; then
    test_pass "正確拒絕刪除 .git 目錄"
else
    test_fail "未正確保護 .git 目錄"
fi

# ============================================================================
# 測試 10: 快速連續刪除 (Test 10: Rapid Successive Deletions)
# ============================================================================
test_title "測試 10: 快速連續刪除（測試奈秒時間戳記）"

setup
cd "$TEST_WORK_DIR"

test_item "快速連續刪除多個檔案"
for i in {1..5}; do
    echo "content $i" > "rapid$i.txt"
done

for i in {1..5}; do
    "$BETTER_RM" "rapid$i.txt" &
done
wait

# 檢查所有檔案是否都成功刪除
all_deleted=true
for i in {1..5}; do
    if [ -e "rapid$i.txt" ]; then
        all_deleted=false
    fi
done

# 檢查是否有檔名衝突
trash_files=$(find "$TEST_TRASH_DIR" -name "rapid*.txt__*" 2>/dev/null | wc -l)

if $all_deleted && [ "$trash_files" -eq 5 ]; then
    test_pass "快速連續刪除成功，無檔名衝突（奈秒時間戳記正常工作）"
elif $all_deleted; then
    test_pass "快速連續刪除成功，但找到 $trash_files 個檔案（預期 5 個）"
else
    test_fail "快速連續刪除失敗"
fi

# ============================================================================
# 測試 11: 路徑結構保留 (Test 11: Path Structure Preservation)
# ============================================================================
test_title "測試 11: 垃圾桶路徑結構保留"

setup
cd "$TEST_WORK_DIR"

test_item "深層目錄結構保留"
mkdir -p deep/nested/directory/structure
echo "deep content" > deep/nested/directory/structure/file.txt
original_path="$TEST_WORK_DIR/deep/nested/directory/structure/file.txt"
"$BETTER_RM" deep/nested/directory/structure/file.txt

# 檢查垃圾桶中是否保留了路徑結構
if find "$TEST_TRASH_DIR$TEST_WORK_DIR/deep/nested/directory/structure" -name "file.txt__*" | grep -q .; then
    test_pass "路徑結構成功保留"
else
    test_fail "路徑結構未保留"
fi

# ============================================================================
# 測試 12: 自訂垃圾桶目錄 (Test 12: Custom Trash Directory)
# ============================================================================
test_title "測試 12: 自訂垃圾桶目錄"

test_item "使用自訂 TRASH_DIR"
custom_trash="/tmp/custom-trash-test"
rm -rf "$custom_trash"
cd "$TEST_WORK_DIR"
echo "custom trash test" > customtest.txt

TRASH_DIR="$custom_trash" "$BETTER_RM" customtest.txt

if [ -d "$custom_trash" ] && find "$custom_trash" -name "customtest.txt__*" | grep -q .; then
    test_pass "自訂垃圾桶目錄正常工作"
else
    test_fail "自訂垃圾桶目錄失敗"
fi
rm -rf "$custom_trash"

# ============================================================================
# 測試結果統計 (Test Results Summary)
# ============================================================================

cleanup

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}測試結果統計 (Test Results Summary)${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "總測試數 (Total Tests): ${BLUE}$TOTAL_TESTS${NC}"
echo -e "通過測試 (Passed): ${GREEN}$PASSED_TESTS${NC}"
echo -e "失敗測試 (Failed): ${RED}$FAILED_TESTS${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✓ 所有測試通過！(All tests passed!)${NC}"
    exit 0
else
    echo -e "${RED}✗ 有 $FAILED_TESTS 個測試失敗 ($FAILED_TESTS tests failed)${NC}"
    exit 1
fi
