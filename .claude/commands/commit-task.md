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

2. **Check for Worktree Context**

   ```bash
   if [[ "$PWD" == *"/.claude/worktrees/"* ]]; then
     IN_WORKTREE=true
   fi
   ```

   **If in worktree**: Skip steps 3-4. Memory files in the worktree are stale. The orchestrator's conversation context carries all task details. Memory update happens after `/worktree-cleanup` returns to the main tree. Go to step 5.

   **If not in worktree**: Continue to step 3.

3. **Prepare Memory Update Payload**
   ```
   taskId: [currentTask.id]
   taskTitle: [currentTask.title]
   status: "complete"
   commitSha: [from commit result]
   filesModified: [filesCommitted with descriptions]
   decisions: [accumulated decisions from implementation]
   notes: [any additional context]
   ```

4. **Spawn memory-updater Subagent**
   Invoke the `memory-updater` agent with the payload.

   The subagent will:
   - Append entry to _docs/memory/progress.md
   - Append decisions to _docs/memory/decisions.md
   - Update task status in task-list.json
   - Amend the commit to include task-list.json update (task-list workflow only)

   **Note:** For task-list workflow, the commit will be amended with `--no-verify` to include the task-list.json update. This ensures task completion tracking travels with the work itself. The final SHA (post-amend) will be reported.

5. **Receive Update Confirmation**
   If not in worktree: confirm memory bank files were updated.
   If in worktree: skip (memory update deferred).

6. **Clear Session Context**
   Remove task-specific state:
   - `currentTask`
   - `implementationPlan`
   - `testFiles`
   - `filesModified`
   - `decisions`
   - `reviewFeedback`
   - `previousReviewIssues`

7. **Report Completion**

   **Standard (not in worktree)**:
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

   **Worktree**:
   ```
   ## Task Committed (Worktree)

   **Task**: [taskTitle]
   **Commit**: [SHA]
   **Branch**: [worktree branch name]
   **Status**: Committed to worktree branch

   Memory update deferred -- will persist after `/worktree-cleanup`.

   ---

   Continue working, or run `/worktree-cleanup` to merge and update memory.
   ```

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
