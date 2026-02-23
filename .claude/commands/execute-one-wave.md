# Execute One Wave

Execute exactly one wave of batch task execution, then exit.

Designed for session chaining: the super-orchestrator (`/batch-execute-chained`) invokes this command inside a `claude -p` subprocess with a fresh context window per wave.

## Overview

1. Determine current wave
2. Activate wave (blocked -> eligible)
3. Create team
4. Execute all batches in wave (inner loop)
5. Commit wave progress
6. Shutdown team and exit

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

### Phase 2: Activate Wave

Clear any stale commit lock from a previous wave:
```bash
.githooks/git-commit-lock.sh force-release
```

For all tasks where `executionWave === currentWave AND status === "blocked"`:
- Set `status: "eligible"` in task-list.json

### Phase 3: Create Team

```
TeamCreate: name = "wave-[currentWave]"
```

### Phase 4: Execute Wave Batches (Inner Loop)

While wave has eligible tasks:

#### 4a. Batch Selection

Execute `/next-batch-from-list` to get parallelizable tasks from current wave.

**If NO_PENDING_TASKS or ALL_TASKS_BLOCKED in current wave**: Wave complete, exit inner loop.

#### 4b. Claim Tasks

For each task in batch, update task-list.json:
- Set `status: "in-progress"`
- Set `assignedAgent: "[teammate-name]"`

#### 4c. Spawn Teammates

For each task, use the Task tool to spawn a teammate with a **self-contained prompt** constructed from the template below.

**Prompt template** (fill bracketed values from task-list.json):

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
    backlog: [list any deferred non-blocking issues from code review, or bugs/tech debt discovered during implementation -- or empty]
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
- Add any deferred non-blocking code review issues, bugs, improvements, or tech debt to the `backlog` field of your result message.
- You MUST send a SendMessage to "team-lead" before finishing, whether you succeed or fail.
```

Task tool parameters:
```
prompt: [constructed from template above]
name: "worker-[NNN]"
subagent_type: "general-purpose"
team_name: "wave-[currentWave]"
mode: "bypassPermissions"
max_turns: 200
```

#### 4d. Collect Results (Active Polling)

**Do NOT end your turn after spawning teammates.** Actively poll your inbox file to collect results.

**Polling loop** (execute immediately after spawning all teammates):

```bash
# Poll inbox every 30 seconds until all teammates report
INBOX=~/.claude/teams/wave-[currentWave]/inboxes/team-lead.json
EXPECTED=[number of spawned teammates]

while true; do
  sleep 30
  # Count TASK_COMPLETE and TASK_FAILED messages
  DONE=$(python3 -c "
import json
with open('$INBOX') as f:
    msgs = json.load(f)
completed = [m for m in msgs if not m.get('read', True) and ('TASK_COMPLETE' in m.get('text','') or 'TASK_FAILED' in m.get('text',''))]
print(len(completed))
  ")
  echo "[$(date +%H:%M:%S)] $DONE of $EXPECTED teammates reported"
  if [ "$DONE" -ge "$EXPECTED" ]; then
    echo "All teammates reported. Collecting results."
    break
  fi
done
```

**After the loop exits**, read the full inbox to extract each result:

```bash
python3 -c "
import json
with open('$INBOX') as f:
    msgs = json.load(f)
for m in msgs:
    if not m.get('read', True) and ('TASK_COMPLETE' in m.get('text','') or 'TASK_FAILED' in m.get('text','')):
        print(f'--- {m[\"from\"]} ({m[\"summary\"]}) ---')
        print(m['text'])
        print()
"
```

Parse each result and proceed to 4e.

#### 4e. Handle Results

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

Continue to 4f with whatever results were collected (mix of success and failure is fine).

#### 4f. Update Memory

Spawn `memory-updater` agent with `batchMode: true` and collected results:

```
batchMode: true
tasks: [successful task results]
failedTasks: [failed task results]
```

#### 4g. Append Backlog Items

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

#### 4h. Report Batch

Report completed tasks. Loop back to 4a if wave has remaining eligible tasks.

### Phase 5: Commit Wave Progress

Commit task-list.json and memory file updates accumulated during the wave:

```bash
git add _docs/task-list.json _docs/memory/progress.md _docs/memory/decisions.md _docs/backlog.json
git commit -m "chore: complete wave [N] - [count] tasks done

Tasks: [TASK-XXX, TASK-YYY, ...]

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

### Phase 6: Shutdown and Cleanup

1. Send `shutdown_request` (via SendMessage) to each active teammate
2. Wait up to 30 seconds for shutdown responses
3. Call `TeamDelete` to remove team

If TeamDelete fails (active members not yet deregistered), wait 5 seconds and retry once.

### Phase 7: Exit

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
- The super-orchestrator handles wave advancement, failure recovery, and user interaction
