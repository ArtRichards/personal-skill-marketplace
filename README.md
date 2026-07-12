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

## Install

For Claude Code:

```bash
claude plugin marketplace add ArtRichards/personal-skill-marketplace
claude plugin install update-system-status@personal-skill-marketplace
```

For Codex:

```bash
codex plugin marketplace add ArtRichards/personal-skill-marketplace --ref main
codex plugin add update-system-status@personal-skill-marketplace
```

## Layout

- `.claude-plugin/marketplace.json` — Claude Code marketplace manifest
- `.agents/plugins/marketplace.json` — Codex marketplace manifest
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
4. Commit to `main` and tag `vX.Y.Z` (annotated) to match the manifest version.
   The marketplace installs from `main`; the tag is a release marker for
   history and rollback.

## License

MIT
