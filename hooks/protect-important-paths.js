#!/usr/bin/env node
// Block coding agents from passing protected directories to destructive shell commands.
// 阻擋 coding agent 將受保護目錄傳給破壞性 shell 命令。

'use strict';

const os = require('os');
const path = require('path');

const SYSTEM_DIRS = [
  '/', '/bin', '/boot', '/dev', '/etc', '/home', '/lib', '/lib64', '/mnt', '/opt',
  '/proc', '/root', '/sbin', '/sys', '/usr', '/var',
];

function toWindowsDrivePath(value, isWindows = (process.platform === 'win32')) {
  if (!isWindows || typeof value !== 'string') return value;
  const driveMatch = /^([A-Za-z]):[\\/]*$/.exec(value);
  if (driveMatch) return `${driveMatch[1].toUpperCase()}:\\`;
  const match = /^\/(?:cygdrive\/)?([A-Za-z])(\/.*)?$/.exec(value);
  if (!match) return value;
  const rest = (match[2] || '').replace(/\//g, '\\');
  return `${match[1].toUpperCase()}:${rest || '\\'}`;
}

function getSystemDirs(platform = process.platform, env = process.env) {
  if (platform !== 'win32') return SYSTEM_DIRS;
  const dirs = [...SYSTEM_DIRS];
  const winDir = env.SystemRoot || env.windir || 'C:\\Windows';
  dirs.push(winDir);
  if (env.ProgramFiles) dirs.push(env.ProgramFiles);
  if (env['ProgramFiles(x86)']) dirs.push(env['ProgramFiles(x86)']);
  if (env.ProgramW6432) dirs.push(env.ProgramW6432);
  if (env.ProgramData) dirs.push(env.ProgramData);
  if (env.ALLUSERSPROFILE) dirs.push(env.ALLUSERSPROFILE);
  const home = env.USERPROFILE || env.HOME || (typeof os.homedir === 'function' ? os.homedir() : '');
  if (home) {
    const winPath = path.win32 || path;
    const usersDir = winPath.dirname(toWindowsDrivePath(home, true));
    if (usersDir && !/^[A-Za-z]:\\?$/.test(usersDir)) {
      dirs.push(usersDir);
    }
  }
  return [...new Set(dirs)];
}

function shellWords(command) {
  const words = [];
  let word = '';
  let quote = '';
  let escaped = false;

  const str = String(command || '');
  for (let i = 0; i < str.length; i++) {
    const char = str[i];
    if (escaped) {
      word += char;
      escaped = false;
    } else if (char === '\\' && quote === '"') {
      const next = str[i + 1];
      if ('$`"\\\n'.includes(next)) {
        escaped = true;
      } else {
        word += char;
      }
    } else if (char === '\\' && quote !== "'") {
      escaped = true;
    } else if (quote) {
      if (char === quote) quote = '';
      else word += char;
    } else if (char === '"' || char === "'") {
      quote = char;
    } else if (';&|\n'.includes(char)) {
      if (word) words.push(word), word = '';
      words.push(char);
    } else if (/\s/.test(char)) {
      if (word) words.push(word), word = '';
    } else {
      word += char;
    }
  }
  if (escaped) word += '\\';
  if (word) words.push(word);
  return words;
}

function expandHome(value, home) {
  if (value === '~') return home;
  if (value.startsWith('~/') || value.startsWith('~\\')) return path.join(home, value.slice(2));
  if (value === '$HOME' || value === '${HOME}') return home;
  if (value.startsWith('$HOME/') || value.startsWith('$HOME\\')) return path.join(home, value.slice(6));
  if (value.startsWith('${HOME}/') || value.startsWith('${HOME}\\')) return path.join(home, value.slice(8));
  return value;
}

function normalizedTarget(value, cwd, home, isWindows = (process.platform === 'win32')) {
  let raw = value || '/';
  if (/^[A-Za-z]:[\\/]*$/.test(raw)) {
    raw = `${raw[0].toUpperCase()}:\\`;
  } else {
    raw = raw.replace(/[\\/]+$/, '') || '/';
    if (/^[A-Za-z]:[\\/]*$/.test(raw)) {
      raw = `${raw[0].toUpperCase()}:\\`;
    }
  }
  const winPath = isWindows ? (path.win32 || path) : path;
  const homeNorm = isWindows ? toWindowsDrivePath(home, isWindows) : home;
  const expanded = toWindowsDrivePath(expandHome(raw, homeNorm), isWindows);
  if (/[*?\[\]{}]/.test(expanded)) return expanded;
  return winPath.resolve(cwd, expanded);
}

function globCanMatchGit(value, isWindows = (process.platform === 'win32')) {
  const winPath = isWindows ? (path.win32 || path) : path;
  const basename = winPath.basename(value);
  if (!/[*?\[\]{}]/.test(basename)) return false;
  const alternatives = basename.replace(/^\{(.+)\}$/, '$1').split(',');
  return alternatives.some((pattern) => {
    const expression = pattern
      .replace(/[.+^$()|\\]/g, '\\$&')
      .replace(/\*/g, '.*')
      .replace(/\?/g, '.');
    try { return new RegExp(`^${expression}$`).test('.git'); } catch (_) { return true; }
  });
}

function protectedReason(target, cwd, home, extraDirs = [], isWindows = (process.platform === 'win32'), env = process.env) {
  const winPath = isWindows ? (path.win32 || path) : path;
  const homeNorm = isWindows ? toWindowsDrivePath(home, isWindows) : home;
  const normalized = normalizedTarget(target, cwd, homeNorm, isWindows);
  const systemDirs = getSystemDirs(isWindows ? 'win32' : 'posix', env);
  const exactDirs = [...systemDirs, homeNorm, ...extraDirs].map((item) => {
    const converted = isWindows ? toWindowsDrivePath(item, isWindows) : item;
    return winPath.resolve(converted);
  });

  const isMatch = (a, b) => {
    if (!a || !b) return false;
    return isWindows ? a.toLowerCase() === b.toLowerCase() : a === b;
  };

  if (exactDirs.some((dir) => isMatch(dir, normalized))) return normalized;

  // Protect whole drive roots on Windows (such as C:\ or D:\)
  // 保護 Windows 下的完整磁碟機根目錄（如 C:\ 或 D:\）
  if (isWindows && /^[A-Za-z]:[\\/]*$/.test(normalized)) return normalized;

  // Protect first-level mount roots under /mnt (such as /mnt/c), while allowing items inside them.
  // 保護 /mnt 的第一層掛載根（如 /mnt/c），但允許操作掛載點內的項目（如 /mnt/c/project）。
  const mntRelative = path.relative('/mnt', normalized);
  if (
    mntRelative &&
    !mntRelative.startsWith('..') &&
    !path.isAbsolute(mntRelative) &&
    !mntRelative.includes(path.sep)
  ) return normalized;

  if (normalized === '.git' || normalized.endsWith(`${winPath.sep}.git`) || normalized.endsWith('/.git')) return normalized;

  if (/(^|[\\/])\.git([\\/]|$)/.test(normalized)) return normalized;
  // A glob that can select .git is unsafe even though it cannot be resolved beforehand.
  // 可能選中 .git 的萬用字元無法事先解析，因此一律視為不安全。
  if (globCanMatchGit(normalized, isWindows)) return normalized;
  return null;
}

function commandTargets(command) {
  const words = shellWords(command);
  const targets = [];
  const separators = new Set([';', '&', '|', '\n']);
  let i = 0;

  while (i < words.length) {
    while (i < words.length && separators.has(words[i])) i += 1;
    if (i >= words.length) break;
    while (i < words.length && /^[A-Za-z_][A-Za-z0-9_]*=/.test(words[i])) i += 1;
    let executable = path.basename(words[i]);

    if (executable === 'sudo') {
      const optionsWithValue = new Set(['-u', '--user', '-g', '--group', '-h', '--host', '-p', '--prompt', '-C', '--close-from', '-T', '--command-timeout', '-R', '--chroot', '-D', '--chdir']);
      i += 1;
      while (i < words.length && words[i].startsWith('-')) {
        const option = words[i];
        i += optionsWithValue.has(option) ? 2 : 1;
      }
      executable = path.basename(words[i] || '');
    } else if (executable === 'command' || executable === 'builtin' || executable === 'noglob') {
      do i += 1; while (i < words.length && words[i].startsWith('-'));
      executable = path.basename(words[i] || '');
    } else if (executable === 'env') {
      i += 1;
      while (i < words.length && (words[i].startsWith('-') || /^[A-Za-z_][A-Za-z0-9_]*=/.test(words[i]))) i += 1;
      executable = path.basename(words[i] || '');
    }

    i += 1;
    if (['rm', 'rmdir'].includes(executable)) {
      for (; i < words.length && !separators.has(words[i]); i += 1) {
        const candidate = words[i];
        if (candidate === '--') continue;
        if (!candidate.startsWith('-') || candidate === '-') targets.push(candidate);
      }
    } else {
      while (i < words.length && !separators.has(words[i])) i += 1;
    }
  }
  return targets;
}

function extractInput(payload) {
  let toolInput = payload.tool_input ?? payload.toolArgs ?? payload.toolCall?.args ?? payload.toolInput ?? {};
  if (typeof toolInput === 'string') {
    try { toolInput = JSON.parse(toolInput); } catch (_) { toolInput = { command: toolInput }; }
  }
  const command = toolInput?.command ?? toolInput?.cmd ?? toolInput?.CommandLine ?? payload.command ?? '';
  const cwd = payload.cwd || toolInput?.Cwd || process.cwd();
  const isCopilot = 'toolName' in payload || 'toolArgs' in payload;
  const isAntigravity = 'toolCall' in payload;
  const isCursor = payload.hook_event_name === 'beforeShellExecution';
  const isGrok = 'toolInput' in payload || payload.hookEventName === 'PreToolUse';

  return {
    command,
    cwd,
    isCopilot,
    isAntigravity,
    isCursor,
    isGrok,
  };
}

function denial(reason, isCopilot, isAntigravity, isCursor, isGrok) {
  const message = `拒絕刪除受保護的目錄：${reason} / Refused to remove protected directory: ${reason}`;
  if (isGrok) {
    return {
      decision: 'deny',
      reason: message,
    };
  }
  if (isCursor) {
    return {
      permission: 'deny',
      user_message: message,
      agent_message: message,
    };
  }
  if (isAntigravity) {
    return {
      allow_tool: false,
      deny_reason: message,
    };
  }
  return isCopilot
    ? { permissionDecision: 'deny', permissionDecisionReason: message }
    : {
        hookSpecificOutput: {
          hookEventName: 'PreToolUse',
          permissionDecision: 'deny',
          permissionDecisionReason: message,
        },
      };
}

function evaluate(payload, env = process.env, platform = process.platform) {
  const { command, cwd, isCopilot, isAntigravity, isCursor, isGrok } = extractInput(payload);
  if (!command) {
    if (isGrok) return { decision: 'allow' };
    if (isCursor) return { permission: 'allow' };
    if (isAntigravity) return { allow_tool: true };
    return null;
  }
  const isWindows = platform === 'win32';
  const winPath = isWindows ? (path.win32 || path) : path;
  const delimiter = isWindows ? (path.win32 ? path.win32.delimiter : ';') : path.delimiter;
  const homeRaw = env.USERPROFILE || env.HOME || (typeof os.homedir === 'function' ? os.homedir() : '');
  const home = isWindows ? toWindowsDrivePath(homeRaw, isWindows) : homeRaw;
  const extraDirs = (env.BETTER_RM_PROTECTED_DIRS || '')
    .split(delimiter).filter(Boolean).map((item) => {
      const converted = isWindows ? toWindowsDrivePath(item, isWindows) : item;
      return winPath.resolve(cwd, converted);
    });

  for (const target of commandTargets(command)) {
    const reason = protectedReason(target, cwd, home, extraDirs, isWindows, env);
    if (reason) return denial(reason, isCopilot, isAntigravity, isCursor, isGrok);
  }

  if (isGrok) return { decision: 'allow' };
  if (isCursor) return { permission: 'allow' };
  if (isAntigravity) return { allow_tool: true };
  return null;
}

async function main() {
  let input = '';
  for await (const chunk of process.stdin) input += chunk;
  try {
    const result = evaluate(JSON.parse(input.replace(/^\uFEFF/, '')));
    if (result) process.stdout.write(JSON.stringify(result));
  } catch (error) {
    console.error(`Hook 輸入無效，已拒絕工具呼叫 / Invalid hook input; tool call denied: ${error.message}`);
    process.exitCode = 2;
  }
}

if (require.main === module) main();

module.exports = {
  commandTargets,
  evaluate,
  getSystemDirs,
  globCanMatchGit,
  normalizedTarget,
  protectedReason,
  shellWords,
  toWindowsDrivePath,
};
