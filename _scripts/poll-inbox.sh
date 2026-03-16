#!/bin/bash
# poll-inbox.sh - Poll Agent Teams inbox for teammate results
#
# Usage: _scripts/poll-inbox.sh <team-name> <expected-count> [max-wait-seconds]
#
# Polls the team-lead inbox every 30 seconds until <expected-count>
# TASK_COMPLETE or TASK_FAILED messages arrive, then prints all results.
#
# Optional max-wait-seconds (default: 1200 = 20 minutes). On timeout,
# exits with code 1 so the caller can mark remaining tasks as failed.
#
# IMPORTANT: The caller must clear the inbox between batches to avoid
# counting stale messages from prior batches. See execute-one-wave.md
# Phase 3e for the purge step.
#
# NOTE: Depends on Agent Teams internal inbox path (~/.claude/teams/<name>/inboxes/).
# This path is not part of a public API and may change in future Claude Code versions.

set -euo pipefail

TEAM_NAME="${1:?Usage: poll-inbox.sh <team-name> <expected-count> [max-wait-seconds]}"
EXPECTED="${2:?Usage: poll-inbox.sh <team-name> <expected-count> [max-wait-seconds]}"
MAX_WAIT="${3:-1200}"
INBOX=~/.claude/teams/"$TEAM_NAME"/inboxes/team-lead.json
ELAPSED=0
INTERVAL=30

# Phase 1: Wait for all teammates to report
while true; do
  sleep "$INTERVAL"
  ELAPSED=$((ELAPSED + INTERVAL))
  DONE=$(python3 -c "
import json, sys
try:
    with open('$INBOX') as f:
        msgs = json.load(f)
    completed = [m for m in msgs if 'TASK_COMPLETE' in m.get('text','') or 'TASK_FAILED' in m.get('text','')]
    print(len(completed))
except (FileNotFoundError, json.JSONDecodeError):
    print(0)
  ")
  echo "[$(date +%H:%M:%S)] $DONE of $EXPECTED teammates reported (${ELAPSED}s elapsed)"
  if [ "$DONE" -ge "$EXPECTED" ]; then
    echo "All teammates reported. Collecting results."
    break
  fi
  if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
    echo "TIMEOUT: ${ELAPSED}s elapsed, only $DONE of $EXPECTED teammates reported."
    exit 1
  fi
done

# Phase 2: Extract and print results
python3 -c "
import json
with open('$INBOX') as f:
    msgs = json.load(f)
for m in msgs:
    if 'TASK_COMPLETE' in m.get('text','') or 'TASK_FAILED' in m.get('text',''):
        print(f'--- {m[\"from\"]} ({m[\"summary\"]}) ---')
        print(m['text'])
        print()
"
