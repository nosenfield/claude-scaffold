#!/bin/bash
# Bootstrap a git worktree with project dependencies.
#
# Called by /worktree after creating a new worktree directory.
# Customize this script for your project's dependency manager and build tools.
#
# Usage: bootstrap-worktree.sh <worktree-path>
#
# The script runs from the main tree root. All paths inside the worktree
# should use $WORKTREE_PATH as the base.

set -e

WORKTREE_PATH="${1:?Usage: bootstrap-worktree.sh <worktree-path>}"

# Node.js
if [ -f "$WORKTREE_PATH/package.json" ]; then
  echo "Installing Node dependencies..."
  (cd "$WORKTREE_PATH" && npm install --silent)
fi

# Python (virtualenv)
if [ -f "$WORKTREE_PATH/requirements.txt" ]; then
  echo "Installing Python dependencies..."
  (cd "$WORKTREE_PATH" && python3 -m venv .venv && .venv/bin/pip install -q -r requirements.txt)
fi

# Ruby (Bundler)
if [ -f "$WORKTREE_PATH/Gemfile" ]; then
  echo "Installing Ruby dependencies..."
  (cd "$WORKTREE_PATH" && bundle install --quiet)
fi

echo "Bootstrap complete: $WORKTREE_PATH"
