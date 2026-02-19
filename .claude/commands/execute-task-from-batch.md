# Execute Task from Batch

Execute a single task as a teammate in batch workflow. Returns structured result to orchestrator.

Used by teammates spawned from `/batch-execute-task-auto`.

## Overview

This command executes the development cycle for an assigned task:
0. Load project context
1. Plan implementation (`/plan-task`)
2. Write tests (`/write-task-tests`)
3. Implement (`/implement-task`)
4. Review (`/review-task`)
5. Commit (`/commit-implementation`)
6. Return structured result to orchestrator

**Does NOT**: Select task (assigned by orchestrator), update memory (orchestrator handles), modify task-list.json.

## Input

Task assigned by orchestrator:
```
taskId: TASK-003
title: Add auth middleware
description: [full description]
acceptanceCriteria:
  - [criterion 1]
  - [criterion 2]
references:
  - [doc path 1]
filesTouched:
  - src/middleware/auth.ts
  - src/types/auth.ts
```

Set `currentTask` in session context from input.

## Workflow

### Phase 0: Load Project Context

Read the following files to establish project awareness before starting work:

1. **`_docs/architecture.md`** -- project structure, tech stack, component boundaries
2. **`_docs/memory/decisions.md`** -- architectural decisions to respect (do not contradict these)
3. **Each file in the task's `references` array** -- design constraints specific to this task

This replaces the `/dev` session start used in the single-task workflow. Teammates do not need session management but do need project context.

### Phase 1: Planning

Execute `/plan-task` to generate an implementation plan.

**Auto-approve the plan and proceed.**

### Phase 2: Test Writing

Execute `/write-task-tests` to create failing tests.

Verify tests fail for expected reasons (no implementation yet).

### Phase 3: Implementation

Execute `/implement-task` to make tests pass.

Verify all tests pass before proceeding.

### Phase 4: Code Review

Execute `/review-task` to perform code review.

**If APPROVE with no issues**: Continue to Phase 5.

**If APPROVE with non-blocking issues**:
Apply auto-triage rules:
- **Low effort issues**: Address now (loop back to Phase 3)
- **Medium/High effort issues**: Add to `backlog` field in result message

Max 3 review-fix loops to prevent infinite cycles.

**If REQUEST_CHANGES**:
- Loop back to Phase 3 to address blocking issues
- After implementation, return to Phase 4 for re-review
- Max 3 review-fix loops

### Phase 5: Commit

Execute `/commit-implementation` to commit code changes.

**If COMMIT_FAILED**: Return failure result.

**If COMMIT_SUCCESS**: Continue to Phase 6.

### Phase 6: Return Result

Send structured result to orchestrator using the **SendMessage tool**. You MUST call this tool before finishing, whether the task succeeded or failed.

**On success** -- call the SendMessage tool:
```
type: "message"
recipient: "team-lead"
summary: "[currentTask.id] complete"
content: |
  TASK_COMPLETE
  taskId: [currentTask.id]
  taskTitle: [currentTask.title]
  commitSha: [from commit result]
  commitMessage: [from commit result]
  result:
    status: success
    summary: [1-2 sentence description of what was implemented]
    filesModified:
      - [file1]
      - [file2]
    blockers: []
  decisions:
    - [decision 1]
    - [decision 2]
  backlog:
    - [any deferred non-blocking issues from code review, or bugs/tech debt discovered during implementation -- or empty]
  testsWritten: [count]
  reviewVerdict: [APPROVE]
```

**On failure** -- call the SendMessage tool:
```
type: "message"
recipient: "team-lead"
summary: "[currentTask.id] failed at [phase]"
content: |
  TASK_FAILED
  taskId: [currentTask.id]
  taskTitle: [currentTask.title]
  phase: [planning|testing|implementation|review|commit]
  result:
    status: failure
    summary: [why it failed - 1-2 sentences]
    filesModified:
      - [any partial work]
    blockers:
      - [issue 1]
      - [issue 2]
  partialWork:
    testsWritten: [count or 0]
    filesModified: [list or empty]
```

## Result Object Schema

The `result` object is consumed by memory-updater:

```json
{
  "status": "success | failure",
  "summary": "Brief description of outcome",
  "filesModified": ["actual files changed"],
  "blockers": ["issues preventing completion (empty on success)"]
}
```

- **Success**: `status: "success"`, `blockers: []`
- **Failure**: `status: "failure"`, `blockers` lists specific issues

## Autonomous Behavior

This workflow proceeds automatically without pausing for input:

1. **Plan approval**: Auto-approved
2. **Non-blocking issues**: Auto-triaged by effort level
3. **Memory updates**: Skipped (orchestrator handles)
4. **Result format**: Structured for machine consumption

## Scope Validation

Before completing, verify file scope:

```
expected = currentTask.filesTouched
actual = result.filesModified

if actual contains files not in expected:
    add warning to result:
    "Modified files outside expected scope: [files]"
```

This warning helps the orchestrator detect potential contention drift.

## Error Handling

| Error | Action | Max Retries |
|-------|--------|-------------|
| Lint/Typecheck | Spawn implementer with ADDRESS_LINT_ERRORS mode | 1 |
| Test failures | Attempt fix | 2 |
| Review REQUEST_CHANGES | Loop back to implementation | 3 |

If retries exhausted, return TASK_FAILED with specific blockers.

## Notes

- This command is for batch workflow only
- Task is assigned by orchestrator, not selected from task-list.json
- Memory updates are handled by orchestrator after batch completes
- Result MUST be sent via `SendMessage` tool with `recipient: "team-lead"` before finishing
- Session context is cleared after returning result
- Always return structured `result` object for machine consumption
