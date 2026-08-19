# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Developers, system administrators, DevOps engineers, and AI coding agent operators working on Linux, macOS, and Unix-like environments who need a safer terminal workflow and protection against catastrophic accidental file deletions (`rm -rf /`, deleting `.git`, project directories, or critical system paths).

## Product Purpose

`better-rm` is a safe, drop-in replacement for the standard Unix `rm` command. Instead of permanently deleting files, it moves them to a structured trash directory (`~/.Trash`) while preserving original directory hierarchies, nanosecond timestamps, and content hashes. It also provides automatic one-command file restoration (`rm --restore`), comprehensive deletion logs, and safety hooks (`PreToolUse`) across 9+ AI coding agents (Claude Code, GitHub Copilot CLI, Cursor, Codex, Antigravity, Qoder, Pi, OpenCode, Grok Build).

## Positioning

Unlike standard destructive `rm` or ad-hoc trash scripts, `better-rm` provides full CLI option compatibility (`-r`, `-f`, `-i`, `-I`, `-v`), hierarchical trash storage with collision-proof nanosecond timestamps and content hashes, audit logs in `XDG_STATE_HOME`, zero-config restore (`rm --restore`), and native security guardrail hooks protecting AI agents against dangerous automated shell executions.

## Operating Context

- Command-line environments (Bash 4.0+, Zsh, macOS Terminal, Linux shells, WSL).
- Developer project workflows with Git repositories.
- AI Agent execution environments (Claude Code, Codex, GitHub Copilot CLI, Cursor, Antigravity, OpenCode, Pi, Qoder, Grok Build).
- Single-page web landing page for product showcase, interactive demo, installation instructions, documentation, and agent setup.

## Capabilities and Constraints

- **Drop-in `rm` compatibility**: Supports `-r`/`-R`, `-f`, `-i`, `-I`, `-v`, `--help`, `--version`.
- **System Protection**: Built-in hard blocks for `/`, `/bin`, `/etc`, `/home`, `/usr`, `/var`, `/root`, `/mnt` mount roots, `$HOME`, and `.git` anywhere.
- **Trash Architecture**: Preserves exact path hierarchy in `~/.Trash/path/to/file__timestamp__hash`.
- **Restoration**: One-step file/folder restoration (`rm --restore <target>` or `rm -f --restore`).
- **Deletion Audit Log**: Structured logs at `~/.local/state/better-rm/deletion.log`.
- **Agent Hooks Integration**: Multi-agent pre-execution interceptor (`install-hooks.sh -a <agent>`).
- **Single-Page Showcase Website**:
  - Responsive Web Design (RWD) for mobile, tablet, and desktop.
  - Dark and Light theme toggle with auto-detection of OS color scheme preference.
  - 9-language internationalization (zh-TW, zh-CN, en, ja, ko, vi, th, ms, id) with browser language auto-detection and manual selector.
  - Interactive terminal simulation demo showing safe delete, blocked dangerous delete, and instant restore.
  - One-click copy commands for quick install and agent hooks setup.
  - Visual comparison table (Standard `rm` vs. `better-rm`).

## Brand Commitments

- **Name**: `better-rm`
- **Tagline**: 給你一個更好、更安全的 `rm` 命令 / A Better, Safer `rm` Command
- **Tone & Aesthetic**: Clean, modern, trustworthy, high-craft developer tool aesthetic with terminal-inspired elements and elegant visual hierarchy.

## Evidence on Hand

- Production-ready `better-rm` shell script, `install.sh`, and `install-hooks.sh`.
- PreToolUse security script `hooks/protect-important-paths.js` supporting 9 coding agents.
- Comprehensive test suites (`test-better-rm.sh`, `test-install-hooks.sh`, `test-hooks.js`).
- Complete documentation in `README.md` and `CHANGELOG.md`.

## Product Principles

1. **Never Destroy by Default**: Safeguard user files by moving to trash with preserved path hierarchy rather than unrecoverable deletion.
2. **Absolute Defense for Critical Paths**: Refuse destructive operations on system and version control roots without compromise.
3. **Drop-in Frictionless Experience**: Instant one-line installation, full standard CLI compatibility, and zero learning curve.
4. **Agent-Aware Security**: Protect both human engineers and autonomous AI coding agents from destructive deletions.
