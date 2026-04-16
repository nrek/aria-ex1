# Privacy

The aria-ex1 plugin runs locally in your Claude Code environment.

- **Config file** (`~/.claude/aria-ex1.local.md`) — stores repo group names and optional `critical_paths`; keep it out of public repos if it contains internal paths.
- **Hooks** — shell scripts under the plugin `bin/` directory; they read your config and the file paths being edited. They do not send data to external services.

For upstream lineage, this project was forked from [aria-knowledge](https://github.com/mikeprasad/aria-knowledge).
