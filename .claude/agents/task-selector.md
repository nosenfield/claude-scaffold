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

**If all non-complete tasks are blocked** (single mode: only after wave activation attempt fails; see Single Mode step 2):
```
ALL_TASKS_BLOCKED
blockedTasks:
  - id: [taskId]
    title: [title]
    blockedBy: [list of blocking task IDs]
```

### 3. Select Based on Mode

#### Single Mode (default)

1. Filter tasks where `status === "eligible"`
2. If no eligible tasks found, attempt wave activation:
   a. Find the lowest `executionWave` among tasks where `status === "blocked"`
   b. For every task in that wave, check that all `blockedBy` task IDs have `status === "complete"`
   c. If ALL tasks in the wave pass the check, set each to `status: "eligible"`
   d. If any task's blockers are incomplete, do NOT activate (return `ALL_TASKS_BLOCKED`)
   e. Re-filter tasks where `status === "eligible"`
3. Sort by `priority` (lower number = higher priority)
4. Select the first task

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
   currentWave = min(executionWave) among tasks where status NOT IN ("complete", "failed")
   ```

2. Filter candidates:
   ```
   candidates = tasks where executionWave === currentWave AND status === "eligible"
   ```

3. If no eligible tasks found, attempt wave activation:
   a. Filter tasks where `executionWave === currentWave AND status === "blocked"`
   b. For every such task, check that all `blockedBy` task IDs have `status === "complete"`
   c. If ALL tasks in the wave pass the check, set each to `status: "eligible"`
   d. If any task's blockers are incomplete, do NOT activate (return `ALL_TASKS_BLOCKED`)
   e. Re-filter candidates where `status === "eligible"`

4. Sort by `priority` (lower number = higher priority)

5. Read `waveSummary[currentWave].contentions`

6. Build batch avoiding contentions:

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
remainingTasks: [count of eligible tasks not in batch]
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

- In single mode: modify only `status` field (wave activation + in-progress)
- In batch mode: modify only `status` field for wave activation (`blocked` → `eligible`); do NOT set `in-progress` (orchestrator handles after spawn)
- Wave activation sets an entire wave to `eligible` at once (not individual tasks)
- Return complete task objects for orchestrator
- Report contentions avoided in batch mode
- Warn about tasks missing `filesTouched`
