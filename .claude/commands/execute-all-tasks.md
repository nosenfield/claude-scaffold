# Execute All Tasks (Linear)

Autonomously execute all tasks from a linear task list using session chaining. Each task runs in a separate `claude -p` subprocess with a fresh context window, preventing context overflow regardless of list size.

## Overview

This command acts as a super-orchestrator: it manages the task loop, launches a disposable `claude -p` session per task, validates results, and handles failures with user interaction.

```
Super-orchestrator (this session, stays lean)
  |
  +-- Task 1: claude -p "Execute /execute-task-auto" (fresh context)
  |     - Selects next task, plans, tests, implements, reviews, commits
  |     - Updates memory + task-list.json via /commit-task
  |
  +-- Task 2: claude -p "Execute /execute-task-auto" (fresh context)
  |     ...
  +-- Task N: all tasks complete
```

**When to use**: Any linear task list where you want single-command full build. This is the linear counterpart to `/batch-execute-chained` (which handles parallel wave-based lists).

**Design**: Always uses session chaining (one `claude -p` per task). Each task gets ~200k tokens of fresh context. The super-orchestrator stays lean (~5k tokens per iteration). State continuity is through task-list.json and memory files on disk.

## Prerequisites

- Repository must be initialized (run `/init-repo` first if not)
- `_docs/task-list.json` must contain eligible or blocked tasks
- No `waveSummary` required (works with both v1.0 and v2.0 schemas)

## Workflow

### Phase 1: Pre-check

1. Read `_docs/task-list.json`
2. Parse tasks and compute status breakdown:

```
## Execute All Tasks (Linear)

**Total Tasks**: [N]
**Status**: [X] complete, [Y] failed, [Z] remaining
```

**If no remaining tasks** (all complete or failed with none eligible/blocked):

```
## All Tasks Already Complete

**Completed**: [X] of [N] tasks
[If failed: **Failed**: [Y] tasks]

Nothing to execute. Run `/dev` to see project status.
```

Stop.

### Phase 2: Task Loop

```
while true:
    2a. Read Status
    2b. Stale Recovery
    2c. Check Completion
    2d. Launch Task
    2e. Poll for Completion
    2f. Validate Result
    2g. Loop
```

#### 2a. Read Status

Read `_docs/task-list.json` and compute:

```python
tasks = data["tasks"]
by_status = {
    "complete": [t for t in tasks if t["status"] == "complete"],
    "failed": [t for t in tasks if t["status"] == "failed"],
    "eligible": [t for t in tasks if t["status"] == "eligible"],
    "blocked": [t for t in tasks if t.get("status") == "blocked"],
    "in-progress": [t for t in tasks if t["status"] == "in-progress"],
}
remaining = [t for t in tasks if t["status"] not in ("complete", "failed")]
```

#### 2b. Stale Recovery

Check for tasks with `status: "in-progress"` left over from crashed prior sessions:

```python
stale = [t for t in tasks if t["status"] == "in-progress"]
```

If stale tasks found, reset them in `_docs/task-list.json`:

```json
{ "status": "eligible", "assignedAgent": null }
```

Report:

```
**Stale Recovery**: Reset [N] in-progress task(s) to eligible
```

#### 2c. Check Completion

**If no remaining tasks** (all complete or failed):
Report final summary (Phase 3) and stop.

**If failed tasks exist AND no eligible or blocked tasks remain**:
Prompt user:

```
## Failed Tasks - No Eligible Tasks Remain

**Failed**: [count]
| Task | Blockers |
|------|----------|
| TASK-XXX | [blocker summary] |

### Options
1. **Retry** - Reset failed tasks to eligible, re-execute
2. **Abort** - Stop execution for manual intervention
```

Handle response:
- **Retry**: For each failed task, update task-list.json:
  ```json
  { "status": "eligible", "assignedAgent": null, "result": null }
  ```
  Loop to 2a.
- **Abort**: Stop execution.

**If eligible or blocked tasks exist**: Continue to 2d.

#### 2d. Launch Task

Report progress:

```
## Executing Next Task

**Completed so far**: [C] of [N]
**Failed so far**: [F]
**Remaining**: [R]
```

Launch `claude -p` in the background:

```bash
env -u CLAUDECODE claude -p --dangerously-skip-permissions "You are executing one task from the task list. Run /execute-task-auto and follow its instructions exactly. Proceed autonomously. Do not ask for user input." 2>&1
```

Use the Bash tool with `run_in_background: true` to launch this. Capture the task_id.

**Note**: The subprocess runs `/execute-task-auto`, which internally:
1. Invokes `/next-from-task-list` (task-selector picks the next eligible task)
2. Plans, tests, implements, reviews
3. Calls `/commit-task` (which commits code, spawns memory-updater, updates task-list.json, amends commit)

The super-orchestrator does NOT select the task or manage the dev cycle. That is fully delegated.

#### 2e. Poll for Completion

Use TaskOutput to check on the background process:

```
TaskOutput(task_id=[id], block: false, timeout: 30000)
```

Repeat every 60 seconds until the task completes (status changes from "running" to "completed").

While waiting, report a brief status line.

#### 2f. Validate Result

After the `claude -p` process completes:

1. Read `_docs/task-list.json`
2. Compare task statuses against the snapshot from 2a
3. Identify which task changed status (if any)

**If a task moved to "complete"**:

```
## Task Complete: [taskId] - [taskTitle]

**Commit**: [check via git log -1 --oneline]
**Tasks Remaining**: [R]
```

Continue to 2g.

**If a task moved to "failed"** (or status is "in-progress" with process exited):

If task is still "in-progress" (subprocess crashed without updating status), reset it:
```json
{
  "status": "failed",
  "result": {
    "status": "failure",
    "summary": "Subprocess exited without completing",
    "filesModified": [],
    "blockers": ["Session terminated unexpectedly"]
  }
}
```

Prompt user:

```
## Task Failed: [taskId] - [taskTitle]

**Blockers**: [from result.blockers or "Subprocess exited without completing"]

### Options
1. **Retry** - Reset to eligible, re-execute
2. **Skip** - Leave as failed, continue to next task
3. **Abort** - Stop execution for manual intervention
```

Handle response:
- **Retry**: Reset task in task-list.json:
  ```json
  { "status": "eligible", "assignedAgent": null, "result": null }
  ```
  Loop to 2a.
- **Skip**: Leave as failed. Loop to 2a.
- **Abort**: Stop execution.

**If no task changed status** (subprocess made no progress):

```
## No Progress Detected

The subprocess exited without completing any task.

### Options
1. **Retry** - Re-launch subprocess
2. **Abort** - Stop execution for manual intervention
```

Handle response:
- **Retry**: Loop to 2a.
- **Abort**: Stop execution.

#### 2g. Loop

Return to 2a.

### Phase 3: Final Report

```
## All Tasks Executed

**Total Tasks**: [N]
**Succeeded**: [X]
**Failed**: [Y]
**Tasks Executed This Session**: [Z]

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
| `claude -p` exits with non-zero code | Read task-list.json to assess; prompt user (Retry/Skip/Abort) |
| `claude -p` produces no output | Check task-list.json for changes; warn user; prompt (Retry/Abort) |
| Task stuck in "in-progress" after subprocess exits | Reset to "failed" with crash marker; prompt user |
| No progress across iteration (same status before/after) | Warn user; prompt (Retry/Abort) |
| Stale in-progress tasks at loop start | Auto-reset to "eligible" (self-healing) |
| task-list.json unreadable or missing | Stop with error |

### Dependency Unblocking

The super-orchestrator does NOT manage dependency resolution. The task-selector agent (invoked by `/next-from-task-list` inside the subprocess) handles dependency checking: when all blockers for a task are complete, it becomes selectable. This works identically for v1.0 (runtime dependency check) and v2.0 (wave-based) schemas.

## Notes

- Each task runs in a fresh `claude -p` context window (~200k tokens available per task)
- The super-orchestrator stays lean (~5k tokens per loop iteration)
- State continuity is through task-list.json and memory files on disk
- Does NOT require Agent Teams -- no teammates are spawned
- Does NOT require waveSummary -- works with v1.0 linear task lists directly
- The `claude -p` subprocess has full tool access via `--dangerously-skip-permissions`
- Failed tasks are not automatically retried -- the super-orchestrator prompts the user
- Task ordering is determined by the task-selector agent (priority-based, dependency-aware)
- `/commit-task` inside each subprocess handles all memory updates and commits
- No post-task infrastructure commits needed by the super-orchestrator
