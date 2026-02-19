#!/bin/bash
# Git Commit Lock
# Prevents overlapping git stage+commit operations in batch execution.
#
# Uses mkdir-based atomic locking (portable, POSIX-compliant).
# Modeled after the agent-specific marker pattern in .claude/hooks/test-file-guard.sh.
#
# Usage:
#   _scripts/git-commit-lock.sh acquire <agent-id> <task-id>
#   _scripts/git-commit-lock.sh release
#   _scripts/git-commit-lock.sh status
#   _scripts/git-commit-lock.sh force-release
#
# Exit codes:
#   0 = success
#   1 = failure (timeout, missing args)

set -o pipefail

LOCK_DIR=".claude/.git-commit-lock.d"
MAX_WAIT=120         # seconds before timeout
POLL_INTERVAL=2      # seconds between acquire attempts
STALE_THRESHOLD=300  # seconds before lock considered stale (5 min)

acquire() {
    local agent_id="${1:?acquire requires agent-id}"
    local task_id="${2:?acquire requires task-id}"
    local waited=0

    while true; do
        if mkdir "$LOCK_DIR" 2>/dev/null; then
            local now
            now=$(date +%s)
            cat > "$LOCK_DIR/owner.json" <<EOF
{"agentId":"${agent_id}","taskId":"${task_id}","acquiredAt":${now}}
EOF
            echo "LOCK_ACQUIRED agentId=${agent_id} taskId=${task_id}"
            return 0
        fi

        # Check for stale lock
        if [ -f "$LOCK_DIR/owner.json" ]; then
            local acquired_at
            acquired_at=$(python3 -c "import json; print(json.load(open('${LOCK_DIR}/owner.json'))['acquiredAt'])" 2>/dev/null || echo "")
            if [ -n "$acquired_at" ]; then
                local now
                now=$(date +%s)
                local age=$((now - acquired_at))
                if [ "$age" -gt "$STALE_THRESHOLD" ]; then
                    echo "STALE_LOCK_DETECTED age=${age}s owner=$(cat "$LOCK_DIR/owner.json" 2>/dev/null). Breaking lock."
                    rm -rf "$LOCK_DIR"
                    continue
                fi
            fi
        fi

        if [ "$waited" -ge "$MAX_WAIT" ]; then
            echo "LOCK_TIMEOUT after ${MAX_WAIT}s. Current owner: $(cat "$LOCK_DIR/owner.json" 2>/dev/null)"
            return 1
        fi

        sleep "$POLL_INTERVAL"
        waited=$((waited + POLL_INTERVAL))
    done
}

release() {
    if [ -d "$LOCK_DIR" ]; then
        rm -rf "$LOCK_DIR"
        echo "LOCK_RELEASED"
    else
        echo "NO_LOCK_HELD"
    fi
    return 0
}

status() {
    if [ -d "$LOCK_DIR" ]; then
        echo "LOCKED"
        cat "$LOCK_DIR/owner.json" 2>/dev/null
    else
        echo "UNLOCKED"
    fi
    return 0
}

force_release() {
    rm -rf "$LOCK_DIR"
    echo "LOCK_FORCE_RELEASED"
    return 0
}

# Main dispatch
case "${1:-}" in
    acquire)
        acquire "$2" "$3"
        ;;
    release)
        release
        ;;
    status)
        status
        ;;
    force-release)
        force_release
        ;;
    *)
        echo "Usage: $0 {acquire <agent-id> <task-id>|release|status|force-release}"
        exit 1
        ;;
esac
