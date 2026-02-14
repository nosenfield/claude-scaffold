# Batch Execute Tasks (Autonomous)

Autonomously execute multiple tasks in parallel using Agent Teams.

Orchestrates teammates to complete batches of parallelizable tasks until the task list is complete.

## Overview

This command acts as team lead executing waves sequentially with parallel tasks within each wave:

1. Determine current wave
2. Activate wave (set blocked tasks to ready)
3. Execute wave batches until wave complete
4. Advance to next wave
5. Repeat until all waves complete

**Design principle:** Execute waves linearly. Parallelize tasks within each wave.

## Prerequisites

- Repository must be initialized (run `/init-repo` first if not)
- `task-list.json` must contain tasks with `waveSummary` computed (run `/compute-waves` if needed)
- Agent Teams must be enabled (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`)

## Workflow

### Outer Loop: Waves

```
while incomplete waves exist:

    Phase 1: Determine Current Wave
    Phase 2: Activate Wave
    Phase 3: Execute Wave (inner loop over batches)
    Phase 4: Verify Wave Complete
    Phase 5: Advance to Next Wave

Report Completion
```

### Phase 1: Determine Current Wave

```
currentWave = min(executionWave) among tasks where status !== "complete"
```

**If all tasks complete**:
```
## All Tasks Complete

**Completed**: [N] tasks
**Waves Executed**: [W]

Run `/dev` to see project status.
```
Stop execution.

### Phase 2: Activate Wave

For all tasks where `executionWave === currentWave AND status === "blocked"`:
- Set `status: "ready"`

```
## Wave [N] Activated

**Tasks in Wave**: [count]
**Set to Ready**: [count]
```

### Phase 3: Execute Wave (Inner Loop)

While wave has ready tasks:

#### 3a. Batch Selection

Execute `/next-batch-from-list` to get parallelizable tasks from current wave.

**If NO_PENDING_TASKS or ALL_TASKS_BLOCKED in current wave**: Wave complete, exit inner loop.

#### 3b. Claim Tasks

For each task in batch, update task-list.json:
- Set `status: "in-progress"`
- Set `assignedAgent: "[agent-instance-id]"`

This prevents other orchestrators from claiming these tasks.

```json
{
  "status": "in-progress",
  "assignedAgent": "teammate-001"
}
```

#### 3c. Spawn Teammates

For each task, spawn teammate with prompt:
```
You are executing task [taskId] as part of a batch.
Task: [title]
Description: [description]
Acceptance Criteria: [criteria]
References: [references]
Files Expected: [filesTouched]

Run /execute-task-from-batch with this task. Return result when complete.
```

#### 3d. Collect Results

Wait for all teammates to report structured results:

**On success**:
```
TASK_COMPLETE
taskId: [id]
result:
  status: success
  summary: [what was done]
  filesModified: [actual files changed]
  blockers: []
```

**On failure**:
```
TASK_FAILED
taskId: [id]
result:
  status: failure
  summary: [why it failed]
  filesModified: [any partial work]
  blockers: [issues preventing completion]
```

#### 3e. Update Memory

Spawn `memory-updater` with `batchMode: true` and collected results.

The agent will:
- Update task-list.json:
  - Successful tasks: `status: "complete"`, write `result` object, set `completedAt`
  - Failed tasks: `status: "failed"`, write `result` object
- Update progress.md and decisions.md

Note: Wave advancement (blocked → ready) is handled by the orchestrator at Phase 2, not memory-updater.

#### 3f. Handle Failures

For failed tasks within the wave:
```
if result.blockers references upstream task:
    # Upstream deficiency - do not retry
    keep status: "failed"
else if retry_count < 2:
    # Retriable failure - reset for next batch
    set status: "ready"
    clear assignedAgent
    clear result
    retry_count++
else:
    # Max retries exceeded
    keep status: "failed"
```

#### 3g. Report Batch

```
## Batch Complete

**Wave**: [N] | **Batch**: [B]
**Completed**: [X] tasks | **Failed**: [Y] tasks | **Retrying**: [Z] tasks

| Task | Status | Summary |
|------|--------|---------|
| TASK-003 | complete | Implemented auth middleware |
| TASK-005 | complete | Created user model |
| TASK-007 | retry | Test failure (attempt 1/2) |
```

Loop back to 3a if wave has remaining ready tasks.

### Phase 4: Verify Wave Complete

Check all tasks in current wave:

**If all tasks `status === "complete"`**: Wave successful, continue to Phase 5.

**If any tasks `status === "failed"` after max retries**:
```
## Wave [N] Incomplete

**Completed**: [X] tasks | **Failed**: [Y] tasks

Failed tasks:
- TASK-007: [blockers]

Options:
1. Skip failed tasks and continue to next wave
2. Abort execution for manual intervention

[Prompt user for decision]
```

### Phase 5: Advance to Next Wave

```
## Wave [N] Complete

**Tasks Completed**: [count]
**Advancing to Wave**: [N+1]
```

Continue outer loop (back to Phase 1).

## Error Handling

### Teammate Timeout
- Log warning, shutdown teammate
- Set task `status: "failed"` with `result.blockers: ["Agent timeout"]`
- Continue with other teammates

### Partial Failure
- Process successes normally
- Failed tasks retried within wave (up to 2 attempts per task)
- After max retries, prompt user: skip or abort

### Full Batch Failure
- Report details
- Stop execution
- Preserve context for manual intervention

### Contention Detected at Runtime
If teammate reports modifying files outside `filesTouched`:
- Log warning in batch report
- Note for future wave computation
- Continue execution (no rollback)

## Notes

- Requires Agent Teams (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`)
- Each teammate runs in its own context window
- Memory updates happen once per batch, not per task
- Use `/execute-task-auto` for single-task workflow
- Run `/compute-waves` after manual task list edits
