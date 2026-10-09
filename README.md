# ArtRichards Personal Skill Marketplace

A Claude Code plugin marketplace for personal host-maintenance and workflow
skills. Each skill ships as its own plugin so they can be installed
independently.

## Plugins

### update-system-status

Keeps a host's `~/system-docs/` directory accurate. The skill owns:

- `system-status.md` — a living, dated record of host facts (storage, disks,
  services, hardware, quirks), edited minimally and deduplicated on every pass;
- plan/spec lifecycle — system plans, specs, and runbooks live in
  `~/system-docs/` only, and completed plans move to
  `~/system-docs/archive/YYYY-MM-DD/` with all references updated;
- `INDEX.md` — a one-line-per-doc map of everything active and archived, kept
  in lockstep with the directory contents.

It is designed to trigger proactively at the end of any agent turn that touched
system state (services, ZFS pools, disks, hardware, sudo grants, samba,
networking, kernel/driver, persistent system-level configs), surfaced a new
system fact, or authored/completed a system plan.

To adopt it on a host, create `~/system-docs/` with a `system-status.md` and
point your `CLAUDE.md` at it (see the skill's SKILL.md for the conventions the
skill enforces).

### create-deb

Packages any script, application, or service as a Debian (`.deb`) package for
system-wide installation. Invoke with `/create-deb [source-path]`. Ships
reference docs (control files, maintainer scripts, common pitfalls) and
templates for `control`, `postinst`, and `postrm`. Moved here from the former
standalone [create-deb-skill](https://github.com/ArtRichards/create-deb-skill)
repository.

## Install

### On my own hosts (the convention for every ArtRichards-authored skill)

One clone per host, skills symlinked from it, updated with `git pull`:

```bash
git clone git@github.com:ArtRichards/personal-skill-marketplace.git ~/opt/personal-skill-marketplace
~/opt/personal-skill-marketplace/install-skills.sh
```

**To update everything at once** (this clone, the `agent-playbook-suite` plugin for
Claude Code and Codex, and `docs-cli`):

```bash
~/opt/personal-skill-marketplace/update-skills.sh
```

Telling Claude or Codex "update my ArtRichards skills" means: run that script, then
restart the agent so the skill index reloads.

`install-skills.sh` is idempotent. It symlinks every `plugins/<plugin>/skills/<skill>/`
into `~/.claude/skills/<skill>` (and `~/.codex/skills/<skill>` when that directory
exists), re-points stale links, and refuses to clobber a real directory. Re-run it
after adding a plugin. To pick up changes on a host:

```bash
git -C ~/opt/personal-skill-marketplace pull --ff-only
```

Do **not** also `claude plugin install` these plugins on such a host — the skills
would be listed twice. Edit skills in the clone, commit, push, then pull on the other
hosts. Hosts set up this way: `monitor`, `robbie`, `voyager`.

Skills authored by Art that live in **other** repos keep their own install path and are
not duplicated here: the agent-playbook-suite skills (`create-milestones`,
`project-foundation`, `ship-milestone`, `simplify`, `sync-and-commit`, `docs`, …) come
from the `ArtRichards/agent-playbook-suite` plugin via `claude plugin install`, and the
`docs` skill also ships inside the `docs-cli` package.

### Anywhere else (marketplace install)

For Claude Code:

```bash
claude plugin marketplace add ArtRichards/personal-skill-marketplace
claude plugin install update-system-status@personal-skill-marketplace
claude plugin install create-deb@personal-skill-marketplace
```

For Codex:

```bash
codex plugin marketplace add ArtRichards/personal-skill-marketplace --ref main
codex plugin add update-system-status@personal-skill-marketplace
codex plugin add create-deb@personal-skill-marketplace
```

## Retired plugins

- `next-task` (0.1.0, 2026-10-03) — deprecated the same day it was added; no longer
  used. History remains at tag `next-task-v0.1.0`. `install-skills.sh` prunes its
  symlinks on the next run.

## Layout

- `.claude-plugin/marketplace.json` — Claude Code marketplace manifest
- `.agents/plugins/marketplace.json` — Codex marketplace manifest
- `update-skills.sh` — one-shot updater for every ArtRichards skill source on a host
- `install-skills.sh` — symlinks all skills into `~/.claude/skills` / `~/.codex/skills`
- `plugins/<plugin>/` — one directory per plugin, each with its own
  `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`, and `skills/`
  payload

## Releasing

1. Edit the skill payload under `plugins/<plugin>/skills/`.
2. Bump the version in `plugins/<plugin>/.claude-plugin/plugin.json`,
   `plugins/<plugin>/.codex-plugin/plugin.json`, and the matching entry in
   `.claude-plugin/marketplace.json`.
3. Run the same checks as CI (`.github/workflows/validate.yml`): JSON manifests
   parse, every skill directory contains a `SKILL.md`, no nested `.git`
   directories, and `claude plugin validate .` passes.
4. Commit to `main` and add an annotated per-plugin tag
   `<plugin>-vX.Y.Z` matching the manifest version (e.g.
   `create-deb-v0.1.0`). The marketplace installs from `main`; tags are
   release markers for history and rollback. (The repo-wide `v0.1.0` tag
   predates the second plugin.)
5. Push, then run `~/opt/personal-skill-marketplace/update-skills.sh` on every
   host listed under Install.

## License

MIT
