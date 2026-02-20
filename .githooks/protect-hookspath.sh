#!/bin/bash
# Protect core.hooksPath from being hijacked by Husky, lefthook, or similar tools.
#
# Wire into package.json:
#   "postprepare": "./.githooks/protect-hookspath.sh"
#
# npm lifecycle order: postinstall -> prepare -> postprepare
# Husky installs at "prepare", so "postprepare" always runs last and wins.

EXPECTED=".githooks"
CURRENT=$(git config core.hooksPath 2>/dev/null)

if [ "$CURRENT" != "$EXPECTED" ]; then
  git config core.hooksPath "$EXPECTED"
  echo "[protect-hookspath] Corrected core.hooksPath: '${CURRENT:-<unset>}' -> '$EXPECTED'"
fi
