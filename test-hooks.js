#!/usr/bin/env node
// Tests for cross-agent protected-directory hooks.
// 跨代理受保護目錄 hook 測試。

'use strict';

const assert = require('assert');
const { evaluate } = require('./hooks/protect-important-paths');

const env = { HOME: '/home/tester', BETTER_RM_PROTECTED_DIRS: '/workspace/secrets' };

function claude(command, cwd = '/workspace/project') {
  return { hook_event_name: 'PreToolUse', tool_name: 'Bash', tool_input: { command }, cwd };
}

function copilot(command, cwd = '/workspace/project') {
  return { toolName: 'bash', toolArgs: JSON.stringify({ command }), cwd };
}

const blocked = [
  'rm -rf /',
  'sudo rm -rf /etc',
  'sudo -u root rm -rf /var',
  'env LC_ALL=C rm -rf /boot',
  'SAFE=1 rm -rf /opt',
  'rm -rf /mnt',
  'rm -rf /mnt/c',
  'rm -rf /mnt/../mnt/wsl',
  'command rm -r ~/.git',
  'rm -rf .git',
  'rm -rf .*',
  'rm -rf {.git,dist}',
  '/bin/rm -rf ../project/.git/',
  'rmdir /home/tester',
  'rm -rf /workspace/secrets',
  'echo ok && rm -rf /usr',
  'echo ok\nrm -rf /usr',
  'ls -la | head -1\nrm -rf .git',
];

const allowed = [
  'rm -rf build',
  'rm file.txt',
  'rm -rf /mnt/c/project',
  'echo rm -rf /',
  'better-rm -r tmp',
  'echo hi\nrm -rf build',
];

for (const command of blocked) {
  const result = evaluate(claude(command), env);
  assert.equal(result?.hookSpecificOutput?.permissionDecision, 'deny', command);
}
for (const command of allowed) {
  assert.equal(evaluate(claude(command), env), null, command);
}

const copilotResult = evaluate(copilot('rm -rf .git'), env);
assert.equal(copilotResult.permissionDecision, 'deny');
assert.match(copilotResult.permissionDecisionReason, /Refused to remove protected directory/);

// Antigravity tests
function antigravity(command, cwd = '/workspace/project') {
  return {
    conversationId: 'test-uuid-12345',
    workspacePaths: ['/workspace/project'],
    stepIdx: 1,
    toolCall: {
      name: 'run_command',
      args: {
        CommandLine: command,
        Cwd: cwd
      }
    }
  };
}

for (const command of blocked) {
  const result = evaluate(antigravity(command), env);
  assert.equal(result.allow_tool, false, command);
  assert.match(result.deny_reason, /Refused to remove protected directory/, command);
}

for (const command of allowed) {
  assert.equal(evaluate(antigravity(command), env).allow_tool, true, command);
}

// Pi coding agent tests
const piResult = evaluate({ tool_input: { command: 'rm -rf .git' }, cwd: '/workspace/project' }, env);
assert.equal(piResult?.hookSpecificOutput?.permissionDecision, 'deny');
assert.match(piResult?.hookSpecificOutput?.permissionDecisionReason, /Refused to remove protected directory/);

// Cursor tests
function cursor(command, cwd = '/workspace/project') {
  return {
    hook_event_name: 'beforeShellExecution',
    command,
    cwd
  };
}

for (const command of blocked) {
  const result = evaluate(cursor(command), env);
  assert.equal(result.permission, 'deny', command);
  assert.match(result.user_message, /Refused to remove protected directory/, command);
}

for (const command of allowed) {
  assert.equal(evaluate(cursor(command), env).permission, 'allow', command);
}

// Grok Build tests
function grok(command, cwd = '/workspace/project') {
  return {
    hookEventName: 'PreToolUse',
    sessionId: 'test-session-555',
    cwd,
    workspaceRoot: '/workspace/project',
    toolName: 'Bash',
    toolInput: {
      command
    }
  };
}

for (const command of blocked) {
  const result = evaluate(grok(command), env);
  assert.equal(result.decision, 'deny', command);
  assert.match(result.reason, /Refused to remove protected directory/, command);
}

for (const command of allowed) {
  assert.equal(evaluate(grok(command), env).decision, 'allow', command);
}

// Invalid hook input must exit 2: in Claude Code only exit 2 blocks the tool
// call; any other non-zero exit is a non-blocking error and the command runs.
// 無效輸入必須以 exit 2 結束：Claude Code 只有 exit 2 會阻擋工具呼叫。
// Windows / MSYS / Cygwin path resolution & protection tests
// Windows / MSYS / Cygwin 路徑解析與保護測試
const { toWindowsDrivePath } = require('./hooks/protect-important-paths');

assert.equal(toWindowsDrivePath('/c', true), 'C:\\');
assert.equal(toWindowsDrivePath('/c/', true), 'C:\\');
assert.equal(toWindowsDrivePath('/c/Users/dave', true), 'C:\\Users\\dave');
assert.equal(toWindowsDrivePath('/C/Users/dave/project', true), 'C:\\Users\\dave\\project');
assert.equal(toWindowsDrivePath('/cygdrive/c/Users/dave', true), 'C:\\Users\\dave');
assert.equal(toWindowsDrivePath('/cygdrive/d', true), 'D:\\');
assert.equal(toWindowsDrivePath('C:\\Users\\dave', true), 'C:\\Users\\dave');
assert.equal(toWindowsDrivePath('/etc', true), '/etc');

const winEnv = {
  HOME: 'C:\\Users\\dave',
  BETTER_RM_PROTECTED_DIRS: 'C:\\Secrets;C:\\work\\protected',
  SystemRoot: 'C:\\Windows',
  ProgramFiles: 'C:\\Program Files',
  ProgramData: 'C:\\ProgramData',
};

const winCwd = 'C:\\Learning';

const winBlocked = [
  'rm -rf /c/Users/dave',
  'rm -rf /C/USERS/DAVE',
  'rm -rf ~',
  'rm -rf $HOME',
  'rm -rf ${HOME}',
  'rm -rf /c',
  'rm -rf /c/',
  'rm -rf "C:\\\\"',
  "rm -rf 'C:\\'",
  'rm -rf C:/',
  'rm -rf /d',
  'rm -rf "D:\\\\"',
  "rm -rf 'D:\\'",
  'rm -rf D:/',
  'rm -rf /cygdrive/c/Users/dave',
  'rm -rf /c/Windows',
  'rm -rf "C:\\Windows"',
  'rm -rf C:\\\\Windows',
  'rm -rf C:/Windows',
  'rm -rf /c/Program\\ Files',
  'rm -rf "C:\\Program Files"',
  'rm -rf /c/ProgramData',
  'rm -rf /c/Users',
  'rm -rf "C:\\Users"',
  'rm -rf C:/Users',
  'rm -rf /c/Secrets',
  'rm -rf "C:\\work\\protected"',
  'rm -rf /c/Users/dave/project/.git',
  'rm -rf "C:\\Learning\\.git"',
  'rm -rf C:/Learning/.git',
  'rm -rf .git',
  'rm -rf .*',
  'rm -rf /c/Users/dave/project/{.git,build}',
];

const winAllowed = [
  'rm -rf /c/Users/dave/subproject',
  'rm -rf /c/Users/dave/project/build',
  'rm -rf "C:\\Learning\\build"',
  'rm -rf C:/Learning/build',
  'rm /c/Users/dave/project/file.txt',
  'better-rm -r tmp',
  'echo hi\nrm -rf build',
];

for (const command of winBlocked) {
  const result = evaluate(claude(command, winCwd), winEnv, 'win32');
  assert.equal(result?.hookSpecificOutput?.permissionDecision, 'deny', `Windows blocked: ${command}`);
}

for (const command of winAllowed) {
  assert.equal(evaluate(claude(command, winCwd), winEnv, 'win32'), null, `Windows allowed: ${command}`);
}

// Test when Git Bash environment supplies MSYS-style HOME (/c/Users/dave)
const msysEnv = { HOME: '/c/Users/dave', BETTER_RM_PROTECTED_DIRS: '/c/Secrets' };
assert.equal(evaluate(claude('rm -rf /c/Users/dave', winCwd), msysEnv, 'win32')?.hookSpecificOutput?.permissionDecision, 'deny');
assert.equal(evaluate(claude('rm -rf ~', winCwd), msysEnv, 'win32')?.hookSpecificOutput?.permissionDecision, 'deny');
assert.equal(evaluate(claude('rm -rf $HOME', winCwd), msysEnv, 'win32')?.hookSpecificOutput?.permissionDecision, 'deny');
assert.equal(evaluate(claude('rm -rf /c/Secrets', winCwd), msysEnv, 'win32')?.hookSpecificOutput?.permissionDecision, 'deny');
assert.equal(evaluate(claude('rm -rf /c/Users/dave/app', winCwd), msysEnv, 'win32'), null);

// Verify all agent payload formats on Windows
const winCopilotResult = evaluate(copilot('rm -rf /c/Users/dave', winCwd), winEnv, 'win32');
assert.equal(winCopilotResult.permissionDecision, 'deny');

const winCursorResult = evaluate(cursor('rm -rf /c/Users/dave', winCwd), winEnv, 'win32');
assert.equal(winCursorResult.permission, 'deny');

const winAgResult = evaluate(antigravity('rm -rf /c/Users/dave', winCwd), winEnv, 'win32');
assert.equal(winAgResult.allow_tool, false);

const winGrokResult = evaluate(grok('rm -rf /c/Users/dave', winCwd), winEnv, 'win32');
assert.equal(winGrokResult.decision, 'deny');

const winPiResult = evaluate({ tool_input: { command: 'rm -rf /c/Users/dave' }, cwd: winCwd }, winEnv, 'win32');
assert.equal(winPiResult?.hookSpecificOutput?.permissionDecision, 'deny');

// Invalid hook input must exit 2: in Claude Code only exit 2 blocks the tool
// call; any other non-zero exit is a non-blocking error and the command runs.
// 無效輸入必須以 exit 2 結束：Claude Code 只有 exit 2 會阻擋工具呼叫。
const { spawnSync } = require('child_process');
const invalidInput = spawnSync(process.execPath, [require.resolve('./hooks/protect-important-paths')], { input: 'not-json', encoding: 'utf8' });
assert.equal(invalidInput.status, 2, 'invalid input must fail closed with exit 2');
assert.match(invalidInput.stderr, /Hook 輸入無效|Invalid hook input/, 'stderr must include denial reason');

console.log(`Hooks 測試通過 / Hook tests passed: ${blocked.length * 4 + allowed.length * 4 + 4 + winBlocked.length + winAllowed.length + 18}`);
