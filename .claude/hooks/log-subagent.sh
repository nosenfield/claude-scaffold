#!/bin/bash
# SubagentStop Hook - Progress Tracking
# Logs subagent completions with prompt/output excerpts
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
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // "unknown"')
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // "unknown"')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.agent_transcript_path // ""')
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Extract prompt and output from transcript
PROMPT=""
OUTPUT=""
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  # First line contains the prompt (user message)
  PROMPT=$(head -1 "$TRANSCRIPT" 2>/dev/null | jq -r '.message.content | if type == "array" then .[0].text else . end | .[0:100]' 2>/dev/null | tr '\n' ' ' | sed 's/  */ /g')

  # Last line contains the output (assistant message)
  OUTPUT=$(tail -1 "$TRANSCRIPT" 2>/dev/null | jq -r '.message.content | if type == "array" then .[0].text else . end | .[0:100]' 2>/dev/null | tr '\n' ' ' | sed 's/  */ /g')
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
