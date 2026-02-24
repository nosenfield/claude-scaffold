# Execute One Wave

Execute exactly one wave of batch task execution, then exit.

Designed for session chaining: the super-orchestrator (`/batch-execute-chained`) invokes this command inside a `claude -p` subprocess with a fresh context window per wave.

## Overview

1. Determine current wave
2. Create team
3. Execute all batches in wave (inner loop)
4. Commit wave progress
5. Shutdown team and exit

**Non-interactive**: This command runs autonomously. It does NOT pause for user input. Failures are recorded in task-list.json for the super-orchestrator to handle.

## Prerequisites

- `task-list.json` must contain tasks with `waveSummary` computed
- Agent Teams must be enabled (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`)

## Workflow

### Phase 1: Determine Current Wave

Read `_docs/task-list.json`. Compute:

```
currentWave = min(executionWave) among tasks where status NOT IN ("complete", "failed")
```

**If all tasks are complete or failed**:
```
ALL_WAVES_COMPLETE total=[N]
```
Stop execution.

Clear any stale commit lock from a previous wave:
```bash
.githooks/git-commit-lock.sh force-release
```

### Phase 2: Create Team

```
TeamCreate: name = "wave-[currentWave]"
```

### Phase 3: Execute Wave Batches (Inner Loop)

While wave has eligible tasks:

#### 3a. Batch Selection

Execute `/next-batch-from-list` to get parallelizable tasks from current wave.

**If NO_PENDING_TASKS or ALL_TASKS_BLOCKED in current wave**: Wave complete, exit inner loop.

#### 3b. Claim Tasks

For each task in batch, update task-list.json:
- Set `status: "in-progress"`
- Set `assignedAgent: "[teammate-name]"`

#### 3c. Spawn Teammates

For each task, use the Task tool to spawn a teammate with a **self-contained prompt**:

1. Read `.claude/partials/teammate-prompt.md`
2. Substitute bracketed placeholders with task values from task-list.json
3. Pass the filled template as the `prompt` parameter

Task tool parameters:
```
prompt: [filled template from above]
name: "worker-[NNN]"
subagent_type: "general-purpose"
team_name: "wave-[currentWave]"
mode: "bypassPermissions"
max_turns: 200
```

#### 3d. Collect Results (Active Polling)

**Do NOT end your turn after spawning teammates.** Actively poll your inbox file to collect results.

Execute immediately after spawning all teammates:

```bash
_scripts/poll-inbox.sh "wave-[currentWave]" [number of spawned teammates]
```

This polls every 30 seconds until all teammates report, then prints all results. Parse each result and proceed to 3e.

#### 3e. Handle Results

Separate results into successes and failures.

**For failed tasks**: Update task-list.json:
```json
{
  "status": "failed",
  "assignedAgent": "[teammate-name]",
  "result": {
    "status": "failure",
    "summary": "[from teammate result]",
    "filesModified": "[from teammate result]",
    "blockers": "[from teammate result]"
  }
}
```

**Do NOT pause on failure.** The super-orchestrator handles user interaction for failures.

Continue to 3f with whatever results were collected (mix of success and failure is fine).

#### 3f. Update Memory

Spawn `memory-updater` agent with `batchMode: true` and collected results:

```
batchMode: true
tasks: [successful task results]
failedTasks: [failed task results]
```

#### 3g. Append Backlog Items

Collect `backlog` entries from all teammate results. For each non-empty backlog item, append to `_docs/backlog.json`:

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

#### 3h. Report Batch

Report completed tasks. Loop back to 3a if wave has remaining eligible tasks.

### Phase 4: Commit Wave Progress

Commit task-list.json and memory file updates accumulated during the wave:

```bash
git add _docs/task-list.json _docs/memory/progress.md _docs/memory/decisions.md _docs/backlog.json
git commit -m "chore: complete wave [N] - [count] tasks done

Tasks: [TASK-XXX, TASK-YYY, ...]

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

### Phase 5: Shutdown and Cleanup

1. Send `shutdown_request` (via SendMessage) to each active teammate
2. Wait up to 30 seconds for shutdown responses
3. Call `TeamDelete` to remove team

If TeamDelete fails (active members not yet deregistered), wait 5 seconds and retry once.

### Phase 6: Exit

Output the structured exit marker:

```
WAVE_COMPLETE wave=[N] completed=[X] failed=[Y]
```

Where:
- `[N]` = wave number executed
- `[X]` = number of tasks that completed successfully
- `[Y]` = number of tasks that failed (0 if all succeeded)

## Error Handling

| Error | Action |
|-------|--------|
| Teammate timeout (no result after polling) | Set task `status: "failed"`, `blockers: ["Agent timeout"]` |
| All tasks in batch failed | Record all as failed, continue to next batch |
| Contention detected at runtime | Log warning, continue execution |
| TeamDelete fails | Wait 5s, retry once. If still fails, force-cleanup via Bash |
| Git commit fails | Log error, continue (super-orchestrator will detect uncommitted state) |

## Notes

- This command is for session-chained workflow only (invoked by `/batch-execute-chained`)
- Do NOT use this command directly in interactive sessions
- Each invocation gets a fresh context window via `claude -p`
- State continuity is through task-list.json and memory files on disk
- Wave advancement (blocked → eligible) is handled by the task-selector agent, not this command
- The super-orchestrator handles failure recovery and user interaction
