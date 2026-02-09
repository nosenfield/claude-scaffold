# Commit Task

Commit completed work and update the memory bank.

## Prerequisites

- Implementation must be complete
- Code review must be approved
- All tests must be passing

If review isn't approved, run `/review` first.

## Steps

1. **Verify Prerequisites**
   Confirm:
   - Tests pass: `npm run test`
   - Lint passes: `npm run lint`
   - Types check: `npm run typecheck`
   
   If any fail, stop and report the issue.

2. **Stage Changes**
   ```bash
   git add -A
   git status
   ```
   Review staged files match expected `filesModified`.

3. **Generate Commit Message**
   Format: `<type>(<scope>): <description> (<taskId>)`
   
   Derive from task:
   - type: feat, fix, refactor, docs, test (based on task category)
   - scope: primary module affected
   - description: task title (lowercase, imperative)
   - taskId: task identifier
   
   Example: `feat(auth): implement login endpoint (TASK-001)`

4. **Execute Commit**
   ```bash
   git commit -m "[generated message]"
   ```
   Capture the commit SHA.

5. **Prepare Memory Update Payload**
   ```
   taskId: [currentTask.id]
   taskTitle: [currentTask.title]
   status: "complete"
   commitSha: [captured SHA]
   filesModified: [list with descriptions]
   decisions: [accumulated decisions from implementation]
   notes: [any additional context]
   ```

6. **Spawn memory-updater Subagent**
   Invoke the `memory-updater` agent with the payload.
   
   The subagent will:
   - Append entry to _docs/memory/progress.md
   - Append decisions to _docs/memory/decisions.md
   - Update task status in task-list.json

7. **Receive Update Confirmation**
   Confirm memory bank files were updated.

8. **Clear Session Context**
   Remove task-specific state:
   - `currentTask`
   - `implementationPlan`
   - `testFiles`
   - `filesModified`
   - `decisions`
   - `reviewFeedback`
   - `previousReviewIssues`

9. **Report Completion**
   ```
   ## Task Complete

   **Task**: [taskId] - [taskTitle]
   **Commit**: [SHA]
   **Status**: Complete

   ### Memory Bank Updated
   - _docs/memory/progress.md: Entry added
   - _docs/memory/decisions.md: [N] decisions recorded
   - task-list.json: Task marked complete

   ---

   Run `/next` to select the next task, or `/dev` to see project status.
   ```

## Post-Commit Verification

Optionally verify clean state:
```bash
git status
npm run test
```
