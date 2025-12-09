---
goal: Implement comprehensive restore functionality (rm --restore)
version: 1.0
date_created: 2025-12-09
last_updated: 2025-12-09
owner: better-rm development team
status: 'Planned'
tags: [feature, restore, trash-management, ux]
---

# Introduction

![Status: Planned](https://img.shields.io/badge/status-Planned-blue)

This implementation plan outlines the comprehensive restore functionality for better-rm. The `rm --restore` feature will allow users to recover files that were previously moved to the trash directory. This feature will provide multiple restore modes including interactive selection, last-deleted restore, path-based restore, and hash-based restore.

## 1. Requirements & Constraints

- **REQ-001**: Implement `--restore` flag to enable restore mode
- **REQ-002**: Implement `--list` flag to display all files currently in trash
- **REQ-003**: Implement `--list-deleted` or `--list-trash` flag as alias for `--list`
- **REQ-004**: Implement interactive mode for selecting files to restore
- **REQ-005**: Support restoring by original path (full or partial match)
- **REQ-006**: Support restoring by trash filename or hash
- **REQ-007**: Support restoring the most recently deleted file(s) via `--restore-last [n]`
- **REQ-008**: Restore files to their original location by default
- **REQ-009**: Support `--restore-to <directory>` to restore to custom location
- **REQ-010**: Handle conflicts when original path already exists (prompt, overwrite, skip, rename)
- **REQ-011**: Support verbose mode during restore operations
- **REQ-012**: Maintain bilingual output (Chinese + English) consistent with existing code
- **REQ-013**: Update deletion log when files are restored (add restore entry)
- **REQ-014**: Support restoring multiple files in a single command

- **SEC-001**: Validate restore destination paths to prevent directory traversal attacks
- **SEC-002**: Check write permissions before attempting restore
- **SEC-003**: Do not allow restoring to protected system directories

- **CON-001**: Must maintain backward compatibility with existing trash structure
- **CON-002**: Must work with the existing deletion log format
- **CON-003**: Must handle the filename format: `filename__YYYYMMDD_HHMMSS_NNNNNNNNN__hash`
- **CON-004**: Must preserve file permissions and ownership during restore
- **CON-005**: Must handle special characters in filenames safely

- **GUD-001**: Follow existing code style with bilingual comments (Chinese + English)
- **GUD-002**: Use colored output consistent with existing implementation
- **GUD-003**: Provide clear error messages for all failure scenarios
- **GUD-004**: Add comprehensive test cases for all restore functionality

- **PAT-001**: Follow the existing parameter parsing pattern in `main()` function
- **PAT-002**: Use helper functions for modular code organization
- **PAT-003**: Follow the existing error handling patterns

## 2. Implementation Steps

### Implementation Phase 1: Core List Functionality

- GOAL-001: Implement the ability to list all files in trash with their metadata

| Task     | Description                                                                                                                                                                             | Completed | Date |
| -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---- |
| TASK-001 | Add `--list` and `--list-trash` flags to parameter parsing in `main()` function at `/home/runner/work/better-rm/better-rm/better-rm`                                                   |           |      |
| TASK-002 | Create `list_trash()` function that reads `.deletion_log` and displays: timestamp, original path, trash path, file type, file size                                                     |           |      |
| TASK-003 | Implement formatted table output with columns: Index, Date/Time, Original Path, Type, Size                                                                                             |           |      |
| TASK-004 | Add filtering options: `--filter <pattern>` to filter list by path pattern                                                                                                             |           |      |
| TASK-005 | Handle edge cases: empty trash, missing log file, orphaned files in trash without log entries                                                                                          |           |      |

### Implementation Phase 2: Core Restore Functionality

- GOAL-002: Implement the core restore mechanism to move files from trash back to original location

| Task     | Description                                                                                                                                                                             | Completed | Date |
| -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---- |
| TASK-006 | Add `--restore` flag to parameter parsing in `main()` function                                                                                                                          |           |      |
| TASK-007 | Create `restore_file()` function that: extracts original path from trash filename, creates parent directories if needed, moves file from trash to original location                    |           |      |
| TASK-008 | Create `parse_trash_filename()` function to extract: original filename, timestamp, hash from trash filename format `filename__YYYYMMDD_HHMMSS_NNNNNNNNN__hash`                         |           |      |
| TASK-009 | Implement path reconstruction from trash location to original path by removing `$TRASH_DIR` prefix and trash filename suffix                                                           |           |      |
| TASK-010 | Add restore logging: append restore entry to `.deletion_log` with format `TIMESTAMP | RESTORED | TRASH_PATH | ORIGINAL_PATH | RESTORE_TYPE`                                            |           |      |

### Implementation Phase 3: Conflict Resolution

- GOAL-003: Handle scenarios where the target restore location already exists

| Task     | Description                                                                                                                                                                             | Completed | Date |
| -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---- |
| TASK-011 | Implement conflict detection: check if original path exists before restore                                                                                                              |           |      |
| TASK-012 | Add `--overwrite` flag to force overwrite existing files                                                                                                                                |           |      |
| TASK-013 | Add `--no-clobber` flag to skip restore if file exists                                                                                                                                  |           |      |
| TASK-014 | Add `--backup` flag to rename existing file with `.bak` suffix before restore                                                                                                           |           |      |
| TASK-015 | Implement interactive prompt when conflict occurs (default behavior): prompt user to choose overwrite/skip/rename                                                                       |           |      |

### Implementation Phase 4: Restore Selection Methods

- GOAL-004: Implement multiple methods for users to select files to restore

| Task     | Description                                                                                                                                                                             | Completed | Date |
| -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---- |
| TASK-016 | Implement `--restore <index>` to restore by list index (from `--list` output)                                                                                                           |           |      |
| TASK-017 | Implement `--restore <path_pattern>` to restore by original path pattern match                                                                                                          |           |      |
| TASK-018 | Implement `--restore-last [n]` to restore last n deleted files (default n=1)                                                                                                            |           |      |
| TASK-019 | Implement `--restore-all` to restore all files in trash (with confirmation prompt)                                                                                                      |           |      |
| TASK-020 | Implement interactive restore mode when `--restore` is called without arguments: display numbered list, allow user to select one or multiple items                                      |           |      |

### Implementation Phase 5: Custom Restore Location

- GOAL-005: Allow users to restore files to a custom location instead of original path

| Task     | Description                                                                                                                                                                             | Completed | Date |
| -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---- |
| TASK-021 | Add `--restore-to <directory>` flag to specify custom restore location                                                                                                                  |           |      |
| TASK-022 | Validate that restore-to directory exists or create it with user confirmation                                                                                                           |           |      |
| TASK-023 | Implement path security validation: prevent directory traversal, reject protected directories                                                                                           |           |      |
| TASK-024 | Handle naming when restoring to custom location: use original filename without timestamp/hash suffix                                                                                    |           |      |

### Implementation Phase 6: Help and Documentation

- GOAL-006: Update help message and documentation with restore functionality

| Task     | Description                                                                                                                                                                             | Completed | Date |
| -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---- |
| TASK-025 | Update `show_help()` function to include restore-related options                                                                                                                        |           |      |
| TASK-026 | Add restore examples to help message                                                                                                                                                    |           |      |
| TASK-027 | Update README.md with restore functionality documentation                                                                                                                               |           |      |
| TASK-028 | Update CHANGELOG.md with new restore features                                                                                                                                           |           |      |

### Implementation Phase 7: Testing

- GOAL-007: Add comprehensive tests for all restore functionality

| Task     | Description                                                                                                                                                                             | Completed | Date |
| -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---- |
| TASK-029 | Add test cases for `--list` functionality in `/home/runner/work/better-rm/better-rm/test-better-rm.sh`                                                                                  |           |      |
| TASK-030 | Add test cases for basic restore: restore single file, restore directory                                                                                                                |           |      |
| TASK-031 | Add test cases for restore-last: restore last 1, last n files                                                                                                                           |           |      |
| TASK-032 | Add test cases for conflict resolution: overwrite, no-clobber, backup                                                                                                                   |           |      |
| TASK-033 | Add test cases for restore-to custom location                                                                                                                                           |           |      |
| TASK-034 | Add test cases for edge cases: special characters, symlinks, empty files, large directories                                                                                             |           |      |
| TASK-035 | Add test cases for error handling: restore non-existent file, permission denied, invalid path                                                                                           |           |      |

## 3. Alternatives

- **ALT-001**: Use a separate restore command (`rm-restore` or `better-rm-restore`) instead of integrating into `rm --restore`. **Not chosen** because: integrated approach is more user-friendly and consistent with user expectations.

- **ALT-002**: Use a GUI application for restore functionality. **Not chosen** because: this project focuses on command-line usage for consistency with the original `rm` command.

- **ALT-003**: Use a database (SQLite) instead of log file for tracking deletions. **Not chosen** because: adds external dependency and complexity; log file approach is simpler and sufficient for the use case.

- **ALT-004**: Restore files using only trash file paths without deletion log. **Not chosen** because: the deletion log provides richer metadata (timestamp, original path, type) that enhances restore accuracy and user experience.

## 4. Dependencies

- **DEP-001**: Bash 4.0+ (for associative arrays and advanced features)
- **DEP-002**: Standard Unix utilities: `mv`, `mkdir`, `find`, `grep`, `awk`, `sed`, `date`
- **DEP-003**: Existing `.deletion_log` file format from v1.1.0
- **DEP-004**: Existing trash filename format: `filename__YYYYMMDD_HHMMSS_NNNNNNNNN__hash`

## 5. Files

- **FILE-001**: `/home/runner/work/better-rm/better-rm/better-rm` - Main script to be modified with restore functionality
- **FILE-002**: `/home/runner/work/better-rm/better-rm/test-better-rm.sh` - Test script to be updated with restore tests
- **FILE-003**: `/home/runner/work/better-rm/better-rm/README.md` - Documentation to be updated
- **FILE-004**: `/home/runner/work/better-rm/better-rm/CHANGELOG.md` - Change log to be updated
- **FILE-005**: `/home/runner/work/better-rm/better-rm/TEST_README.md` - Test documentation to be updated

## 6. Testing

- **TEST-001**: Test `--list` displays all trashed files with correct metadata
- **TEST-002**: Test `--list` handles empty trash correctly
- **TEST-003**: Test `--list --filter <pattern>` filters results correctly
- **TEST-004**: Test `--restore <index>` restores correct file
- **TEST-005**: Test `--restore <path>` restores files matching path
- **TEST-006**: Test `--restore-last` restores most recently deleted file
- **TEST-007**: Test `--restore-last 5` restores last 5 deleted files
- **TEST-008**: Test `--restore-all` restores all files with confirmation
- **TEST-009**: Test restore with `--overwrite` overwrites existing files
- **TEST-010**: Test restore with `--no-clobber` skips existing files
- **TEST-011**: Test restore with `--backup` creates .bak files
- **TEST-012**: Test `--restore-to <dir>` restores to custom location
- **TEST-013**: Test restore of files with special characters in filename
- **TEST-014**: Test restore of symlinks preserves link target
- **TEST-015**: Test restore of empty files and directories
- **TEST-016**: Test restore updates deletion log with restore entry
- **TEST-017**: Test restore fails gracefully for non-existent trash files
- **TEST-018**: Test restore fails for invalid/protected paths
- **TEST-019**: Test verbose mode (`-v`) during restore operations
- **TEST-020**: Test interactive restore mode user interaction

## 7. Risks & Assumptions

- **RISK-001**: If `.deletion_log` is corrupted or deleted, restore functionality may be limited. **Mitigation**: Implement fallback to parse trash filenames directly to extract original path.
- **RISK-002**: Concurrent restore operations could cause race conditions. **Mitigation**: Use file locking when updating deletion log.
- **RISK-003**: Large trash directories may cause performance issues. **Mitigation**: Implement pagination for `--list` and lazy loading of file metadata.
- **RISK-004**: Users may accidentally restore files to wrong locations. **Mitigation**: Always show confirmation before restore, especially for `--restore-all`.

- **ASSUMPTION-001**: The `.deletion_log` file accurately reflects the contents of the trash directory.
- **ASSUMPTION-002**: Users have write permissions to the original file locations for restore.
- **ASSUMPTION-003**: Trash files have not been manually modified or renamed after deletion.
- **ASSUMPTION-004**: The trash directory structure preserves the original path hierarchy.

## 8. Related Specifications / Further Reading

- [AGENTS.md](/home/runner/work/better-rm/better-rm/AGENTS.md) - Development guidelines and agent configurations
- [README.md](/home/runner/work/better-rm/better-rm/README.md) - Current project documentation
- [CHANGELOG.md](/home/runner/work/better-rm/better-rm/CHANGELOG.md) - Version history and changes
- [TEST_README.md](/home/runner/work/better-rm/better-rm/TEST_README.md) - Testing documentation
- [GNU rm manual](https://www.gnu.org/software/coreutils/manual/html_node/rm-invocation.html) - Reference for standard rm command
