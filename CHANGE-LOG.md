# Change Log

## 2026-07-05 03:12
- Files changed: `.gitignore` (new, untracked)
- Purpose: Add basic repo hygiene. Repo previously had no `.gitignore` at all. New file ignores `*.log`, `*.tmp`, `*.bak`, editor swap/backup files (`*~`, `*.swp`), and `.DS_Store`. Chosen after inspecting the repo contents: two shell scripts (`update-system.sh`, `update-system-zsh.sh`) which only log to `/var/log/system-update.log`, outside the repo; no test suite or in-repo config/artifact generation was found, so no additional patterns were needed.
- Risk level: Low — additive, non-functional change; does not modify either shell script or any existing tracked file.
- Commit: 51f959c
