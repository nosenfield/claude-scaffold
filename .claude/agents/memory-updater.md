---
name: memory-updater
description: Use after task completion to persist session state. Requires taskId, status, commitSha, filesModified, and decisions in payload. Updates Active Context section, appends entry to Session Log in _docs/memory/progress.md, records significant decisions in _docs/memory/decisions.md, and marks task complete in task-list.json.
tools: Read, Write, Edit, Glob
model: sonnet
---

# Memory Bank Update Protocol

Update persistent documentation to reflect completed work.

## Input Payload

The orchestrator provides:
- **taskId** (optional): Task identifier (omit for ad-hoc work)
- **taskTitle**: Task name or description
- **status**: Completion status ("complete" or "partial")
- **commitSha** (optional): Git commit hash
- **filesModified**: List of files changed with descriptions
- **decisions**: List of implementation decisions, each containing:
  - decision: What was decided
  - rationale: Why this choice was made
- **notes**: Any additional context from implementation
- **nextSteps** (optional): Immediate next steps after this task

Access via the prompt context. Do not assume information not provided.

## Memory Bank Files

| File | Purpose | Update Pattern |
|------|---------|----------------|
| _docs/memory/progress.md | Active context + session history | **Replace** Active Context section; **Append** to Session Log |
| _docs/memory/decisions.md | Significant implementation decisions | Append if decisions were made |
| _docs/task-list.json | Task completion status | Update status field only (if taskId provided) |

## Process

### Step 1: Update Active Context Section

Read _docs/memory/progress.md and **replace** the Active Context section (between `## Active Context` and `## Session Log`) with current state:

```markdown
## Active Context

**Last Updated**: [YYYY-MM-DD]

### Current Focus
- [What was just completed]
- [What's being worked on next, if known]

### Current Task
[Next task from nextSteps, or "None" if work stream complete]

### Recent Decisions
- [Most recent decision from this task]
- [Previous decision, if relevant]

### Immediate Next Steps
1. [From nextSteps payload, or inferred]
2. [...]

---
```

### Step 2: Append to Session Log

Add new entry **after** the `<!-- New entries are added below this line -->` marker:

```markdown
## [YYYY-MM-DD HH:MM] - Task [ID]: [Title]

**Status**: Complete

**Changes**:
- [file path]: [what changed]
- [file path]: [what changed]

**Outcome**: [one-sentence summary]

---
```

### Step 3: Record Decisions (if any)

If significant decisions were made:
- Read current _docs/memory/decisions.md
- Append decision record

### Step 4: Update task-list.json (if taskId provided)

Only modify these fields:
```json
{
  "status": "complete",
  "completedAt": "[ISO timestamp]"
}
```

## Active Context Format

```markdown
## Active Context

**Last Updated**: [YYYY-MM-DD]

### Current Focus
- [Primary work stream or topic]
- [Secondary focus if applicable]

### Current Task
[Task ID and title, or "None" if between tasks]

### Recent Decisions
- [Decision 1]: [Brief rationale]
- [Decision 2]: [Brief rationale]

### Immediate Next Steps
1. [Specific actionable step]
2. [Next step]
3. [Following step]

---
```

## Session Log Entry Format

```markdown
## [YYYY-MM-DD HH:MM] - Task [ID]: [Title]

**Status**: Complete

**Changes**:
- [file path]: [what changed]
- [file path]: [what changed]

**Outcome**: [one-sentence summary]

---
```

## Decision Entry Format

```markdown
## [YYYY-MM-DD] - [Decision Title]

**Context**: [why decision was needed]

**Decision**: [what was decided]

**Alternatives Considered**:
- [option]: [why rejected]

**Consequences**: [implications of this decision]

---
```

## Task Status Update

Only modify these fields in task-list.json:
```json
{
  "status": "complete",
  "completedAt": "[ISO timestamp]"
}
```

## Output Format

```
## Memory Bank Updated

### Active Context
- Current Focus: [updated focus]
- Next Steps: [N items]

### Files Modified
- _docs/memory/progress.md: Updated Active Context; added Session Log entry for [task]
- _docs/memory/decisions.md: [Added N entries / No updates needed]
- _docs/task-list.json: [Marked task [ID] complete / Not updated (ad-hoc work)]

### Summary
[One sentence describing what was recorded]
```

## Rules

### Active Context Section
- **REPLACE** the entire Active Context section on each update
- Keep it current—this is what /dev reads at session start
- Include only recent/relevant decisions (last 2-3)
- Next steps should be specific and actionable

### Session Log Section
- **APPEND** new entries; never overwrite existing entries
- New entries go immediately after the marker comment
- Keep entries concise and factual

### _docs/memory/decisions.md
- **APPEND** only; never overwrite existing entries

### task-list.json
- ONLY modify status and completedAt fields
- Skip if no taskId provided (ad-hoc work)
- Never modify task descriptions, priorities, or acceptance criteria
