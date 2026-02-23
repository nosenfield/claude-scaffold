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
