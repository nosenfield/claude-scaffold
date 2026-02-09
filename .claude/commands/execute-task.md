# Execute Task

Autonomously execute the full development workflow for a single task from the task list.

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

Present the plan and wait for user approval:
- "approve" → Continue to Phase 3
- Feedback → Revise plan and re-present

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
- Present recommendations to user
- User chooses: address now, defer, or skip
- If addressing: loop back to Phase 4 with feedback
- If deferring: log to backlog, continue to Phase 6
- If skipping: continue to Phase 6

**If REQUEST_CHANGES**:
- Set review feedback in context
- Loop back to Phase 4 to address blocking issues
- After implementation, return to Phase 5 for re-review

### Phase 6: Commit

Execute `/commit-task` to commit changes and update memory.

### Completion

Report task completion:

```
## Task Execution Complete

**Task**: [taskId] - [taskTitle]
**Commit**: [SHA]
**Status**: Complete

### Workflow Summary
- Plan: Approved
- Tests: [N] written, all failing initially
- Implementation: All tests passing
- Review: Approved
- Memory: Updated

---

Run `/execute-task` again for the next task, or `/dev` to see project status.
```

## User Interaction Points

This workflow pauses for user input at:

1. **Plan approval** (Phase 2): User must approve the implementation plan
2. **Non-blocking issues** (Phase 5): User chooses how to handle recommendations

All other phases execute autonomously.

## Error Handling

If any phase fails:
1. Report the failure with details
2. Stop execution
3. Preserve session context for manual intervention
4. User can fix the issue and resume with the appropriate command:
   - `/plan-task` to revise planning
   - `/implement-task` to retry implementation
   - `/review-task` to retry review

## Notes

- This command is for task-list workflow; ad-hoc work should use individual commands
- Each execution processes exactly one task
- Review feedback loops are handled automatically within Phase 5
- Session context is cleared after successful commit
