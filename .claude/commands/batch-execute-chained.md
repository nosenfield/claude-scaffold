# Batch Execute Tasks (Chained)

Autonomously execute all waves of a task list using session chaining. Each wave runs in a separate `claude -p` subprocess with a fresh context window, preventing the context overflow that occurs with `/batch-execute-task-auto` on large task lists.

## Overview

This command acts as a super-orchestrator: it manages the wave loop, launches disposable `claude -p` sessions for wave execution, validates results, and handles failures with user interaction.

```
Super-orchestrator (this session, stays lean)
  |
  +-- Wave 0: claude -p "Execute /execute-one-wave" (fresh context)
  |     - Creates team, spawns teammates, collects results
  |     - Updates memory, commits, cleans up
  |
  +-- Wave 1: claude -p "Execute /execute-one-wave" (fresh context)
  |     ...
  +-- Wave N: all tasks complete
```

**When to use**: Task lists with more than ~28 tasks or 5+ waves. For smaller task lists, `/batch-execute-task-auto` works within a single context window.

## Prerequisites

- Repository must be initialized (run `/init-repo` first if not)
- `task-list.json` must contain tasks with `waveSummary` computed (run `/compute-waves` if needed)
- Agent Teams must be enabled (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`)

## Workflow

### Phase 1: Pre-check

1. Read `_docs/task-list.json`
2. Verify `waveSummary` exists. If missing:
   ```
   ## Waves Not Computed

   task-list.json does not have waveSummary.
   Run `/compute-waves` before batch execution.
   ```
   Stop.

3. Count total tasks, total waves, and current status breakdown:
   ```
   ## Batch Execution (Chained)

   **Total Tasks**: [N]
   **Total Waves**: [W]
   **Status**: [X] complete, [Y] failed, [Z] remaining
   ```

### Phase 2: Wave Loop

```
while true:
    2a. Read Status
    2b. Check Completion
    2c. Launch Wave
    2d. Poll for Completion
    2e. Validate Results
    2f. Report and Loop
```

#### 2a. Read Status

Read `_docs/task-list.json` and compute:

```python
tasks = data["tasks"]
by_status = {
    "complete": [t for t in tasks if t["status"] == "complete"],
    "failed": [t for t in tasks if t["status"] == "failed"],
    "eligible": [t for t in tasks if t["status"] == "eligible"],
    "blocked": [t for t in tasks if t["status"] == "blocked"],
    "in-progress": [t for t in tasks if t["status"] == "in-progress"],
}
incomplete = [t for t in tasks if t["status"] not in ("complete", "failed")]
currentWave = min(t["executionWave"] for t in incomplete) if incomplete else None
```

#### 2b. Check Completion

**If no incomplete tasks** (all complete or failed):
Report final summary (Phase 3) and stop.

**If failed tasks exist AND no incomplete non-failed tasks in the current wave**:
Prompt user:

```
## Failed Tasks Detected

**Failed**: [count]
| Task | Wave | Blockers |
|------|------|----------|
| TASK-XXX | [N] | [blocker summary] |

### Options
1. **Retry** - Reset failed tasks to eligible, re-execute
2. **Skip** - Leave as failed, continue to next wave
3. **Abort** - Stop execution for manual intervention
```

Handle response:
- **Retry**: For each failed task in the current wave, update task-list.json:
  ```json
  { "status": "eligible", "assignedAgent": null, "result": null }
  ```
  Loop to 2a.
- **Skip**: Leave failed tasks as-is. Continue (execute-one-wave skips them).
- **Abort**: Stop execution.

**If ready** (incomplete tasks exist, no unhandled failures): Continue to 2c.

#### 2c. Launch Wave

Report progress:
```
## Launching Wave [N]

**Tasks in wave**: [count]
**Elapsed**: [X] complete, [Y] failed, [Z] remaining
```

Launch `claude -p` in the background:

```bash
env -u CLAUDECODE claude -p --dangerously-skip-permissions "You are executing one wave of batch tasks. Run /execute-one-wave and follow its instructions exactly. Proceed autonomously. Do not ask for user input." 2>&1
```

Use the Bash tool with `run_in_background: true` to launch this. Capture the task_id.

#### 2d. Poll for Completion

Use TaskOutput to check on the background process:

```
TaskOutput(task_id=[id], block: false, timeout: 30000)
```

Repeat every 60 seconds until the task completes (status changes from "running" to "completed").

While waiting, report progress dots or a brief status line.

#### 2e. Validate Results

After the `claude -p` process completes:

1. Read `_docs/task-list.json`
2. Count tasks that changed status since 2a
3. Report:

```
## Wave [N] Complete

**Completed**: [X] tasks
**Failed**: [Y] tasks
**Remaining**: [Z] tasks across [W] waves

[If failed: list failed task IDs and blockers]
```

#### 2f. Loop

Return to 2a.

### Phase 3: Final Report

```
## All Waves Complete

**Total Tasks**: [N]
**Succeeded**: [X]
**Failed**: [Y]
**Waves Executed**: [W]

[If failed tasks exist:]
### Failed Tasks
| Task | Blockers |
|------|----------|
| TASK-XXX | [blockers] |

Run `/dev` to see project status.
```

## Error Handling

| Error | Action |
|-------|--------|
| `claude -p` exits with non-zero code | Read task-list.json to assess damage; report to user; loop continues |
| `claude -p` produces no output | Check task-list.json for changes; warn user; continue |
| Wave makes no progress (same status before/after) | Warn user: "Wave [N] made no progress. Possible issue." Prompt for retry/abort |
| Stale in-progress tasks (from crashed prior wave) | Reset to eligible at start of loop iteration |

### Stale In-Progress Recovery

At the start of each loop iteration (2a), check for tasks with `status: "in-progress"` that have no active team. These are stale from a crashed prior wave:

```python
stale = [t for t in tasks if t["status"] == "in-progress"]
```

If stale tasks found, reset them:
```json
{ "status": "eligible", "assignedAgent": null }
```

This self-heals from crashed `claude -p` sessions.

## Notes

- Each wave runs in a fresh `claude -p` context window (~200k tokens available per wave)
- The super-orchestrator stays lean (~5k tokens per wave iteration)
- For 20+ waves, the super-orchestrator uses ~100k tokens total (within 200k limit)
- State continuity is through task-list.json and memory files on disk
- Use `/batch-execute-task-auto` for smaller task lists (fewer than ~28 tasks / 5 waves)
- The `claude -p` subprocess has the full tool set (Task, TeamCreate, SendMessage)
- Failed tasks are not automatically retried -- the super-orchestrator prompts the user
