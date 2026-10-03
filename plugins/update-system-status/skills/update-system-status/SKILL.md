---
name: update-system-status
description: Keep `~/system-docs/` accurate (private repo ArtRichards/system-docs, one branch per host; always work on the `<hostname>` branch, never `main`) — update `system-status.md`, ensure new plans/specs land there, archive completed plans to `~/system-docs/archive/YYYY-MM-DD/`, and keep `~/system-docs/INDEX.md` in sync with the directory's contents. Trigger proactively at the end of turns that touched system state (services, ZFS pools, disks, hardware, sudo grants, samba, networking, kernel/driver, persistent system-level configs), that surfaced new system facts (smartctl findings, version pins, latent quirks), or that authored/completed a system plan. Skip for purely application or code work that doesn't change the operator's mental model of the host. Always invoke without asking when the criteria match.
---

# Update System Status

This skill owns the hygiene of `~/system-docs/` — the canonical home for host
documentation. That includes `system-status.md` (the living facts log), any
plans/specs/runbooks for system work, the dated archive of completed plans,
and `INDEX.md` — a one-line-per-doc index that stays in lockstep with the
directory.

## Repo layout

`~/system-docs/` on every host is a checkout of the **private** GitHub repo
`ArtRichards/system-docs`, laid out one branch per machine:

- `main` — skeleton only: `README.md`, empty `system-status.md` and `INDEX.md`
  templates, `.gitignore`, empty `archive/`. **Never commit host facts to main.**
- `<hostname>` — that host's live docs (e.g. `robbie`, `voyager`). Each host's
  checkout stays on its own branch and tracks `origin/<hostname>`.

Before any edit, confirm the checkout is on the host's branch:
`git -C ~/system-docs branch --show-current` must equal `hostname`. If it is
`main` or anything else, stop and fix the checkout first
(`git -C ~/system-docs checkout <hostname>`); do not edit on the wrong branch.

**Where this skill itself lives:** like every ArtRichards-authored skill, the
source is the `~/opt/personal-skill-marketplace` clone on each host, symlinked
into `~/.claude/skills/`. Edit it there, commit, push, and `git pull` on the
other hosts (see that repo's README). Never edit the plugin cache copy. When
asked to "update my ArtRichards skills", run
`~/opt/personal-skill-marketplace/update-skills.sh` and tell the operator to
restart the agent.

**Bootstrapping a new host:** `git clone git@github.com:ArtRichards/system-docs.git ~/system-docs`,
then `git checkout -b $(hostname) main`, fill the templates with a first
inventory, add the hostname to the branch list in `README.md` on `main`
(separate commit on `main`), and `git push -u origin $(hostname)`.

## When to run

Run this skill at the end of a turn if **any** of these are true:

- A system-level service was added/removed/reconfigured (docker compose service touching the host, systemd unit, samba share, network mount).
- A disk, partition, or ZFS pool/dataset changed (added, removed, resilvered, renamed, capacity shift past a meaningful threshold).
- Hardware state changed or was newly observed (GPU/driver, NIC, sensors, SMART status).
- A scoped-sudo grant, apt repo, or other host-wide install/uninstall happened.
- A persistent quirk was discovered worth recording (e.g., "Docker Hub `latest` tag is stale", "this kernel build hangs on suspend").
- A planned migration step was completed or its status changed (e.g., a numbered plan in the host's recovery docs).
- A new system plan/spec/runbook was authored, or an existing one was completed or superseded.

Do **not** run for:

- Pure application code edits, refactors, PR review, business-logic debugging.
- Transient state (uptime, queue depth, log volume, current memory use).
- Anything already captured in `git log` of a project repo and not interesting at the system level.

If unsure, run it — but keep edits minimal. A no-op pass is cheaper than a lost fact.

## Workflow

1. **Read the current status file** — `~/system-docs/system-status.md`. It is authoritative; do not duplicate facts that already exist.
2. **List the candidate updates** in your head from this turn's work: additions, modifications, removals. For each, decide which section it belongs in.
3. **Edit minimally** with `Edit`/`Read` — never `Write` (no full-file rewrites; that risks clobbering existing facts).
4. **Handle plan lifecycle** (see next section) — relocate any plan authored elsewhere this turn into `~/system-docs/`, and archive any plan completed this turn.
5. **Refresh `INDEX.md`** (see "Index" section) — every doc in `~/system-docs/` (active + archived) must have exactly one entry; remove entries whose files no longer exist, add entries for new files, and correct any drifted descriptions.
6. **Bump the `_Last updated:`** header line in `system-status.md` to today's date plus a one-line hint of what changed.
7. **Commit and push to the host branch.** Re-check
   `git -C ~/system-docs branch --show-current` equals the hostname, then run
   `git -C ~/system-docs add -A && git -C ~/system-docs commit -m "<hostname>: <one-line summary of this pass>" && git -C ~/system-docs push`.
   The branch tracks `origin/<hostname>`, so a plain `push` is correct. Never
   push to `main`, never change the remote's visibility, and never push the
   docs anywhere public — they contain host hardware, service and sudo-policy
   details.

## Plan lifecycle

`~/system-docs/` is the **only** correct location for system plans, specs, and
runbooks. Enforce that on every pass:

- **New plans:** if this turn authored a plan/spec about the host (migration,
  recovery, redundancy, sudo policy, samba layout, hardware swap, etc.) and it
  landed anywhere other than `~/system-docs/`, move it there now and update
  every reference (`~/CLAUDE.md`, `system-status.md`, other plans).
- **Completed plans:** if a plan is finished or superseded, move the file to
  `~/system-docs/archive/YYYY-MM-DD/` using the completion date. Create the
  dated directory if needed (`mkdir -p`). Then update references in
  `~/CLAUDE.md`, `system-status.md`, and any other plan that points at it.
  Keep the top of `~/system-docs/` limited to in-flight work.
- **Partial completion:** if only one sub-plan inside a multi-part document is
  done (e.g., Plan 1 of a redundancy+recovery doc), do **not** archive yet —
  note the completion inline and archive once the whole document is done.

`~/system-docs/` is a git checkout, so use `git mv` for relocations and
archiving so history follows the file.

## Index

`~/system-docs/INDEX.md` is the at-a-glance map of everything in the directory.
It is the **first place to look** before starting system maintenance — it
should answer "what plans/specs exist, which are active, which are archived"
without having to `ls`.

Conventions:

- Two top-level sections: **Active** (files in `~/system-docs/` itself) and
  **Archive** (everything under `~/system-docs/archive/<date>/`).
- One bullet per file: `- [filename](filename) — one-line description.`
- Archive bullets prefix with the dated subdirectory:
  `- [archive/2026-05-20/foo.md](archive/2026-05-20/foo.md) — …`
- `system-status.md` is always listed first under Active.
- Keep descriptions short (≤ ~80 chars) and accurate to the file's current
  contents, not its original purpose.
- No prose paragraphs, no nested sections per doc — this is an index, not a
  wiki.

Refresh rule: every pass that touched a file in `~/system-docs/` (created,
moved, archived, or materially rewrote it) must update INDEX.md in the same
pass. If unsure whether a description still fits, re-read the doc's first
section and rewrite the one-liner.

`ls ~/system-docs/ ~/system-docs/archive/*/ 2>/dev/null` is the ground truth —
INDEX.md entries that don't have a corresponding file are stale and must be
removed.

## Placing the fact

Read the existing sections first and put the fact in the closest match. The current section list is **illustrative, not canonical** — it can grow, shrink, or be reshaped as the system changes. Don't force a fact into a section that doesn't really fit just to avoid creating a new one, and don't preserve a stale section once it's empty.

Sections that have existed in the past include things like storage / disks / hardware / services / samba / local scripts / quirks / open items — useful as orientation for the kind of fact-bucket this file uses, not as a closed taxonomy.

Two soft preferences when deciding placement:

- **Gotchas / traps** are easier to find when they live in their own bucket rather than buried inside the affected service's bullet.
- **In-flight migrations and deferred fixes** group well together rather than sprawling into new top-level sections each.

When adding a new section, match the existing style — short `##` header, bullet list, tables for inventories, no prose paragraphs.

## Entry style

- **Concise.** One- or two-line bullets. Tables for inventories.
- **Date inline** when state has a "since when" or "until when" meaning: `"...stopped+disabled 2026-05-20; revert with sudo systemctl ..."`.
- **Include the revert.** If you record a change, record how to undo it.
- **Name the gotcha.** When a quirk is what bit you, write it so the next person doesn't get bitten: not "ollama:latest works" but "ollama:latest is stale at 0.13.3; pin a specific tag".
- **Link to scripts/plans** by absolute path. Don't restate their contents.

## Deduplication

Before adding a new bullet, grep the file for the key term. If a related entry exists:

- **Refine in place** when the new fact extends/corrects the old one (preferred).
- **Replace** when the old entry is now wrong (don't leave stale claims; they are worse than missing).
- **Append a new bullet** only when the fact is genuinely separate.

Never paste a paragraph that repeats a prior bullet — that is the most common failure mode of this file.

## `Last updated` line

Format: `_Last updated: YYYY-MM-DD — short hint of the change._`

The hint should name the most consequential item, not list every edit. If multiple things changed in one turn, pick the headline:

- Good: `_Last updated: 2026-05-20 — ollama dockerized; paperless lineup refreshed._`
- Bad: `_Last updated: 2026-05-20 — edited services, hardware, quirks, and lineup._`

## Quick sanity check before finishing

- Did the diff add a date where one was needed?
- Is the revert path captured for anything reversible?
- Is the file still readable end-to-end (no orphan headers, no dead links)?
- Did `_Last updated:_` get bumped?
- Is the checkout on the host's own branch (not `main`), and did the push land on `origin/<hostname>`?
- Does `INDEX.md` match the current contents of `~/system-docs/` (no stale entries, no missing ones)?

If yes to all, the pass is done.
