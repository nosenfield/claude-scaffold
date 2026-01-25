#!/bin/bash
# pre-commit-check.sh
# Strict hook: runs on Stop event, blocks if quality gates fail
# Ensures clean state before session ends or commit

set -e

echo "Running pre-commit quality checks..."

# Run tests
if ! npm run test --silent 2>/dev/null; then
  echo "ERROR: Tests failing. Fix before commit." >&2
  exit 2
fi

# Run linter
if ! npm run lint --silent 2>/dev/null; then
  echo "ERROR: Lint errors found. Fix before commit." >&2
  exit 2
fi

# Run type check
if ! npm run typecheck --silent 2>/dev/null; then
  echo "ERROR: Type errors found. Fix before commit." >&2
  exit 2
fi

echo "All quality checks passed."
exit 0
