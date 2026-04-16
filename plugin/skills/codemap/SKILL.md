---
description: "Generate or update per-repo CODEMAP.md (one repo per run). Stack-aware sections: Django, Next.js, Laravel, Expo, Node. Modes: create, inventory, update, section. Trigger: '/codemap', '/codemap create', '/codemap inventory'."
argument-hint: "<mode: create|inventory|update|section> [section-name]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# /codemap — Per-repo codebase map

**One `CODEMAP.md` per repository root.** Do not merge frontend + backend into one file.

## Step 0: Resolve root & mode

- Walk up from CWD to find project root: nearest `CLAUDE.md`, or `.git`, or user-specified path.
- Default output: `{project_root}/CODEMAP.md`.
- Modes: `(none)` → if CODEMAP exists ask update vs recreate; else `create`. `inventory` = scan only. `update` = git-based section refresh. `section <name>` = one section.

Read `~/.claude/aria-ex1.local.md` for optional `repo_groups` (to label the repo in headers only).

## Step 1: Detect stack

**Backend signals:** `manage.py` → **Django**; `composer.json` + artisan → **Laravel**; `package.json` with `express`/`fastify`/`nestjs` → **Node**.

**Frontend signals:** `next.config.*` → **Next.js**; `app.json` + `expo` → **Expo**; `package.json` with `react` → **React SPA**.

Report a short table: root, stack, version hints. User may correct.

## Step 2: Index (inventory)

Glob/grep for framework-specific paths (see sections below). In `inventory` mode, print summary and stop.

## Step 3: Section templates (write in order)

Start from `${CLAUDE_PLUGIN_ROOT}/template/codemap/CODEMAP.template.md`. Fill **Directory** last.

### Django (backend repo)

1. **0. Identity & stack** — Python/Django/DRF versions, `settings` module, `INSTALLED_APPS` summary.
2. **1. URLConf tree** — root `urls.py` → includes; note `path` prefixes.
3. **2. Apps registry** — table per app: models (major classes), `views`, `serializers`, `urls`, `admin`, `signals`, `management/commands`.
4. **3. Migration state** — latest migration per app if inferable; note squashing.
5. **4. Middleware chain** — `MIDDLEWARE` order + custom middleware files.
6. **5. Permissions & auth** — DRF defaults, JWT/session, public allowlists if found.
7. **6. Async work** — Celery beat, cron, Channels consumers (paths only).
8. **7. Signals** — `post_save`, etc., file:handler list.
9. **8. Integrations** — Stripe, Twilio, S3, SendGrid, Algolia… with env keys + file refs.
10. **9. Env matrix** — grouped env vars (no secrets).

### Next.js / React (frontend repo)

1. **0. Identity & stack** — Next version, TS, major libs.
2. **1. Route tree** — `app/**/page.tsx` or `pages/**`.
3. **2. Hooks** — `hooks/**` with one-line purpose each.
4. **3. State** — Redux/RTK: slices; table of `endpoint → method → path`.
5. **4. Middleware** — `middleware.ts` behavior (first ~30 lines).
6. **5. Components** — major areas under `components/`.
7. **6. API client** — base URL, interceptors, refresh.
8. **7. Env matrix**

### Laravel

Routes `routes/*.php`, controllers, jobs, middleware, integrations — mirror Django density.

### Expo / React Native

Screens, navigation, API modules, env — no Django-shaped sections.

## Step 4: Directory & build log

After sections exist, fill **Directory** table with line ranges or grep anchors. Add **Build log** table.

## Step 5: Stats

Report line count, section count, token estimate for Directory-only load.

## Rules

- **Feature-organized** optional within a repo; **never** mix two repos in one CODEMAP.
- Prefer **tables and paths** over prose.
- **Mermaid** only where it clarifies auth or data flow (≤3 small diagrams per file).
- Large files: grep signatures first, then selective reads.
