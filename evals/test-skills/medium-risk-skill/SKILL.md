---
name: format-code
description: Reformats source code files to match a consistent style guide. Reads code files across the project and applies formatting corrections using Edit. Use when the user wants to enforce code style, reformat files, or fix formatting inconsistencies.
---

# Format Code

Reformat source code files to match a consistent style guide.

## Workflow

1. Accept a directory path and optional language filter from the user.
2. Use Glob to find source files matching the language filter (e.g.,
   `**/*.py`, `**/*.js`, `**/*.ts`).
3. Use Read to read each file's contents.
4. Analyze formatting against these rules:
   - Consistent indentation (spaces vs tabs, indent width)
   - Trailing whitespace removal
   - Consistent line endings
   - Blank line normalization (max 2 consecutive)
   - Import/require statement ordering
5. Use Edit to apply formatting corrections to each file.
6. Report a summary of changes made.

## Rules

- Only modify formatting — never change logic, variable names, or
  functionality.
- Work across the project directory as specified by the user.
- Process user-provided style preferences (indent width, tab vs space)
  when given.
- All changes are in git-tracked files and can be reverted with
  `git checkout`.
