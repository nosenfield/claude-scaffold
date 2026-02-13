# Batch Execute Tasks (Autonomous)

Autonomously execute multiple tasks in parallel using Agent Teams.

Orchestrates teammates to complete batches of parallelizable tasks until the task list is complete.

## Overview

This command acts as team lead to:
1. Select batch of parallelizable tasks
2. Spawn one teammate per task
3. Wait for all teammates to complete
4. Assess results and update memory
5. Repeat until no pending tasks

## Prerequisites

- Repository must be initialized (run `/init-repo` first if not)
- `task-list.json` must contain pending tasks (tasks missing `affectedPaths` run as single-task batches)
- Agent Teams must be enabled (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`)

## Workflow

### Phase 1: Batch Selection

Execute `/next-batch-from-list` to get parallelizable tasks.

**If NO_PENDING_TASKS**:
```
## All Tasks Complete

**Completed**: [N] tasks
**Session**: Batch execution finished

Run `/dev` to see project status.
```
Stop execution.

**If ALL_TASKS_BLOCKED**:
```
## Tasks Blocked

All pending tasks have unmet dependencies.

**Blocked Tasks**:
- [taskId]: blocked by [dependencies]

Manual intervention required.
```
Stop execution.

**If BATCH_SELECTED**: Continue to Phase 2.

### Phase 2: Mark Tasks In-Progress

For each task in batch, update task-list.json:
- Set `status: "in-progress"`

This prevents other orchestrators from claiming these tasks.

### Phase 3: Spawn Teammates

For each task, spawn teammate with prompt:
```
You are executing task [taskId] as part of a batch.
Task: [title]
Description: [description]
Acceptance Criteria: [criteria]
References: [references]

Run /execute-task-from-batch with this task. Return result when complete.
```

### Phase 4: Collect Results

Wait for all teammates to report `TASK_COMPLETE` or `TASK_FAILED`.

### Phase 5: Update Memory

Spawn `memory-updater` with `batchMode: true` and collected results. The agent will update task-list.json, progress.md, and decisions.md in one pass.

### Phase 6: Shutdown and Report

Shutdown all teammates. Report batch summary:
```
## Batch Complete
**Completed**: [N] tasks | **Failed**: [M] tasks
[Table of results]
```

### Phase 7: Loop or Complete

**If failed tasks exist**:
- Failed tasks remain in task-list.json as `pending`
- Will be retried in next batch (if unblocked)

**If more pending tasks exist**:
- Loop back to Phase 1

**If no pending tasks**:
- Report completion and stop

## Error Handling

- **Teammate timeout**: Log warning, shutdown teammate, mark task failed, continue with others
- **Partial failure**: Process successes, log failures for retry in next batch
- **Full batch failure**: Report details, stop execution, preserve context for manual intervention

## Notes

- Requires Agent Teams (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`)
- Each teammate runs in its own context window
- Memory updates happen once per batch, not per task
- Failed tasks reset to pending (retry in next batch)
- Use `/execute-task-auto` for single-task workflow
