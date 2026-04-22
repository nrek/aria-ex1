# CLAUDE.md — aria-ex1

## What this is

**aria-ex1** is the installable Claude Code plugin under `plugin/`. It provides:

- **Per-repo** `CODEMAP.md` — one file per git repo, sections matched to stack (Django gets migrations, signals, Celery, etc.; Next.js gets routes, RTK Query, ...).
- **Per product group** `STITCH.md` — tables linking FE calls to BE views, entities, integrations; drift section can reuse workspace `analyze_projects.py` patterns.
- **`/distill`** — outputs tiered task specs per `plugin/template/distill/TASK.schema.md`.
- **Edit hooks** — structural enforcement: PreToolUse denies Edit/Write when the `[Rule 22]` compliance marker is missing; PostToolUse requires `[Rule 22 · Scope]` verification. Fail-open on detector error.
- **Structural signal detection** — auth, migration, model, routing, and external-service patterns surfaced in deny messages.

## Layout

```
aria-ex1/
├── README.md
├── CHANGELOG.md
├── CLAUDE.md          <- you are here
├── tests/
│   ├── run.sh
│   ├── repros/
│   └── fixtures/
└── plugin/
    ├── .claude-plugin/plugin.json
    ├── bin/           <- hook scripts (bash + embedded python3)
    ├── skills/        <- SKILL.md per command
    └── template/      <- rules/, codemap/, stitch/, distill/, LOCAL.md
```

## Development

1. Edit files under `plugin/`.
2. Run `sh tests/run.sh` to verify hook behavior.
3. Bump `plugin/.claude-plugin/plugin.json` version for release-worthy changes.
4. Test by copying `plugin/` to your local Claude plugins path and restarting Claude Code.

## Public repo hygiene

Do not commit secrets, internal URLs, or personal paths in examples.
