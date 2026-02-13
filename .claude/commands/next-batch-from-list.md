# Next Batch from List

Select a batch of parallelizable tasks from the task list.

Used by `/batch-execute-task-auto` to get tasks that can run concurrently.

## Overview

Spawns the `task-selector` agent in batch mode to:
1. Read task-list.json
2. Identify all unblocked pending tasks
3. Group tasks with non-overlapping `affectedPaths`
4. Return batch of parallelizable tasks

## Steps

1. **Spawn task-selector in Batch Mode**
   Invoke `task-selector` agent with:
   ```
   mode: batch
   ```

2. **Receive Batch Result**

   **If NO_PENDING_TASKS**:
   ```
   NO_PENDING_TASKS
   completedCount: [N]
   totalCount: [N]
   ```

   **If ALL_TASKS_BLOCKED**:
   ```
   ALL_TASKS_BLOCKED
   blockedTasks:
     - id: [taskId]
       title: [title]
       blockedBy: [list of blocking task IDs]
   ```

   **If BATCH_SELECTED**:
   ```
   BATCH_SELECTED
   batchSize: [N]
   tasks:
     - id: TASK-003
       title: Add auth middleware
       priority: 1
       description: [description]
       acceptanceCriteria:
         - [criterion 1]
       references:
         - [doc path]
       affectedPaths:
         - src/middleware/auth.ts
         - src/types/auth.ts
     - id: TASK-005
       title: Create user model
       priority: 2
       description: [description]
       acceptanceCriteria:
         - [criterion 1]
       references:
         - [doc path]
       affectedPaths:
         - src/models/user.ts
         - src/types/user.ts
   remainingTasks: [count of pending tasks not in batch]
   ```

3. **Report Result**

   For BATCH_SELECTED:
   ```
   ## Batch Selected

   **Batch Size**: [N] tasks
   **Remaining**: [M] pending tasks

   ### Tasks in Batch
   1. [TASK-003] Add auth middleware (priority 1)
      - Affects: src/middleware/auth.ts, src/types/auth.ts
   2. [TASK-005] Create user model (priority 2)
      - Affects: src/models/user.ts, src/types/user.ts

   No file conflicts detected. Tasks can run in parallel.
   ```

## Batch Selection Rules

The task-selector agent applies these rules:

1. **Unblocked only**: Task's `blockedBy` must be empty or all resolved
2. **No file conflicts**: Tasks in same batch must have non-overlapping `affectedPaths`
3. **Priority order**: Higher priority tasks selected first
4. **Greedy grouping**: Add tasks to batch while no conflicts exist

### Conflict Detection

Two tasks conflict if their `affectedPaths` arrays share any path:
```
TASK-003.affectedPaths: [src/auth.ts, src/types.ts]
TASK-004.affectedPaths: [src/auth.ts, src/config.ts]
→ Conflict: src/auth.ts appears in both
→ TASK-004 excluded from batch
```

### Missing affectedPaths

If a task lacks `affectedPaths`:
- Treat as conflicting with all other tasks
- Task runs in its own single-task batch
- Log warning for orchestrator

## Notes

- This command does NOT mark tasks as in-progress (orchestrator handles after spawning)
- Batch size depends on task independence, not a fixed limit
- Single-task batches are valid (when no parallelization possible)
- Use `/next-from-task-list` for single-task workflow
