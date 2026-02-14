---
name: task-selector
description: Use when /next-from-task-list or /next-batch-from-list is invoked. Reads task-list.json and selects tasks. Single mode returns one task and marks it in-progress. Batch mode returns all parallelizable tasks from waveSummary without marking in-progress. Uses haiku for fast, deterministic selection logic.
tools: Read, Edit
model: haiku
---

# Task Selection Protocol

Analyze the task list and select tasks based on mode.

## Input

The orchestrator provides:
```
mode: single | batch
```

If no mode specified, default to `single`.

## Process

### 1. Load Task List

Read `_docs/task-list.json`.

Verify schema version:
- Version 2.x: Use wave-based selection (this protocol)
- Version 1.x: Fall back to legacy selection (compute dependencies at runtime)

### 2. Handle Edge Cases

**If no tasks exist**:
```
NO_PENDING_TASKS
completedCount: 0
totalCount: 0
```

**If all tasks complete**:
```
NO_PENDING_TASKS
completedCount: [N]
totalCount: [N]
```

**If all non-complete tasks are blocked**:
```
ALL_TASKS_BLOCKED
blockedTasks:
  - id: [taskId]
    title: [title]
    blockedBy: [list of blocking task IDs]
```

### 3. Select Based on Mode

#### Single Mode (default)

1. Filter tasks where `status === "ready"`
2. Sort by `priority` (lower number = higher priority)
3. Select the first task

**Update Task Status**:
Edit `_docs/task-list.json`:
- Set `status: "in-progress"`

**Return**:
```
TASK_SELECTED
id: [task.id]
title: [task.title]
priority: [task.priority]
executionWave: [task.executionWave]
description: [task.description]
acceptanceCriteria:
  - [criterion 1]
  - [criterion 2]
references:
  - [doc path 1]
  - [doc path 2]
filesTouched:
  - [path 1]
  - [path 2]
blockedBy: [list or empty]
```

#### Batch Mode

1. Determine current wave:
   ```
   currentWave = min(executionWave) among tasks where status !== "complete"
   ```

2. Filter candidates:
   ```
   candidates = tasks where executionWave === currentWave AND status === "ready"
   ```

3. Sort by `priority` (lower number = higher priority)

4. Read `waveSummary[currentWave].contentions`

5. Build batch avoiding contentions:

```
batch = []
usedFiles = Set()  # Defense in depth within wave

for each candidate (priority order):
    # Check waveSummary contentions
    if task is in waveSummary[currentWave].contentions with any batch member:
        skip

    # Check file overlap (defense in depth - catches unlisted contentions)
    if intersection(task.filesTouched, usedFiles) is not empty:
        skip

    # Check concurrency limit
    if batch.size >= metadata.maxConcurrency:
        break

    add task to batch
    add task.filesTouched to usedFiles
```

Do NOT update task status (orchestrator handles after spawning).

**Return**:
```
BATCH_SELECTED
batchSize: [N]
tasks:
  - id: TASK-003
    title: Add auth middleware
    priority: 1
    executionWave: [wave]
    description: [description]
    acceptanceCriteria:
      - [criterion 1]
    references:
      - [doc path]
    filesTouched:
      - src/middleware/auth.ts
      - src/types/auth.ts
  - id: TASK-005
    title: Create user model
    priority: 2
    executionWave: [wave]
    description: [description]
    acceptanceCriteria:
      - [criterion 1]
    references:
      - [doc path]
    filesTouched:
      - src/models/user.ts
      - src/types/user.ts
remainingTasks: [count of ready tasks not in batch]
contentionsAvoided:
  - [TASK-003, TASK-007]: src/routes/index.ts
warnings:
  - [any tasks with empty filesTouched]
```

### 4. Legacy Mode (Version 1.x)

If `metadata.version` starts with "1.":

**Single Mode**:
- Filter `status === "pending"`
- Check all `blockedBy` tasks have `status === "complete"`
- Select highest priority unblocked task
- Set status to `in-progress`

**Batch Mode**:
- Filter pending + unblocked tasks
- Greedy grouping by `affectedPaths` (legacy field name)
- Return batch without status update

## Output

| Result | When | Status Update |
|--------|------|---------------|
| `TASK_SELECTED` | Single mode, task available | Yes |
| `BATCH_SELECTED` | Batch mode, tasks available | No |
| `NO_PENDING_TASKS` | All complete | No |
| `ALL_TASKS_BLOCKED` | All non-complete blocked | No |

## Rules

- In single mode: modify only `status` field
- In batch mode: do NOT modify any fields
- Return complete task objects for orchestrator
- Report contentions avoided in batch mode
- Warn about tasks missing `filesTouched`
