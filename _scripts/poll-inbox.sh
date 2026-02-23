#!/bin/bash
# poll-inbox.sh - Poll Agent Teams inbox for teammate results
#
# Usage: _scripts/poll-inbox.sh <team-name> <expected-count>
#
# Polls the team-lead inbox every 30 seconds until <expected-count>
# TASK_COMPLETE or TASK_FAILED messages arrive, then prints all results.
#
# NOTE: Depends on Agent Teams internal inbox path (~/.claude/teams/<name>/inboxes/).
# This path is not part of a public API and may change in future Claude Code versions.

set -euo pipefail

TEAM_NAME="${1:?Usage: poll-inbox.sh <team-name> <expected-count>}"
EXPECTED="${2:?Usage: poll-inbox.sh <team-name> <expected-count>}"
INBOX=~/.claude/teams/"$TEAM_NAME"/inboxes/team-lead.json

# Phase 1: Wait for all teammates to report
while true; do
  sleep 30
  DONE=$(python3 -c "
import json, sys
try:
    with open('$INBOX') as f:
        msgs = json.load(f)
    completed = [m for m in msgs if not m.get('read', True) and ('TASK_COMPLETE' in m.get('text','') or 'TASK_FAILED' in m.get('text',''))]
    print(len(completed))
except (FileNotFoundError, json.JSONDecodeError):
    print(0)
  ")
  echo "[$(date +%H:%M:%S)] $DONE of $EXPECTED teammates reported"
  if [ "$DONE" -ge "$EXPECTED" ]; then
    echo "All teammates reported. Collecting results."
    break
  fi
done

# Phase 2: Extract and print results
python3 -c "
import json
with open('$INBOX') as f:
    msgs = json.load(f)
for m in msgs:
    if not m.get('read', True) and ('TASK_COMPLETE' in m.get('text','') or 'TASK_FAILED' in m.get('text','')):
        print(f'--- {m[\"from\"]} ({m[\"summary\"]}) ---')
        print(m['text'])
        print()
"
