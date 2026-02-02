#!/bin/bash
# SubagentStop Hook - Progress Tracking
# Logs subagent completions with prompt/output excerpts
#
# Known limitation: agent_type field is documented but not provided by Claude Code
# as of v2.1.25. Workaround: extract from agentId pattern if available.
#
# Exit codes:
#   0 = success (allow subagent to stop)
#   2 = blocking error (prevent subagent from stopping)

set -o pipefail

# Get project root from environment or current directory
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
LOG_FILE="$PROJECT_DIR/.claude/subagent.log"

# Read hook input from stdin
INPUT=$(cat)

# Extract fields from hook input
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // "unknown"')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.agent_transcript_path // ""')
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Extract agent type
# Note: agent_type is documented but not always provided by Claude Code (v2.1.25).
# Workaround: check transcript's agentId for embedded type pattern (e.g., "aprompt_suggestion-xxx")
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // empty')
if [ -z "$AGENT_TYPE" ] && [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  # Try to extract from transcript's agentId field (pattern: a<type>-<id> or just <id>)
  # Use sed for portable extraction (works in both bash and zsh)
  TRANSCRIPT_AGENT_ID=$(jq -rs '.[0].agentId // ""' "$TRANSCRIPT" 2>/dev/null)
  AGENT_TYPE=$(echo "$TRANSCRIPT_AGENT_ID" | sed -n 's/^a\([a-z_]*\)-[a-f0-9]*$/\1/p')
fi
AGENT_TYPE="${AGENT_TYPE:-unknown}"

# Extract prompt and output from transcript
PROMPT=""
OUTPUT=""
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  # Transcript is JSONL with multiple entry types: user, assistant, progress, etc.
  # Filter by type to get correct entries.

  # First "user" entry contains the prompt
  PROMPT=$(jq -rs '[.[] | select(.type == "user")] | .[0].message.content |
    if type == "array" then
      (map(select(.type == "text")) | .[0].text // "")
    else
      (. // "")
    end |
    .[0:100]
  ' "$TRANSCRIPT" 2>/dev/null | tr '\n' ' ' | sed 's/  */ /g')

  # Last "assistant" entry contains the output
  OUTPUT=$(jq -rs '[.[] | select(.type == "assistant")] | .[-1].message.content |
    if type == "array" then
      (map(select(.type == "text")) | .[0].text // "")
    else
      (. // "")
    end |
    .[0:100]
  ' "$TRANSCRIPT" 2>/dev/null | tr '\n' ' ' | sed 's/  */ /g')
fi

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Append to log
{
  echo "---"
  echo "timestamp: $TIMESTAMP"
  echo "agent: $AGENT_TYPE"
  echo "id: $AGENT_ID"
  echo "prompt: ${PROMPT:-n/a}"
  echo "output: ${OUTPUT:-n/a}"
} >> "$LOG_FILE"

exit 0
