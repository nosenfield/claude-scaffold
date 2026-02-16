#!/bin/bash
# Agent Event Hook - Progress Tracking
# Handles SubagentStop, TeammateIdle, and TaskCompleted events.
# Logs agent/teammate activity with event-specific fields.
#
# Known limitation: agent_type field is documented but not provided by Claude Code
# as of v2.1.25. Workaround: extract from agentId pattern if available.
#
# Exit codes:
#   0 = success (allow event to proceed)
#   2 = blocking error (prevent event from completing)

set -o pipefail

# Get project root from environment or current directory
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
LOG_FILE="$PROJECT_DIR/.claude/subagent.log"

# Read hook input from stdin
INPUT=$(cat)

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Detect event type by checking which fields are present.
# - SubagentStop: has agent_id, agent_transcript_path
# - TeammateIdle: has teammate_name, team_name (no agent_id)
# - TaskCompleted: has task_id, task_subject, teammate_name (no agent_id)
HAS_AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // empty')
HAS_TASK_ID=$(echo "$INPUT" | jq -r '.task_id // empty')
HAS_TEAMMATE=$(echo "$INPUT" | jq -r '.teammate_name // empty')

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

if [ -n "$HAS_TASK_ID" ]; then
  # TaskCompleted event
  TASK_ID=$(echo "$INPUT" | jq -r '.task_id // "unknown"')
  TASK_SUBJECT=$(echo "$INPUT" | jq -r '.task_subject // "unknown"')
  TEAMMATE=$(echo "$INPUT" | jq -r '.teammate_name // "unknown"')
  {
    echo "---"
    echo "timestamp: $TIMESTAMP"
    echo "event: TaskCompleted"
    echo "task: $TASK_ID"
    echo "subject: $TASK_SUBJECT"
    echo "teammate: $TEAMMATE"
  } >> "$LOG_FILE"

elif [ -n "$HAS_TEAMMATE" ] && [ -z "$HAS_AGENT_ID" ]; then
  # TeammateIdle event
  TEAMMATE=$(echo "$INPUT" | jq -r '.teammate_name // "unknown"')
  TEAM=$(echo "$INPUT" | jq -r '.team_name // "unknown"')
  {
    echo "---"
    echo "timestamp: $TIMESTAMP"
    echo "event: TeammateIdle"
    echo "teammate: $TEAMMATE"
    echo "team: $TEAM"
  } >> "$LOG_FILE"

else
  # SubagentStop event (default)
  AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // "unknown"')
  TRANSCRIPT=$(echo "$INPUT" | jq -r '.agent_transcript_path // ""')

  # Extract agent type
  AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // empty')
  if [ -z "$AGENT_TYPE" ] && [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
    TRANSCRIPT_AGENT_ID=$(jq -rs '.[0].agentId // ""' "$TRANSCRIPT" 2>/dev/null)
    AGENT_TYPE=$(echo "$TRANSCRIPT_AGENT_ID" | sed -n 's/^a\([a-z_]*\)-[a-f0-9]*$/\1/p')
  fi
  AGENT_TYPE="${AGENT_TYPE:-unknown}"

  # Extract prompt and output from transcript
  PROMPT=""
  OUTPUT=""
  if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
    PROMPT=$(jq -rs '[.[] | select(.type == "user")] | .[0].message.content |
      if type == "array" then
        (map(select(.type == "text")) | .[0].text // "")
      else
        (. // "")
      end
    ' "$TRANSCRIPT" 2>/dev/null | tr '\n' ' ' | sed 's/  */ /g')

    OUTPUT=$(jq -rs '[.[] | select(.type == "assistant")] | .[-1].message.content |
      if type == "array" then
        (map(select(.type == "text")) | .[0].text // "")
      else
        (. // "")
      end
    ' "$TRANSCRIPT" 2>/dev/null | tr '\n' ' ' | sed 's/  */ /g')
  fi

  {
    echo "---"
    echo "timestamp: $TIMESTAMP"
    echo "event: SubagentStop"
    echo "agent: $AGENT_TYPE"
    echo "id: $AGENT_ID"
    echo "prompt: ${PROMPT:-n/a}"
    echo "output: ${OUTPUT:-n/a}"
  } >> "$LOG_FILE"
fi

exit 0
