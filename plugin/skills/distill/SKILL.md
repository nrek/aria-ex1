---
description: "Turn raw task text into a tiered executable spec per TASK.schema.md. Optional --group and --tier. Trigger: '/distill', '/distill --group=myproduct \"…\"'."
argument-hint: "<text or path> [--group=id] [--tier=micro|standard|full]"
allowed-tools: Read, Write, Edit, Glob, Grep
---

# /distill — Task transformation

## Step 0: Inputs

- Raw task: inline string or read from file path.
- Optional `--group=<id>`: read `~/.claude/aria-ex1.local.md`, load `CODEMAP.md` for backend + each frontend, and `stitch_path` `STITCH.md` if present.
- Optional `--tier=micro|standard|full`; else compute score:

| Signal | Points |
|--------|--------|
| >1 layer (FE+BE, BE+DB, …) | +2 |
| new endpoint / route / model / migration | +2 |
| external service (Stripe, Twilio, S3, SendGrid, Algolia, …) | +2 |
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

One implementation path per layer section. No option lists.

## Step 3: Validation

- All `[R]` present for the tier.
- No banned words from TASK.schema.md.
- No empty `[L]` sections.
- With `--group`, cited paths must appear in loaded CODEMAP/STITCH.

On failure: self-correct once, then put remaining gaps under **Assumptions** as blocking.

## Step 4: Output

Write markdown to user-chosen path or default `TASK.md` in CWD. No backlog or side files.
