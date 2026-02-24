# Compute Execution Waves

Analyze task dependencies and generate `waveSummary` for parallel execution.

Run this command after creating or modifying the task list to enable batch parallelization.

## Overview

This command performs a topological sort of tasks based on `blockedBy` dependencies, assigns `executionWave` values, and generates the `waveSummary` structure with contention detection.

## Prerequisites

- `_docs/task-list.json` must exist with tasks defined
- Tasks must have `blockedBy` arrays (can be empty)
- Tasks must have `filesTouched` arrays for contention detection

## Algorithm

### Step 1: Build Dependency Graph

```
for each task:
    node = task.id
    edges = task.blockedBy (incoming dependencies)
```

### Step 2: Topological Sort (Kahn's Algorithm)

```
wave = 0
ready = tasks where blockedBy is empty
while ready is not empty:
    assign wave to all ready tasks
    mark ready tasks as processed
    wave++
    ready = tasks where all blockedBy are processed
```

### Step 3: Detect Contentions

For each wave, compare `filesTouched` arrays pairwise:

```
for each pair (taskA, taskB) in wave:
    if intersection(taskA.filesTouched, taskB.filesTouched) is not empty:
        add [taskA.id, taskB.id] to wave.contentions
```

### Step 4: Update Task List

Write updated `task-list.json` with:
- `executionWave` set on each task
- `waveSummary` array at root level
- Initial `status` set based on wave:
  - Wave 0 tasks: `status: "eligible"` (eligible for immediate execution)
  - Wave 1+ tasks: `status: "blocked"` (awaiting wave activation by task-selector)

Note: "blocked" means the task is in a future wave, not that individual dependencies are unmet. The task-selector agent activates each wave by transitioning all its tasks from blocked to eligible at once when prior wave dependencies are complete.

## Output

```
## Waves Computed

**Total Tasks**: [N]
**Waves**: [W]

### Wave Summary

| Wave | Tasks | Max Parallelism | Contentions |
|------|-------|-----------------|-------------|
| 0 | TASK-001 | 1 | None |
| 1 | TASK-002, TASK-003, TASK-004 | 3 | None |
| 2 | TASK-005, TASK-006 | 2 | TASK-005 <-> TASK-006 |

### Contention Details

- **Wave 2**: TASK-005 and TASK-006 share `src/routes/index.ts`
  - These tasks will run sequentially within the wave

### Status Updates

- [N] tasks set to `eligible` (wave 0)
- [M] tasks set to `blocked` (waves 1+)
```

## Error Handling

### Circular Dependencies

If topological sort detects a cycle:

```
## Circular Dependency Detected

The following tasks form a dependency cycle:

TASK-003 -> TASK-005 -> TASK-007 -> TASK-003

Cannot compute waves. Fix dependencies before proceeding.
```

### Missing Dependencies

If `blockedBy` references a non-existent task:

```
## Missing Dependency

TASK-005 references TASK-099 in blockedBy, but TASK-099 does not exist.

Fix task list before computing waves.
```

## Example

Input tasks:
```
TASK-001: blockedBy=[]
TASK-002: blockedBy=[TASK-001]
TASK-003: blockedBy=[TASK-001]
TASK-004: blockedBy=[TASK-002, TASK-003]
```

Output waves:
```
Wave 0: [TASK-001]
Wave 1: [TASK-002, TASK-003]
Wave 2: [TASK-004]
```

## Notes

- Run after any modification to task dependencies
- Run after adding or removing tasks
- The command modifies `task-list.json` in place
- Existing `status` values are preserved for `in-progress`, `complete`, and `failed` tasks
- Only `blocked` and `eligible` are set based on wave computation
