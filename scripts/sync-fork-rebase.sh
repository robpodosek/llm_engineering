#!/usr/bin/env bash
# Generic Synchronizer for forked repositories.
# Detects the default branch and rebases onto upstream.

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "Error: not inside a git repository."
  exit 1
}
cd "$ROOT"

# 1. Detect Default Branch
MAIN_BRANCH=$(git remote show origin 2>/dev/null | grep "HEAD branch" | cut -d: -f2 | xargs)
if [ -z "$MAIN_BRANCH" ]; then
    MAIN_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
    echo "Note: Remote branch detection skipped or failed. Using current branch: $MAIN_BRANCH"
fi

# 2. Verify Upstream
if ! git remote get-url upstream &>/dev/null; then
  echo "Error: No git remote named 'upstream' found."
  echo "To sync a fork, you must add the original repository as a remote named 'upstream'."
  echo "Example: git remote add upstream https://github.com/ed-donner/llm_engineering.git"
  exit 1
fi

# 3. Check for Local Changes
if ! git diff-index --quiet HEAD -- 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
  echo "Error: uncommitted or staged changes. Please commit or stash them before syncing."
  exit 1
fi

echo "--- Fork Sync Start (Branch: $MAIN_BRANCH) ---"

echo "1. Fetching upstream updates..."
git fetch upstream

# Ensure we are on the main branch
CURRENT_BRANCH=$(git symbolic-ref --short HEAD)
if [ "$CURRENT_BRANCH" != "$MAIN_BRANCH" ]; then
    echo "2. Switching to $MAIN_BRANCH..."
    git checkout "$MAIN_BRANCH"
fi

echo "3. Rebasing $MAIN_BRANCH onto upstream/$MAIN_BRANCH..."
if git rebase "upstream/$MAIN_BRANCH"; then
    echo "4. Updating your fork (origin $MAIN_BRANCH)..."
    if git push origin "$MAIN_BRANCH"; then
        echo "Success: Sync complete (fast-forward)."
    else
        echo "Push failed. Force-pushing with lease (safe overwrite)..."
        git push origin "$MAIN_BRANCH" --force-with-lease
        echo "Success: Sync complete."
    fi
else
    echo "Error: Rebase failed due to conflicts."
    echo "Please resolve conflicts manually, then run 'git rebase --continue'."
    exit 1
fi

echo "--- Fork Sync Finished ---"
