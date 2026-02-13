# Commit Task

Commit completed work and update the memory bank.

Composes `/commit-implementation` with memory update.

## Prerequisites

- Implementation must be complete
- Code review must be approved
- All tests must be passing

If review isn't approved, run `/review-task` first.

## Steps

1. **Execute Commit Implementation**
   Run `/commit-implementation`.

   **If COMMIT_FAILED**: Stop and report the error.

   **If COMMIT_SUCCESS**: Continue with result:
   ```
   taskId: [from result]
   taskTitle: [from result]
   commitSha: [from result]
   filesCommitted: [from result]
   ```

2. **Prepare Memory Update Payload**
   ```
   taskId: [currentTask.id]
   taskTitle: [currentTask.title]
   status: "complete"
   commitSha: [from commit result]
   filesModified: [filesCommitted with descriptions]
   decisions: [accumulated decisions from implementation]
   notes: [any additional context]
   ```

3. **Spawn memory-updater Subagent**
   Invoke the `memory-updater` agent with the payload.

   The subagent will:
   - Append entry to _docs/memory/progress.md
   - Append decisions to _docs/memory/decisions.md
   - Update task status in task-list.json
   - Amend the commit to include task-list.json update (task-list workflow only)

   **Note:** For task-list workflow, the commit will be amended with `--no-verify` to include the task-list.json update. This ensures task completion tracking travels with the work itself. The final SHA (post-amend) will be reported.

4. **Receive Update Confirmation**
   Confirm memory bank files were updated.

5. **Clear Session Context**
   Remove task-specific state:
   - `currentTask`
   - `implementationPlan`
   - `testFiles`
   - `filesModified`
   - `decisions`
   - `reviewFeedback`
   - `previousReviewIssues`

6. **Report Completion**
   ```
   ## Task Complete

   **Task**: [taskId] - [taskTitle]
   **Commit**: [SHA] (amended with task-list.json update)
   **Status**: Complete

   ### Memory Bank Updated
   - _docs/memory/progress.md: Entry added
   - _docs/memory/decisions.md: [N] decisions recorded
   - task-list.json: Task marked complete (included in commit)

   ---

   Run `/next-from-task-list` to select the next task, or `/dev` to see project status.
   ```

   For ad-hoc workflow (no taskId), report original SHA without amend note.

## Post-Commit Verification

Optionally verify clean state:
```bash
git status
npm run test
```

## Notes

- This command is for single-task workflow
- For batch workflow, teammates use `/commit-implementation` directly
- Orchestrator handles memory updates for batch workflow
