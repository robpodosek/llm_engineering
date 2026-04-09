#!/usr/bin/env bash
# Rebase local main onto upstream/main, then push to origin (your fork).
# Run from anywhere inside the repo. Requires remote "upstream" pointing at the original repo.
#
# Usage:
#   ./scripts/sync-fork-rebase.sh
#   bash scripts/sync-fork-rebase.sh

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "Error: not inside a git repository."
  exit 1
}
cd "$ROOT"

if ! git remote get-url upstream &>/dev/null; then
  echo "No git remote named 'upstream'. Add the original repo, for example:"
  echo "  git remote add upstream https://github.com/ed-donner/llm_engineering.git"
  exit 1
fi

if ! git diff-index --quiet HEAD -- 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
  echo "Error: uncommitted or staged changes. Commit or stash them first."
  exit 1
fi

echo "Fetching upstream..."
git fetch upstream

echo "Rebasing main onto upstream/main..."
git checkout main
git rebase upstream/main

echo "Pushing to origin (your fork)..."
if git push origin main; then
  echo "Done (fast-forward push)."
else
  echo "Normal push failed (history likely rewritten by rebase). Force-pushing with lease..."
  git push origin main --force-with-lease
  echo "Done."
fi
