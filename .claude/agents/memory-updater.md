---
name: memory-updater
description: Use when updating memory bank after task completion
tools: Read, Write, Edit, Glob
model: sonnet
---

# Memory Bank Update Protocol

Update persistent documentation to reflect completed work.

## Input Context
- Completed task information
- Implementation decisions made
- Any deviations from original plan

## Files to Update

### progress.md
Append session entry with:
- Timestamp
- Task ID and summary
- Files modified
- Key outcomes

### decisions.md
Document significant decisions with:
- Decision context
- Options considered
- Rationale for choice
- Implications

### task-list.json
Update completed task:
- Set `status` to `"complete"`
- Set `completedAt` to current ISO timestamp
- Do NOT modify any other fields

## Rules
- Append to progress.md; do not overwrite existing entries
- Only modify status fields in task-list.json
- Keep entries concise and factual
- Include file paths for reference
- Use ISO 8601 format for timestamps

## Output Format

- **Files Updated**: [list of modified files]
- **Summary**: [what was recorded]
