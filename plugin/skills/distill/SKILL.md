---
description: "Turn raw task text into a tiered executable spec per TASK.schema.md. Optional --group, --tier, and output flags. Trigger: '/distill', '/distill --group=myproduct \"…\"'."
argument-hint: "<text or path> [--group=id] [--tier=micro|standard|full] [--append|--out=path|--no-archive]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# /distill — Task transformation

Turn raw task text into a tiered executable spec following `TASK.schema.md`.

## Step 0: Inputs

- Raw task: inline string, read from file path, or prompt user to paste if no argument was provided.
- Optional `--group=<id>`: read `~/.claude/aria-ex1.local.md`, load `CODEMAP.md` for backend + each frontend, and `stitch_path` `STITCH.md` if present.
- Optional `--tier=micro|standard|full`; else compute score:

| Signal | Points |
|--------|--------|
| >1 layer (FE+BE, BE+DB, …) | +2 |
| new endpoint / route / model / migration | +2 |
| external service (Stripe, Twilio, S3, SendGrid, Algolia, OpenAI, Vercel, …) | +2 |
| auth / permissions / security | +2 |
| input >150 words or multi-paragraph | +1 |
| names >3 files | +1 |
| single-sentence trivial edit | -3 |

- Score ≤ 0 → **micro**; 1–3 → **standard**; ≥ 4 → **full**

## Step 1: Schema

Follow `${CLAUDE_PLUGIN_ROOT}/template/distill/TASK.schema.md` section tags `[R]` `[L]` `[O]` `[F]`.

**Always emit:** 1 Objective, 2 Scope, 5 Dependencies & API Requirements, 10 QA, 11 DoD.

**Layers 6–8:** include Frontend / Backend / Database only if justified by the task; never empty headings.

**Tier:** `full` adds **3 Non-Goals**. `standard` and `full` add **4 Assumptions** and **9 Edge Cases** when non-empty. `micro` skips Non-Goals; Assumptions only if blocking ambiguity exists.

## Step 2: Single chosen approach

One implementation path per layer section. No option menus inside a layer. Matches Rule 22's Execute discipline: commit to one plan.

## Step 3: Validation

- All `[R]` present for the tier.
- No empty `[L]` sections.
- With `--group`, every cited file path must appear in the loaded CODEMAP or STITCH content. If the model invents a path, remove the citation or promote the uncertainty to **Assumptions** as blocking.
- Advisory vocabulary check: scan output for `TASK.schema.md` phrases such as `flexible`, `extensible`, `scalable framework`, `we could also`, `alternatively`, `one option`, `potentially`, and `might want to`. Prefer concrete alternatives. Surface remaining hits as soft warnings in the final summary.

On failure: self-correct once, then put remaining gaps under **Assumptions** as blocking.

## Step 4: Output

Default output path: `TASK.md` in CWD.

**Overwrite safety:**
- If `TASK.md` exists and is non-empty, first-run behavior: emit a one-time notice explaining the auto-archive default.
- Default: move existing `TASK.md` to `.aria-distill/archive/TASK-YYYY-MM-DD-HHMMSS.md`, then write fresh output to `TASK.md`.
- Archive directory `.aria-distill/archive/` is created lazily on first archive. First-run notice suggests adding `.aria-distill/` to `.gitignore`.

**Flags override defaults:**
- `--append` — add the new spec below existing `TASK.md` content, separated by `---` and a `## Distilled YYYY-MM-DD HH:MM` header. No archive.
- `--out=<path>` — write to the specified path. Existing `TASK.md` is untouched; no archive.
- `--no-archive` — overwrite existing `TASK.md` without archiving. Destructive opt-in; display a warning before proceeding.

**Writing steps:**
1. Determine final target path from flags / default.
2. If archive applies: verify `.aria-distill/archive/` exists, creating it if needed, then move the existing file in with a timestamped name.
3. Write the spec to the target path.
4. Print summary: tier chosen, score when auto-tiered, target path, archive path when used, and advisory-vocabulary warnings when present.

No backlog or side files beyond `.aria-distill/archive/`.
