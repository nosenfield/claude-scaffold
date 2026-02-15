#!/bin/bash
# Test File Guard Hook
# Runs before Write/Edit/MultiEdit operations
# Purpose: Block modifications to test files during implementation
#
# Exit codes:
#   0 = success (allow operation)
#   2 = blocking error (deny operation)
#
# This hook enforces test immutability as defined in test-protection.md.
# Test files may only be created/modified by the test-writer subagent.
#
# Batch-safe: Uses agent-specific marker files (.test-writing-mode-{agentId})
# to prevent race conditions when multiple teammates execute concurrently.
# Falls back to legacy generic marker for single-agent workflows.

set -o pipefail

# Read hook input from stdin
INPUT=$(cat)

# Extract the file path from the tool input
# The input is JSON with tool_input containing the file path
FILE_PATH=$(echo "$INPUT" | grep -oP '"file_path"\s*:\s*"\K[^"]+' 2>/dev/null || \
            echo "$INPUT" | grep -oP '"path"\s*:\s*"\K[^"]+' 2>/dev/null || \
            echo "")

# If we couldn't extract a path, allow the operation
if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Check if this is a test file
is_test_file() {
    local path="$1"
    
    # Check file extension patterns
    if [[ "$path" =~ \.(test|spec)\.(ts|tsx|js|jsx)$ ]]; then
        return 0
    fi
    
    # Check directory patterns
    if [[ "$path" =~ /__tests__/ ]] || [[ "$path" =~ /tests/ ]]; then
        return 0
    fi
    
    return 1
}

# Check if we're in test-writing mode
# This would be set by the test-writer subagent
is_test_writing_mode() {
    # Check for environment variable set by orchestrator
    if [ "${CLAUDE_TEST_WRITING_MODE:-false}" = "true" ]; then
        return 0
    fi

    # Check for agent-specific marker file (batch-safe)
    # Pattern: .test-writing-mode-{agentId} or legacy .test-writing-mode
    if ls .claude/.test-writing-mode* 1>/dev/null 2>&1; then
        # Extract agent ID from marker filename if present
        local marker_file
        marker_file=$(ls .claude/.test-writing-mode* 2>/dev/null | head -1)

        # If CLAUDE_AGENT_ID is set, verify it matches the marker
        if [ -n "${CLAUDE_AGENT_ID:-}" ] && [ -f ".claude/.test-writing-mode-${CLAUDE_AGENT_ID}" ]; then
            return 0
        fi

        # Legacy: allow any marker if no agent ID context
        if [ -z "${CLAUDE_AGENT_ID:-}" ] && [ -f "$marker_file" ]; then
            return 0
        fi
    fi

    return 1
}

# Main logic
main() {
    if is_test_file "$FILE_PATH"; then
        if is_test_writing_mode; then
            # Test writer is allowed to modify tests
            exit 0
        else
            # Block test modification during implementation
            echo '{"decision": "deny", "reason": "Test files cannot be modified during implementation. Tests define the contract - fix implementation, not tests. If test assertions are incorrect, report as blocker to orchestrator."}' 
            exit 0
        fi
    fi
    
    # Not a test file, allow operation
    exit 0
}

main
