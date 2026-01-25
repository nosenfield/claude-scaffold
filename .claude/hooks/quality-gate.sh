#!/bin/bash
# quality-gate.sh
# Advisory hook: runs after file writes, warns but does not block
# Used with PostToolUse event for Write|Edit|MultiEdit

set -e

# Skip if no TypeScript/JavaScript files changed
CHANGED_FILES=$(git diff --name-only 2>/dev/null | grep -E '\.(ts|tsx|js|jsx)$' || true)
if [ -z "$CHANGED_FILES" ]; then
  exit 0
fi

WARNINGS=""

# Run linter (advisory)
if npm run lint --silent 2>/dev/null; then
  : # pass
else
  WARNINGS="${WARNINGS}Lint warnings detected. "
fi

# Run type check (advisory)
if npm run typecheck --silent 2>/dev/null; then
  : # pass
else
  WARNINGS="${WARNINGS}Type errors detected. "
fi

# Report warnings but don't block
if [ -n "$WARNINGS" ]; then
  echo "Advisory: ${WARNINGS}Consider fixing before commit." >&2
fi

# Always exit 0 (advisory mode)
exit 0
