#!/usr/bin/env bash
# Update every ArtRichards-authored skill on this host, from all three sources:
#   1. this clone (personal skills, symlinked by install-skills.sh)
#   2. the agent-playbook-suite plugin (Claude Code and Codex, whichever is installed)
#   3. the docs-cli pip package the suite depends on (only if already installed)
# Safe to re-run. Say "update my ArtRichards skills" to an agent and it runs this.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$HOME/.local/bin:$PATH"   # pipx / npm-global installs (docs, codex, claude) even over non-login ssh
step() { printf '\n== %s\n' "$*"; }

step "personal-skill-marketplace: pull + relink"
if git -C "$REPO" diff --quiet && git -C "$REPO" diff --cached --quiet; then
  git -C "$REPO" pull --ff-only || echo "!! pull failed (offline or diverged); continuing with local copy"
else
  echo "!! uncommitted changes in $REPO; skipping pull. Commit/push them, then re-run."
fi
"$REPO/install-skills.sh"

if command -v claude >/dev/null 2>&1; then
  if claude plugin list 2>/dev/null | grep -q "agent-playbook-suite@agent-playbook-suite"; then
    step "Claude Code: agent-playbook-suite"
    claude plugin marketplace update agent-playbook-suite || true
    claude plugin update agent-playbook-suite@agent-playbook-suite || true
  else
    echo "-- Claude Code: agent-playbook-suite not installed here; skipping"
  fi
fi

if command -v codex >/dev/null 2>&1; then
  if codex plugin list 2>&1 | grep -q "agent-playbook-suite@agent-playbook-suite"; then
    step "Codex: agent-playbook-suite marketplace"
    codex plugin marketplace upgrade agent-playbook-suite || true
    echo "   (if Codex keeps the old copy: codex plugin remove agent-playbook-suite@agent-playbook-suite && codex plugin add agent-playbook-suite@agent-playbook-suite)"
  else
    echo "-- Codex: agent-playbook-suite not installed here; skipping"
  fi
fi

if command -v pipx >/dev/null 2>&1 && pipx list 2>/dev/null | grep -q "package docs-cli"; then
  step "docs-cli (pipx)"
  pipx upgrade docs-cli; docs --version
elif python3 -m pip show docs-cli >/dev/null 2>&1; then
  step "docs-cli (pip)"
  python3 -m pip install --quiet --upgrade docs-cli && docs --version
else
  echo "-- docs-cli not installed here; skipping"
fi

step "done — restart Claude Code / Codex so the skill index reloads"
