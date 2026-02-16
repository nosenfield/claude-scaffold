# Batch Execute Tasks (Autonomous)

Autonomously execute multiple tasks in parallel using Agent Teams.

Orchestrates teammates to complete batches of parallelizable tasks until the task list is complete.

## Overview

This command acts as team lead executing waves sequentially with parallel tasks within each wave:

1. Determine current wave
2. Activate wave (set blocked tasks to eligible)
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

For each task, use the Task tool to spawn a teammate with a **self-contained prompt** constructed from the template below.

**Prompt template** (orchestrator fills bracketed values from task-list.json):

```
You are a teammate executing a development task. Complete the full cycle below, then report your result.

## Assigned Task

- **taskId**: [taskId]
- **title**: [title]
- **description**: [description]
- **acceptanceCriteria**:
  [each criterion as a bullet]
- **references**:
  [each reference path as a bullet, or "None"]
- **filesTouched**:
  [each file path as a bullet]

## Workflow

Execute these phases in order. Proceed automatically; do not pause for input.

0. **Load Context**: Read these files before starting work:
   - `_docs/architecture.md` (project structure, tech stack, component boundaries)
   - `_docs/memory/decisions.md` (architectural decisions -- do not contradict these)
   - Each file listed in **references** above (task-specific design constraints)
1. **Plan**: Run `/plan-task` with the task above. Auto-approve the plan.
2. **Test**: Run `/write-task-tests` to create failing tests. Verify they fail for expected reasons.
3. **Implement**: Run `/implement-task` to make tests pass. Verify all tests pass.
4. **Review**: Run `/review-task`. If APPROVE, continue. If REQUEST_CHANGES, loop back to Implement (max 3 loops).
5. **Commit**: Run `/commit-implementation` to commit changes.
6. **Report**: Send your result to the orchestrator using the SendMessage tool (see below).

## Reporting Result

After completing (or failing), you MUST send a message to the orchestrator:

**On success:**
Use the SendMessage tool with:
  type: "message"
  recipient: "team-lead"
  summary: "[taskId] complete"
  content: |
    TASK_COMPLETE
    taskId: [taskId]
    taskTitle: [title]
    commitSha: [sha from commit step]
    commitMessage: [message from commit step]
    result:
      status: success
      summary: [1-2 sentence description]
      filesModified: [list of files]
      blockers: []
    decisions: [list any decisions made]
    testsWritten: [count]
    reviewVerdict: APPROVE

**On failure:**
Use the SendMessage tool with:
  type: "message"
  recipient: "team-lead"
  summary: "[taskId] failed at [phase]"
  content: |
    TASK_FAILED
    taskId: [taskId]
    taskTitle: [title]
    phase: [planning|testing|implementation|review|commit]
    result:
      status: failure
      summary: [why it failed]
      filesModified: [any partial work]
      blockers: [specific issues]
    partialWork:
      testsWritten: [count or 0]
      filesModified: [list or empty]

## Constraints

- Do NOT update memory files (progress.md, decisions.md). The orchestrator handles this.
- Do NOT modify task-list.json directly.
- Do NOT expand scope beyond the assigned task.
- You MUST send a SendMessage to "team-lead" before finishing, whether you succeed or fail.
```

The orchestrator constructs this prompt by substituting task fields from task-list.json, then passes it as the `prompt` parameter to the Task tool with `team_name` set to the active team.

#### 3d. Collect Results

Wait for all teammates to report `TASK_COMPLETE` or `TASK_FAILED` with structured result objects (see `/execute-task-from-batch` for schema).

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

### Phase 5: Advance to Next Wave

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
