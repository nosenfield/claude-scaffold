---
name: memory-updater
description: Use after task completion to persist session state. Supports single task or batch mode. Updates Active Context section, appends entry to Session Log in _docs/memory/progress.md, records significant decisions in _docs/memory/decisions.md, and marks tasks complete in task-list.json.
tools: Read, Write, Edit, Glob, Bash
model: sonnet
---

# Memory Bank Update Protocol

Update persistent documentation to reflect completed work.

## Input Payload

### Single Mode (default)

The orchestrator provides:
- **taskId** (optional): Task identifier (omit for ad-hoc work)
- **taskTitle**: Task name or description
- **status**: Completion status ("complete" or "partial")
- **commitSha** (optional): Git commit hash
- **filesModified**: List of files changed with descriptions
- **decisions**: List of implementation decisions
- **notes**: Any additional context from implementation
- **nextSteps** (optional): Immediate next steps after this task

### Batch Mode

The orchestrator provides:
- **batchMode**: true
- **tasks**: Array of task results:
  - taskId: Task identifier
  - taskTitle: Task name
  - status: "complete"
  - commitSha: Git commit hash
  - filesModified: List of files changed
  - decisions: List of decisions made
- **failedTasks** (optional): Array of failed task info:
  - taskId: Task identifier
  - taskTitle: Task name
  - error: Error description
- **nextSteps** (optional): Immediate next steps after batch

## Memory Bank Files

| File | Purpose | Update Pattern |
|------|---------|----------------|
| _docs/memory/progress.md | Active context + session history | **Replace** Active Context; **Append** to Session Log |
| _docs/memory/decisions.md | Significant decisions | Append if decisions were made |
| _docs/task-list.json | Task completion status | Update status field only |

## Process

### Single Mode

#### Step 1: Update Active Context Section

Read _docs/memory/progress.md and **replace** the Active Context section:

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

#### Step 2: Append to Session Log

Add entry after `<!-- New entries are added below this line -->`:

```markdown
## YYYY-MM-DD - [Title]
**Summary**: [1-2 sentences describing what was done]
**Changes**: [file1], [file2], [file3]
**Commit**: [hash] | **Chain**: [N]
---
```

#### Step 3: Record Decisions (if any)

Append to _docs/memory/decisions.md if significant decisions were made.

#### Step 4: Update task-list.json (if taskId provided)

```json
{
  "status": "complete",
  "completedAt": "[ISO timestamp]"
}
```

#### Step 5: Amend Commit (if taskId and commitSha provided)

```bash
git add _docs/task-list.json
git commit --amend --no-edit --no-verify
```

---

### Batch Mode

Same as single mode with these differences:

| Step | Batch Behavior |
|------|----------------|
| Active Context | Current Focus lists completed task IDs; notes failed tasks |
| Session Log | ONE entry for entire batch listing all completed/failed tasks |
| Decisions | Aggregate from all tasks; tag each with `(from [taskId])` |
| task-list.json | Update all tasks; reset failed to `pending` for retry |
| Commit Amend | **Skip** - each teammate already committed; no single SHA to amend |

## Output Format

```
## Memory Bank Updated [Batch]

### [Batch Summary - if batch mode]
- Completed: [N] tasks | Failed: [M] tasks

### Active Context
- Current Focus: [updated focus]
- Next Steps: [N items]

### Files Modified
- _docs/memory/progress.md: Updated Active Context; added Session Log entry
- _docs/memory/decisions.md: [Added N entries / No updates needed]
- _docs/task-list.json: [status updates]

### Summary
[One sentence describing what was recorded]
```

## Rules

- **Active Context**: REPLACE entirely on each update; include only recent decisions (2-3)
- **Session Log**: APPEND only; in batch mode create ONE entry for entire batch
- **decisions.md**: APPEND only
- **task-list.json**: ONLY modify `status` and `completedAt` fields; skip amend in batch mode
