# Batch Execute Tasks (Autonomous)

Autonomously execute multiple tasks in parallel using Agent Teams.

Orchestrates teammates to complete batches of parallelizable tasks until the task list is complete.

## Overview

This command acts as team lead executing waves sequentially with parallel tasks within each wave:

1. Determine current wave
2. Activate wave (set blocked tasks to eligible)
3. Execute wave batches until wave complete
4. Commit wave progress (task-list.json + memory files)
5. Advance to next wave
6. Repeat until all waves complete

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
    Phase 5: Commit Wave Progress
    Phase 6: Advance to Next Wave

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

Clear any stale commit lock from a previous wave:
```bash
.githooks/git-commit-lock.sh force-release
```

For all tasks where `executionWave === currentWave AND status === "blocked"`:
- Set `status: "eligible"`

```
## Wave [N] Activated

**Tasks in Wave**: [count]
**Set to Eligible**: [count]
```

### Phase 3: Execute Wave (Inner Loop)

While wave has eligible tasks:

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

For each task, use the Task tool to spawn a teammate with a **self-contained prompt**:

1. Read `.claude/partials/teammate-prompt.md`
2. Substitute bracketed placeholders with task values from task-list.json
3. Pass the filled template as the `prompt` parameter

```
Task tool parameters:
  prompt: [filled template from above]
  name: "worker-[NNN]"           # Unique teammate name
  subagent_type: "general-purpose"
  team_name: [active team name]
  mode: "bypassPermissions"
  max_turns: 200                  # Full dev cycles need ample turn budget
```

**Why `max_turns: 200`**: A full development cycle (context loading + plan + test + implement + review + commit + report) consumes 50-150 assistant turns depending on task complexity. The default (~25-30) is insufficient. Setting 200 provides headroom without risking runaway execution.

#### 3d. Collect Results (Active Polling)

**Do NOT end your turn after spawning teammates.** The automatic inbox delivery mechanism is unreliable for waking idle agents. Instead, actively poll your inbox file to collect results.

Execute immediately after spawning all teammates:

```bash
_scripts/poll-inbox.sh "[team-name]" [number of spawned teammates]
```

This polls every 30 seconds until all teammates report, then prints all results. Parse each result and proceed to 3e.

#### 3e. Check for Failures (Pause Point)

After all teammates report (or timeout), check for any TASK_FAILED results.

**If ANY task failed**:

1. **Allow in-progress teammates to complete**: Do NOT terminate teammates still executing. Wait for all spawned teammates in this batch to finish their current work.

2. **Collect all results**: Gather both success and failure results from the batch.

3. **Update memory**: Spawn `memory-updater` with `batchMode: true` and collected results.

4. **Pause for user input**:
```
## Batch Paused - Task Failure Detected

**Wave**: [N] | **Batch**: [B]
**Completed**: [X] tasks | **Failed**: [Y] tasks

### Failed Tasks
| Task | Phase | Blockers |
|------|-------|----------|
| TASK-007 | implementation | [blocker description] |

### Options
1. **Retry**: Reset failed tasks to eligible, continue wave
2. **Skip**: Mark as failed, continue to next wave
3. **Abort**: Stop for manual intervention
```

Wait for user response.

**User response handling**:
- **Option 1 (Retry)**: Continue to 3g, then loop to 3a
- **Option 2 (Skip)**: Failed tasks remain "failed"; exit inner loop to Phase 4
- **Option 3 (Abort)**: Stop execution, preserve context for manual intervention

**If ALL tasks succeeded**: Continue to 3f (skip pause).

#### 3f. Update Memory (Success Path)

Spawn `memory-updater` with `batchMode: true` and collected results.

The agent will:
- Update task-list.json:
  - Successful tasks: `status: "complete"`, write `result` object, set `completedAt`
- Update progress.md and decisions.md

Note: Wave advancement (blocked → eligible) is handled by the orchestrator at Phase 2, not memory-updater.

After memory update, collect `backlog` entries from all teammate results. For each non-empty backlog item, append to `_docs/backlog.json`:

```json
{
  "id": "BACKLOG-[next]",
  "sourceTask": "[teammate's taskId]",
  "category": "maintainability",
  "description": "[backlog item text]",
  "createdAt": "[ISO timestamp]"
}
```

Skip this step if no teammates reported backlog items.

#### 3g. Handle Retry (User-Initiated)

If user selected "Retry failed tasks" in 3e:

```
for each failed task:
    set status: "eligible"
    clear assignedAgent
    clear result
```

Loop back to 3a to include retried tasks in next batch selection.

#### 3h. Report Batch

Report completed tasks. Loop back to 3a if wave has remaining eligible tasks.

### Phase 4: Verify Wave Complete

Check all tasks in current wave:
- **All complete**: Continue to Phase 5
- **Any failed** (user selected "Skip"): Note skipped tasks, continue to Phase 5

### Phase 5: Commit Wave Progress

Commit task-list.json and memory file updates accumulated during the wave. This captures all status transitions (eligible -> in-progress -> complete), result objects, and memory updates in a single infrastructure commit per wave.

```bash
git add _docs/task-list.json _docs/memory/progress.md _docs/memory/decisions.md _docs/backlog.json
git commit -m "chore: complete wave [N] - [count] tasks done

Tasks: [TASK-XXX, TASK-YYY, ...]

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

**Why per-wave**: The single-task workflow amends the implementation commit (decision 2026-02-11). In batch mode, multiple teammates make separate implementation commits, so amending is not applicable. One infrastructure commit per wave keeps history clean without per-batch clutter.

### Phase 6: Advance to Next Wave

Report wave completion. Continue outer loop (back to Phase 1).

## Error Handling

### Teammate Timeout
- Log warning, shutdown teammate
- Set task `status: "failed"` with `result.blockers: ["Agent timeout"]`
- Triggers pause behavior (above)

### Full Batch Failure
- All tasks in batch failed
- Report details
- Pause for user decision (same options as partial failure)

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

## Session Chaining (Large Task Lists)

For task lists that may exceed the context window (~28+ tasks across multiple waves), use `/batch-execute-chained`. It runs each wave in a separate `claude -p` session with a fresh context window while the super-orchestrator stays lean.
