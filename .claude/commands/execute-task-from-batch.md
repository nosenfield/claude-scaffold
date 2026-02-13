# Execute Task from Batch

Execute a single task as a teammate in batch workflow. Returns result to orchestrator.

Used by teammates spawned from `/batch-execute-task-auto`.

## Overview

This command executes the development cycle for an assigned task:
1. Plan implementation (`/plan-task`)
2. Write tests (`/write-task-tests`)
3. Implement (`/implement-task`)
4. Review (`/review-task`)
5. Commit (`/commit-implementation`)
6. Return result to orchestrator

**Does NOT**: Select task (assigned by orchestrator), update memory (orchestrator handles).

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
```

Set `currentTask` in session context from input.

## Workflow

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
- **Medium/High effort issues**: Note in result for orchestrator

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

Send structured result to orchestrator.

**On success**:
```
TASK_COMPLETE
taskId: [currentTask.id]
taskTitle: [currentTask.title]
commitSha: [from commit result]
commitMessage: [from commit result]
filesModified:
  - [file1]: [description]
  - [file2]: [description]
decisions:
  - [decision 1]
  - [decision 2]
testsWritten: [count]
reviewVerdict: [APPROVE]
reviewNotes: [any non-blocking issues deferred]
```

**On failure**:
```
TASK_FAILED
taskId: [currentTask.id]
taskTitle: [currentTask.title]
phase: [planning|testing|implementation|review|commit]
error: [error description]
details: [error output or context]
partialWork:
  testsWritten: [count or 0]
  filesModified: [list or empty]
```

## Autonomous Behavior

This workflow proceeds automatically without pausing for input:

1. **Plan approval**: Auto-approved
2. **Non-blocking issues**: Auto-triaged by effort level
3. **Memory updates**: Skipped (orchestrator handles)

## Error Handling

### Lint/Typecheck Failures (Pre-Commit)

Delegate to implementer subagent:
- Spawn `implementer` with mode: ADDRESS_LINT_ERRORS
- Provide lintErrors: [error output]
- Re-verify
- If still failing, return TASK_FAILED

### Test Failures

If tests fail after implementation:
1. Attempt fix (max 2 retries)
2. If still failing, return TASK_FAILED with details

### Review Loops

Max 3 review-fix iterations. If still REQUEST_CHANGES after 3 loops:
- Return TASK_FAILED with review feedback

## Notes

- This command is for batch workflow only
- Task is assigned by orchestrator, not selected from task-list.json
- Memory updates are handled by orchestrator after batch completes
- Result must be sent to orchestrator (via Agent Teams messaging)
- Session context is cleared after returning result
