#!/bin/bash
#
# install-hooks.sh 測試 / Tests for install-hooks.sh
#

set -e

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
INSTALLER="$SCRIPT_DIR/install-hooks.sh"
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/better-rm-hooks.XXXXXX")
PASSED=0
FAILED=0

cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

pass() {
    PASSED=$((PASSED + 1))
    echo "✓ $1"
}

fail() {
    FAILED=$((FAILED + 1))
    echo "✗ $1" >&2
}

assert_success() {
    local name="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        pass "$name"
    else
        fail "$name"
    fi
}

assert_contains() {
    local name="$1"
    local haystack="$2"
    local needle="$3"
    if printf '%s\n' "$haystack" | grep -q "$needle"; then
        pass "$name"
    else
        fail "$name"
    fi
}

assert_failure() {
    local name="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        fail "$name"
    else
        pass "$name"
    fi
}

assert_file() {
    local name="$1"
    local file="$2"
    if [ -f "$file" ]; then
        pass "$name"
    else
        fail "$name"
    fi
}

assert_equal() {
    local name="$1"
    local expected="$2"
    local actual="$3"
    if [ "$expected" = "$actual" ]; then
        pass "$name"
    else
        fail "$name (expected: $expected, actual: $actual)"
    fi
}

make_repo() {
    local repo="$1"
    mkdir -p "$repo"
    git -C "$repo" init -q
}

hook_count() {
    local agent="${2:-claude}"
    node - "$1" "$agent" <<'NODE'
const fs = require('fs');
const settings = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const agent = process.argv[3] ?? 'claude';
let count = 0;

const hasRuntimePath = (command) => typeof command === 'string' && command.includes('protect-important-paths.js');

if (agent === 'cursor') {
  for (const hook of settings?.hooks?.beforeShellExecution ?? []) {
    if (typeof hook?.command === 'string' && hasRuntimePath(hook.command)) count += 1;
  }
} else if (agent === 'copilot') {
  for (const entry of settings?.hooks?.preToolUse ?? []) {
    if (entry?.type !== 'command' || entry?.matcher !== 'bash|powershell') continue;
    if ((typeof entry?.bash === 'string' && hasRuntimePath(entry.bash))
      || (typeof entry?.powershell === 'string' && hasRuntimePath(entry.powershell))) {
      count += 1;
    }
  }
} else if (agent === 'antigravity') {
  const workspace = settings?.hooks?.['better-rm-protection'];
  for (const entry of workspace?.PreToolUse ?? []) {
    if (entry?.matcher !== 'run_command' || !Array.isArray(entry.hooks)) continue;
    for (const hook of entry.hooks) {
      if (hook?.type === 'command' && hasRuntimePath(hook.command)) count += 1;
    }
  }
} else {
  for (const entry of settings.hooks?.PreToolUse ?? []) {
    if (entry?.matcher !== 'Bash' || !Array.isArray(entry.hooks)) continue;
    for (const hook of entry.hooks) {
      if (hook?.type === 'command' && hasRuntimePath(hook.command)) count += 1;
    }
  }
}
process.stdout.write(String(count));
NODE
}

file_mode() {
    node -e 'process.stdout.write((require("fs").statSync(process.argv[1]).mode & 0o777).toString(8))' "$1"
}

file_mtime() {
    node -e 'process.stdout.write(String(require("fs").statSync(process.argv[1]).mtimeMs))' "$1"
}

file_hash() {
    node -e 'process.stdout.write(require("crypto").createHash("sha256").update(require("fs").readFileSync(process.argv[1])).digest("hex"))' "$1"
}

backup_count() {
    local directory="$1"
    local name="$2"
    find "$directory" -maxdepth 1 -type f -name "$name.better-rm.bak.*" | wc -l | tr -d ' '
}

expected_settings_path() {
    case "$1" in
        claude) echo ".claude/settings.json" ;;
        codex) echo ".codex/hooks.json" ;;
        cursor) echo ".cursor/hooks.json" ;;
        copilot) echo ".github/hooks/better-rm.json" ;;
        antigravity) echo ".agents/hooks.json" ;;
        qoder) echo ".qoder/settings.json" ;;
        pi) echo ".pi/hooks.json" ;;
        grok) echo ".grok/hooks/better-rm.json" ;;
        *) echo "" ;;
    esac
}

echo "========================================"
echo "install-hooks.sh tests"
echo "========================================"

CURRENT_HOOKS_VERSION="$(awk -F'\"' '/^VERSION=/{print $2; exit}' "$SCRIPT_DIR/install-hooks.sh")"

# CLI parsing
assert_success "--version short flag works" bash -c "'$INSTALLER' -v | grep -q \"install-hooks.sh ${CURRENT_HOOKS_VERSION}\""
assert_success "--version long flag works" bash -c "'$INSTALLER' --version | grep -q \"install-hooks.sh ${CURRENT_HOOKS_VERSION}\""
assert_success "--help succeeds" "$INSTALLER" --help
HELP_TEXT=$("$INSTALLER" --help)
assert_contains "help shows supported agents" "$HELP_TEXT" "supported:"
assert_contains "help shows claude as supported agent" "$HELP_TEXT" "claude"
assert_contains "help shows codex as supported agent" "$HELP_TEXT" "codex"
assert_contains "help shows cursor as supported agent" "$HELP_TEXT" "cursor"
assert_failure "missing --agent fails" "$INSTALLER"
assert_failure "missing --agent value fails" "$INSTALLER" --agent
assert_failure "unknown option fails" "$INSTALLER" --wat
assert_failure "unsupported agent fails" "$INSTALLER" --agent unknown
assert_failure "duplicate --agent fails" "$INSTALLER" -a claude --agent claude

# Matrix install in project mode for all supported agents.
for agent in claude codex cursor copilot antigravity qoder pi grok; do
    AGENT_PROJECT="$TMP_ROOT/matrix-${agent}-project"
    make_repo "$AGENT_PROJECT"
    mkdir -p "$AGENT_PROJECT/src/nested"
    (
        cd "$AGENT_PROJECT/src/nested"
        "$INSTALLER" -a "$agent" >/dev/null
    )

    AGENT_SETTINGS="$AGENT_PROJECT/$(expected_settings_path "$agent")"
    AGENT_SETTINGS_DIR="$(dirname "$AGENT_SETTINGS")"
    assert_file "matrix project install creates ${agent} settings" "$AGENT_SETTINGS"
    assert_equal "matrix ${agent} hook count is one" "1" "$(hook_count "$AGENT_SETTINGS" "$agent")"
    assert_equal "matrix ${agent} settings mode is 644" "644" "$(file_mode "$AGENT_SETTINGS")"
    assert_file "matrix ${agent} hook is placed beside settings" "$AGENT_SETTINGS_DIR/protect-important-paths.js"

    AGENT_HASH_BEFORE=$(file_hash "$AGENT_SETTINGS")
    (
        cd "$AGENT_PROJECT/src/nested"
        "$INSTALLER" -a "$agent" >/dev/null
    )
    assert_equal "matrix ${agent} install is idempotent" "$AGENT_HASH_BEFORE" "$(file_hash "$AGENT_SETTINGS")"

    # Non-Claude agents should reject --global
    if [ "$agent" != "claude" ]; then
        assert_failure "matrix ${agent} rejects global" bash -c "cd '$TMP_ROOT' && '$INSTALLER' -a '$agent' --global"
    fi
done

# OpenCode has dedicated runtime + plugin install path checks.
OPENCODE_PROJECT="$TMP_ROOT/opencode-project"
make_repo "$OPENCODE_PROJECT"
mkdir -p "$OPENCODE_PROJECT/src/nested"
(
    cd "$OPENCODE_PROJECT/src/nested"
    "$INSTALLER" -a opencode >/dev/null
)
OPENCODE_PLUGIN="$OPENCODE_PROJECT/.opencode/plugins/protect-important-paths.ts"
OPENCODE_RUNTIME="$OPENCODE_PROJECT/hooks/protect-important-paths.js"
assert_file "opencode plugin is created at project path" "$OPENCODE_PLUGIN"
assert_file "opencode runtime hook is created at project path" "$OPENCODE_RUNTIME"
OPENCODE_PLUGIN_HASH_BEFORE=$(file_hash "$OPENCODE_PLUGIN")
OPENCODE_RUNTIME_HASH_BEFORE=$(file_hash "$OPENCODE_RUNTIME")

assert_contains "opencode plugin references project-local runtime" "$(cat "$OPENCODE_PLUGIN")" "../../hooks/protect-important-paths"

(
    cd "$OPENCODE_PROJECT/src/nested"
    "$INSTALLER" -a opencode >/dev/null
)
assert_equal "opencode plugin hash is idempotent" "$OPENCODE_PLUGIN_HASH_BEFORE" "$(file_hash "$OPENCODE_PLUGIN")"
assert_equal "opencode runtime hash is idempotent" "$OPENCODE_RUNTIME_HASH_BEFORE" "$(file_hash "$OPENCODE_RUNTIME")"

# OpenCode should also reject project-level global install flag.
assert_failure "opencode rejects global" bash -c "cd '$TMP_ROOT' && '$INSTALLER' -a opencode --global"

# OpenCode must reject dangling symbolic links before copying plugin or runtime files.
OPENCODE_PLUGIN_SYMLINK_REPO="$TMP_ROOT/opencode-plugin-symlink-project"
make_repo "$OPENCODE_PLUGIN_SYMLINK_REPO"
mkdir -p "$OPENCODE_PLUGIN_SYMLINK_REPO/.opencode/plugins"
OPENCODE_DANGLING_PLUGIN_TARGET="$TMP_ROOT/missing-opencode-plugin.ts"
ln -s "$OPENCODE_DANGLING_PLUGIN_TARGET" "$OPENCODE_PLUGIN_SYMLINK_REPO/.opencode/plugins/protect-important-paths.ts"
assert_failure "opencode rejects dangling plugin symlink" bash -c "cd '$OPENCODE_PLUGIN_SYMLINK_REPO' && '$INSTALLER' -a opencode"
if [ -L "$OPENCODE_PLUGIN_SYMLINK_REPO/.opencode/plugins/protect-important-paths.ts" ] && [ ! -e "$OPENCODE_DANGLING_PLUGIN_TARGET" ]; then
    pass "opencode dangling plugin symlink is not followed"
else
    fail "opencode dangling plugin symlink is not followed"
fi
if [ ! -e "$OPENCODE_PLUGIN_SYMLINK_REPO/hooks/protect-important-paths.js" ]; then
    pass "opencode plugin symlink failure leaves runtime untouched"
else
    fail "opencode plugin symlink failure leaves runtime untouched"
fi

OPENCODE_RUNTIME_SYMLINK_REPO="$TMP_ROOT/opencode-runtime-symlink-project"
make_repo "$OPENCODE_RUNTIME_SYMLINK_REPO"
mkdir -p "$OPENCODE_RUNTIME_SYMLINK_REPO/.opencode/plugins" "$OPENCODE_RUNTIME_SYMLINK_REPO/hooks"
printf 'existing plugin must remain unchanged\n' > "$OPENCODE_RUNTIME_SYMLINK_REPO/.opencode/plugins/protect-important-paths.ts"
OPENCODE_STALE_PLUGIN_HASH=$(file_hash "$OPENCODE_RUNTIME_SYMLINK_REPO/.opencode/plugins/protect-important-paths.ts")
OPENCODE_DANGLING_RUNTIME_TARGET="$TMP_ROOT/missing-opencode-runtime.js"
ln -s "$OPENCODE_DANGLING_RUNTIME_TARGET" "$OPENCODE_RUNTIME_SYMLINK_REPO/hooks/protect-important-paths.js"
assert_failure "opencode rejects dangling runtime symlink" bash -c "cd '$OPENCODE_RUNTIME_SYMLINK_REPO' && '$INSTALLER' -a opencode"
assert_equal "opencode runtime symlink failure leaves plugin unchanged" "$OPENCODE_STALE_PLUGIN_HASH" "$(file_hash "$OPENCODE_RUNTIME_SYMLINK_REPO/.opencode/plugins/protect-important-paths.ts")"
if [ -L "$OPENCODE_RUNTIME_SYMLINK_REPO/hooks/protect-important-paths.js" ] && [ ! -e "$OPENCODE_DANGLING_RUNTIME_TARGET" ]; then
    pass "opencode dangling runtime symlink is not followed"
else
    fail "opencode dangling runtime symlink is not followed"
fi

# Global mode supports HOME and CLAUDE_CONFIG_DIR without a Git repository.
GLOBAL_HOME="$TMP_ROOT/global-home"
mkdir -p "$GLOBAL_HOME"
(
    cd "$TMP_ROOT"
    CLAUDE_CONFIG_DIR= HOME="$GLOBAL_HOME" "$INSTALLER" --agent claude --global >/dev/null
)
GLOBAL_SETTINGS="$GLOBAL_HOME/.claude/settings.json"
assert_file "global settings use HOME fallback" "$GLOBAL_SETTINGS"
assert_equal "new global settings use mode 600" "600" "$(file_mode "$GLOBAL_SETTINGS")"

CUSTOM_CONFIG="$TMP_ROOT/custom config"
(
    cd "$TMP_ROOT"
    HOME="$GLOBAL_HOME" CLAUDE_CONFIG_DIR="$CUSTOM_CONFIG" "$INSTALLER" -a claude -g >/dev/null
)
assert_file "CLAUDE_CONFIG_DIR overrides HOME" "$CUSTOM_CONFIG/settings.json"

# Merge preservation, legacy replacement, duplicate removal, backup, and mode preservation.
MERGE_REPO="$TMP_ROOT/merge-project"
make_repo "$MERGE_REPO"
mkdir -p "$MERGE_REPO/.claude"
cat > "$MERGE_REPO/.claude/settings.json" <<'JSON'
{
  "permissions": {"allow": ["Read"]},
  "env": {"EXAMPLE": "yes"},
  "hooks": {
    "Stop": [{"hooks": [{"type": "command", "command": "echo stop"}]}],
    "PreToolUse": [
      {
        "matcher": "Read",
        "hooks": [{"type": "command", "command": "node /tmp/hooks/protect-important-paths.js"}]
      },
      {
        "matcher": "Bash",
        "extra": "keep-me",
        "hooks": [
          {"type": "command", "command": "echo unrelated"},
          {"type": "command", "command": "node \"$(git rev-parse --show-toplevel)/hooks/protect-important-paths.js\"", "timeout": 5}
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [{"type": "command", "command": "node '/old/hooks/protect-important-paths.js'"}]
      }
    ]
  }
}
JSON
chmod 640 "$MERGE_REPO/.claude/settings.json"
ORIGINAL_MERGE="$TMP_ROOT/original-settings.json"
cp "$MERGE_REPO/.claude/settings.json" "$ORIGINAL_MERGE"
(
    cd "$MERGE_REPO"
    "$INSTALLER" --agent claude >/dev/null
)
MERGE_SETTINGS="$MERGE_REPO/.claude/settings.json"
assert_equal "duplicate better-rm Bash hooks collapse to one" "1" "$(hook_count "$MERGE_SETTINGS")"
assert_equal "existing settings mode is preserved" "640" "$(file_mode "$MERGE_SETTINGS")"
assert_equal "changed settings create one backup" "1" "$(backup_count "$MERGE_REPO/.claude" settings.json)"

BACKUP=$(find "$MERGE_REPO/.claude" -maxdepth 1 -type f -name 'settings.json.better-rm.bak.*' | head -n 1)
if cmp -s "$ORIGINAL_MERGE" "$BACKUP"; then
    pass "backup preserves original bytes"
else
    fail "backup preserves original bytes"
fi

if node - "$MERGE_SETTINGS" <<'NODE'
const s = require(process.argv[2]);
const bash = s.hooks.PreToolUse.filter((x) => x.matcher === 'Bash');
if (s.permissions.allow[0] !== 'Read') process.exit(1);
if (s.env.EXAMPLE !== 'yes') process.exit(1);
if (s.hooks.Stop[0].hooks[0].command !== 'echo stop') process.exit(1);
if (s.hooks.PreToolUse[0].matcher !== 'Read') process.exit(1);
if (bash[0].extra !== 'keep-me') process.exit(1);
if (!bash[0].hooks.some((x) => x.command === 'echo unrelated')) process.exit(1);
NODE
then
    pass "merge preserves unrelated settings and hooks"
else
    fail "merge preserves unrelated settings and hooks"
fi

# A second run is a byte-for-byte no-op and creates no backup.
BEFORE_HASH=$(node -e 'process.stdout.write(require("crypto").createHash("sha256").update(require("fs").readFileSync(process.argv[1])).digest("hex"))' "$MERGE_SETTINGS")
BEFORE_MTIME=$(file_mtime "$MERGE_SETTINGS")
BEFORE_BACKUPS=$(backup_count "$MERGE_REPO/.claude" settings.json)
sleep 1
(
    cd "$MERGE_REPO"
    "$INSTALLER" -a claude >/dev/null
)
AFTER_HASH=$(node -e 'process.stdout.write(require("crypto").createHash("sha256").update(require("fs").readFileSync(process.argv[1])).digest("hex"))' "$MERGE_SETTINGS")
assert_equal "idempotent run preserves file bytes" "$BEFORE_HASH" "$AFTER_HASH"
assert_equal "idempotent run preserves modification time" "$BEFORE_MTIME" "$(file_mtime "$MERGE_SETTINGS")"
assert_equal "idempotent run creates no backup" "$BEFORE_BACKUPS" "$(backup_count "$MERGE_REPO/.claude" settings.json)"

# Invalid settings fail without modifying their input.
for fixture in malformed array hooks pretool bashhooks; do
    INVALID_REPO="$TMP_ROOT/invalid-$fixture"
    make_repo "$INVALID_REPO"
    mkdir -p "$INVALID_REPO/.claude"
    case "$fixture" in
        malformed) printf '{bad json\n' > "$INVALID_REPO/.claude/settings.json" ;;
        array) printf '[]\n' > "$INVALID_REPO/.claude/settings.json" ;;
        hooks) printf '{"hooks": []}\n' > "$INVALID_REPO/.claude/settings.json" ;;
        pretool) printf '{"hooks": {"PreToolUse": {}}}\n' > "$INVALID_REPO/.claude/settings.json" ;;
        bashhooks) printf '{"hooks": {"PreToolUse": [{"matcher":"Bash","hooks":{}}]}}\n' > "$INVALID_REPO/.claude/settings.json" ;;
    esac
    INVALID_HASH=$(node -e 'process.stdout.write(require("crypto").createHash("sha256").update(require("fs").readFileSync(process.argv[1])).digest("hex"))' "$INVALID_REPO/.claude/settings.json")
    assert_failure "invalid $fixture settings fail safely" bash -c "cd '$INVALID_REPO' && '$INSTALLER' -a claude"
    assert_equal "invalid $fixture settings remain unchanged" "$INVALID_HASH" "$(node -e 'process.stdout.write(require("crypto").createHash("sha256").update(require("fs").readFileSync(process.argv[1])).digest("hex"))' "$INVALID_REPO/.claude/settings.json")"
done

# Symlink settings are rejected.
SYMLINK_REPO="$TMP_ROOT/symlink-project"
make_repo "$SYMLINK_REPO"
mkdir -p "$SYMLINK_REPO/.claude"
printf '{}\n' > "$TMP_ROOT/real-settings.json"
ln -s "$TMP_ROOT/real-settings.json" "$SYMLINK_REPO/.claude/settings.json"
assert_failure "symbolic-link settings are rejected" bash -c "cd '$SYMLINK_REPO' && '$INSTALLER' -a claude"

# Paths with spaces, quotes, and dollar signs are safely encoded and executable.
SPECIAL_SOURCE="$TMP_ROOT/source space's \$dir"
mkdir -p "$SPECIAL_SOURCE/hooks"
cp "$INSTALLER" "$SPECIAL_SOURCE/install-hooks.sh"
cp "$SCRIPT_DIR/hooks/protect-important-paths.js" "$SPECIAL_SOURCE/hooks/protect-important-paths.js"
chmod +x "$SPECIAL_SOURCE/install-hooks.sh"
SPECIAL_HOME="$TMP_ROOT/special-home"
HOME="$SPECIAL_HOME" CLAUDE_CONFIG_DIR= "$SPECIAL_SOURCE/install-hooks.sh" -a claude --global >/dev/null
SPECIAL_SETTINGS="$SPECIAL_HOME/.claude/settings.json"
SPECIAL_COMMAND=$(node -e 'const s=require(process.argv[1]); process.stdout.write(s.hooks.PreToolUse[0].hooks[0].command)' "$SPECIAL_SETTINGS")
if printf '%s' '{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"rm -rf .git"},"cwd":"/workspace/project"}' | bash -c "$SPECIAL_COMMAND" | grep -q '"permissionDecision":"deny"'; then
    pass "special-character hook path executes blocked payload"
else
    fail "special-character hook path executes blocked payload"
fi
if printf '%s' '{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"rm file.txt"},"cwd":"/workspace/project"}' | bash -c "$SPECIAL_COMMAND" >/dev/null; then
    pass "installed hook accepts harmless payload"
else
    fail "installed hook accepts harmless payload"
fi

# Hook command must embed the install-time node PATH so it survives minimal runtime PATHs
# （例如 agent 以精簡 PATH 啟動 hook，nvm 的 node 不在其中）。
NODE_BIN_DIR_AT_TEST="$(cd -- "$(dirname -- "$(command -v node)")" && pwd -P)"
if printf '%s' "$SPECIAL_COMMAND" | grep -qF "$NODE_BIN_DIR_AT_TEST"; then
    pass "hook command embeds install-time node directory"
else
    fail "hook command embeds install-time node directory"
fi

EMPTY_BIN="$TMP_ROOT/empty-bin"
mkdir -p "$EMPTY_BIN"
if printf '%s' '{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"rm -rf .git"},"cwd":"/workspace/project"}' | env -i HOME="$SPECIAL_HOME" PATH="$EMPTY_BIN" /bin/bash -c "$SPECIAL_COMMAND" | grep -q '"permissionDecision":"deny"'; then
    pass "hook blocks payload under minimal PATH without node"
else
    fail "hook blocks payload under minimal PATH without node"
fi
if printf '%s' '{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"rm file.txt"},"cwd":"/workspace/project"}' | env -i HOME="$SPECIAL_HOME" PATH="$EMPTY_BIN" /bin/bash -c "$SPECIAL_COMMAND" >/dev/null; then
    pass "hook accepts harmless payload under minimal PATH without node"
else
    fail "hook accepts harmless payload under minimal PATH without node"
fi

# Missing shared hook fails before touching settings.
MISSING_SOURCE="$TMP_ROOT/missing-source"
mkdir -p "$MISSING_SOURCE"
cp "$INSTALLER" "$MISSING_SOURCE/install-hooks.sh"
chmod +x "$MISSING_SOURCE/install-hooks.sh"
MISSING_HOME="$TMP_ROOT/missing-home"
assert_success "missing shared hook installs from release" env HOME="$MISSING_HOME" CLAUDE_CONFIG_DIR= "$MISSING_SOURCE/install-hooks.sh" -a claude --global
assert_file "missing shared hook creates settings" "$MISSING_HOME/.claude/settings.json"
assert_file "missing shared hook installs local runtime" "$MISSING_HOME/.claude/protect-important-paths.js"

echo ""
echo "========================================"
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "========================================"

if [ "$FAILED" -ne 0 ]; then
    exit 1
fi
