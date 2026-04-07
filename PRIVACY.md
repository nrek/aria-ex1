# Privacy Policy — ARIA

**Last updated:** 2026-04-07

## Summary

ARIA does not collect, transmit, or store any data outside your local machine. Everything stays on your filesystem.

## What ARIA accesses

- **Your knowledge folder** (configured during `/setup`) — reads and writes knowledge files, backlogs, indexes, and intake items
- **Claude Code session transcripts** — reads local JSONL transcript files for knowledge extraction and audit digests
- **Your ARIA config file** (`~/.claude/aria-knowledge.local.md`) — reads plugin settings you configured during setup
- **Your project files** — hook scripts read file paths to classify edit impact; no file contents are transmitted anywhere

## What ARIA does NOT do

- No network requests, API calls, or telemetry
- No data collection or analytics
- No external service connections
- No cookies, tracking, or fingerprinting
- No data shared with the plugin author or any third party

## Data storage

All data created by ARIA lives in your local knowledge folder and Claude Code's local plugin cache. Uninstalling the plugin and deleting your knowledge folder removes everything.

## Contact

Questions about this policy: [github.com/mikeprasad/aria-knowledge/issues](https://github.com/mikeprasad/aria-knowledge/issues)
