# aria-ex1

Execution-First Claude Code plugin: per-repo codemaps, cross-repo stitching, tiered task distillation, edit-time enforcement.

## Quick start

1. Install this `plugin/` directory as a Claude Code plugin.
2. Run `/setup` — creates `~/.claude/aria-ex1.local.md` with `repo_groups` and optional `critical_paths`.
3. In each repo root, run `/codemap create` (or `inventory` / `update` / `section`).
4. For a registered group, run `/stitch create <group>` to emit `STITCH.md` at the configured `stitch_path`.
5. Use `/distill` with optional `--group=` and `--tier=micro|standard|full`.

See [QUICKSTART.md](QUICKSTART.md) for a short walkthrough.

## License

CC BY-NC-SA 4.0 — see [LICENSE](LICENSE).
