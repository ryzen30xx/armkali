---
name: verify
description: Run shellcheck, shfmt, and bash syntax checks on all shell scripts in the project. Use when verifying script correctness before committing or after significant changes.
---

Run the following checks on all `.sh` files in the project. Report any issues found.

## Checks to run

1. **Syntax check**: `bash -n <file>` for every `.sh` file
2. **ShellCheck lint**: `shellcheck -x <file>` for every `.sh` file
3. **shfmt format check**: `shfmt -d -i 2 <file>` for every `.sh` file (shows diff of what would change)

## How to run

Find all `.sh` files:
```bash
find . -name '*.sh' -type f
```

Then run each check on every file. If any check fails, show the output and the file path.

## Expected outcome

- Exit 0 with no output means all scripts pass
- Any failures should be reported with file path, line number, and the specific issue
- After reporting, offer to fix the issues automatically (shfmt -w for formatting, manual fix suggestions for shellcheck warnings)
