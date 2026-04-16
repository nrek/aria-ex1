# CLAUDE.md — aria-ex1

## What this is

**aria-ex1** is the installable Claude Code plugin under `plugin/`. It provides:

- **Per-repo** `CODEMAP.md` — one file per git repo, sections matched to stack (Django gets migrations, signals, Celery, etc.; Next.js gets routes, RTK Query, …).
- **Per product group** `STITCH.md` — tables linking FE calls to BE views, entities, integrations; drift section can reuse workspace `analyze_projects.py` patterns.
- **`/distill`** — outputs tiered task specs per `plugin/template/distill/TASK.schema.md`.
- **Edit hooks** — enforce visible change assessment on every file write.

## Layout

```
aria-ex1/
├── README.md
├── CHANGELOG.md
├── CLAUDE.md          ← you are here
└── plugin/
    ├── .claude-plugin/plugin.json
    ├── bin/           ← hook scripts (bash)
    ├── skills/        ← SKILL.md per command
    └── template/      ├── rules/, codemap/, stitch/, distill/, LOCAL.md
```

## Development

1. Edit files under `plugin/`.
2. Bump `plugin/.claude-plugin/plugin.json` version for release-worthy changes.
3. Test by copying `plugin/` to your local Claude plugins path and restarting Claude Code.

## Public repo hygiene

Do not commit secrets, internal URLs, or personal paths in examples.
