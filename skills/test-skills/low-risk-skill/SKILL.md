---
name: summarize-markdown
description: Reads markdown files in a project directory and produces a structured summary of their contents. Use when the user wants to summarize documentation, get an overview of markdown files, or understand a directory of docs.
---

# Summarize Markdown

Read markdown files in a specified directory and produce a structured
summary of their contents.

## Workflow

1. Accept a directory path from the user.
2. Use Glob to find all `*.md` files in the directory.
3. Use Read to read each file's contents.
4. For each file, extract:
   - The title (first `#` heading)
   - Any YAML frontmatter description
   - Key sections (second-level headings)
5. Present a summary table to the user:

| File | Title | Key Sections |
|------|-------|-------------|
| ... | ... | ... |

## Rules

- Only read files — never modify, create, or delete anything.
- Limit to the specified directory — do not traverse parent directories.
- If no markdown files are found, report that clearly.
