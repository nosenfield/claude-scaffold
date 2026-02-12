# Execute Task (Autonomous)

Autonomously execute the full development workflow for a single task from the task list without user interaction.

## Overview

This command orchestrates the complete development cycle:
1. Select next task (`/next-from-task-list`)
2. Plan implementation (`/plan-task`)
3. Write tests (`/write-task-tests`)
4. Implement (`/implement-task`)
5. Review (`/review-task`)
6. Commit (`/commit-task`)

## Prerequisites

- Repository must be initialized (run `/init-repo` first if not)
- `task-list.json` must contain pending tasks

## Workflow

### Phase 1: Task Selection

Execute `/next-from-task-list` to select the highest-priority unblocked task.

**If NO_PENDING_TASKS**: Report completion and stop.
**If ALL_TASKS_BLOCKED**: Report blocked state and stop.
**If TASK_SELECTED**: Continue to Phase 2.

### Phase 2: Planning

Execute `/plan-task` to generate an implementation plan.

**Auto-approve the plan and proceed to Phase 3.**

Log acceptance:
```
## Plan Auto-Approved

**Task**: [taskId] - [taskTitle]

Proceeding to test writing...
```

### Phase 3: Test Writing

Execute `/write-task-tests` to create failing tests.

Verify tests fail for expected reasons (no implementation yet).

### Phase 4: Implementation

Execute `/implement-task` to make tests pass.

Verify all tests pass before proceeding.

### Phase 5: Code Review

Execute `/review-task` to perform code review.

**If APPROVE with no issues**: Continue to Phase 6.

**If APPROVE with non-blocking issues**:
Apply auto-triage rules:
- **Low effort issues**: Address now (loop back to Phase 4)
- **Medium/High effort issues**: Defer to backlog

If any issues are addressed: loop back to Phase 4 with feedback, then re-review.
If all issues are deferred: log to backlog, continue to Phase 6.

Max 3 review-fix loops to prevent infinite cycles.

**If REQUEST_CHANGES**:
- Set review feedback in context
- Loop back to Phase 4 to address blocking issues
- After implementation, return to Phase 5 for re-review
- Max 3 review-fix loops to prevent infinite cycles

### Phase 6: Commit

Execute `/commit-task` to commit changes and update memory.

### Completion

Report task completion:

```
## Task Execution Complete (Autonomous)

**Task**: [taskId] - [taskTitle]
**Commit**: [SHA]
**Status**: Complete

### Workflow Summary
- Plan: Auto-approved
- Tests: [N] written, all failing initially
- Implementation: All tests passing
- Review: [verdict]
- Memory: Updated

---

Run `/execute-task-auto` again for the next task, or `/dev` to see project status.
```

## Autonomous Behavior

This workflow proceeds automatically without pausing for user input:

1. **Plan approval** (Phase 2): Auto-approved
2. **Non-blocking issues** (Phase 5): Auto-triaged by effort level

All other phases execute autonomously (same as `/execute-task`).

## Error Handling

### Lint/Typecheck Failures (Pre-Commit)

Delegate to implementer subagent:
- Spawn `implementer` with mode: ADDRESS_LINT_ERRORS
- Provide lintErrors: [error output from lint/typecheck]
- Re-verify: `npm run lint && npm run typecheck`
- If successful, continue to commit
- If still failing after fix attempt, stop and report

### Other Failures

If tests fail or implementation encounters runtime errors:
1. Report the failure with details
2. Stop execution
3. Preserve session context for manual intervention

User can resume with:
- `/plan-task` to revise planning
- `/implement-task` to retry implementation
- `/review-task` to retry review
- `/commit-task` to retry commit

## Notes

- This command is for automated task-list workflow; use `/execute-task` when human oversight is preferred
- Each execution processes exactly one task
- Review feedback loops are handled automatically within Phase 5 (max 3 loops)
- Session context is cleared after successful commit
