# Next Batch from List

Select a batch of parallelizable tasks from the task list.

Used by `/batch-execute-task-auto` to get tasks that can run concurrently.

## Overview

Spawns the `task-selector` agent in batch mode to:
1. Read task-list.json
2. Filter tasks with `status: "ready"`
3. Use `waveSummary.contentions` to avoid file conflicts
4. Return batch of parallelizable tasks

## Prerequisites

- `task-list.json` must exist with `waveSummary` computed
- Run `/compute-waves` if `waveSummary` is missing or stale

## Steps

1. **Check for waveSummary**

   Read `_docs/task-list.json` and verify `waveSummary` exists.

   **If missing**:
   ```
   ## Waves Not Computed

   task-list.json does not have waveSummary.
   Run `/compute-waves` before batch selection.
   ```
   Stop.

2. **Spawn task-selector in Batch Mode**

   Invoke `task-selector` agent with:
   ```
   mode: batch
   ```

3. **Receive Batch Result**

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
       executionWave: 1
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
       executionWave: 1
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
   ```

4. **Report Result**

   For BATCH_SELECTED:
   ```
   ## Batch Selected

   **Wave**: [current wave from tasks]
   **Batch Size**: [N] tasks
   **Remaining in Wave**: [M] ready tasks

   ### Tasks in Batch
   1. [TASK-003] Add auth middleware (priority 1)
      - Files: src/middleware/auth.ts, src/types/auth.ts
   2. [TASK-005] Create user model (priority 2)
      - Files: src/models/user.ts, src/types/user.ts

   ### Contentions Avoided
   - TASK-003 and TASK-007 share src/routes/index.ts (TASK-007 deferred)

   No file conflicts in batch. Tasks can run in parallel.
   ```

## Batch Selection Rules

The task-selector agent applies these rules:

1. **Ready status only**: Task must have `status: "ready"`
2. **Contention check**: Use `waveSummary.contentions` to identify conflicting pairs
3. **File overlap check**: Defense in depth - compare `filesTouched` arrays
4. **Priority order**: Higher priority tasks selected first
5. **Concurrency limit**: Respect `metadata.maxConcurrency`

### Contention Handling

Tasks listed in `waveSummary.contentions` cannot run in the same batch:
```json
"contentions": [["TASK-005", "TASK-006"]]
```

If both TASK-005 and TASK-006 are ready:
- TASK-005 (higher priority) enters batch
- TASK-006 excluded, noted in `contentionsAvoided`

### Empty filesTouched

If a task lacks `filesTouched`:
- Include in batch only if batch is empty (single-task batch)
- Log warning for orchestrator
- Recommend running `/compute-waves` to update

## Notes

- This command does NOT mark tasks as in-progress (orchestrator handles after claiming)
- Batch size depends on task independence and `maxConcurrency`, not a fixed limit
- Single-task batches are valid (when contentions prevent parallelization)
- Use `/next-from-task-list` for single-task workflow
