#!/usr/bin/env bash
# Link every skill in this clone into ~/.claude/skills (and ~/.codex/skills if present).
# Convention for ArtRichards-authored skills: one clone at ~/opt/personal-skill-marketplace
# per host, skills symlinked from it, updates via `git pull`. Do NOT also install the
# same plugins through `claude plugin install` on that host — the skills would appear twice.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
link_into() {
  local target_dir="$1"
  [ -d "$target_dir" ] || return 0
  for skill in "$REPO"/plugins/*/skills/*/; do
    skill="${skill%/}"
    [ -f "$skill/SKILL.md" ] || continue
    name="$(basename "$skill")"
    dest="$target_dir/$name"
    if [ -L "$dest" ]; then
      [ "$(readlink -f "$dest")" = "$skill" ] && { echo "ok      $dest"; continue; }
      ln -sfn "$skill" "$dest"; echo "relink  $dest"
    elif [ -e "$dest" ]; then
      echo "SKIP    $dest exists and is not a symlink; remove it by hand to adopt the clone" >&2
    else
      ln -s "$skill" "$dest"; echo "link    $dest -> $skill"
    fi
  done
}
link_into "$HOME/.claude/skills"
link_into "$HOME/.codex/skills"
