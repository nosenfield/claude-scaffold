# Commit Implementation

Commit code changes and return result. Does not update memory files.

Used by teammates in batch workflow, or internally by `/commit-task`.

## Prerequisites

- Implementation must be complete
- Code review must be approved
- All tests must be passing

## Input

From session context:
- `currentTask`: Task object (id, title)
- `filesModified`: List of modified files

## Steps

1. **Verify Prerequisites**
   Confirm:
   - Tests pass: `npm run test`
   - Lint passes: `npm run lint`
   - Types check: `npm run typecheck`

   **If lint/typecheck fails**:
   - Spawn `implementer` subagent with mode: ADDRESS_LINT_ERRORS
   - Provide lintErrors: [error output]
   - Re-verify: `npm run lint && npm run typecheck`
   - If still failing, return error result

   **If tests fail**: Return error result.

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
   - taskId: task identifier (if present)

   Example: `feat(auth): implement login endpoint (TASK-001)`

4. **Execute Commit**
   ```bash
   git commit -m "[generated message]"
   ```
   Capture the commit SHA.

5. **Return Result**

   On success:
   ```
   COMMIT_SUCCESS
   taskId: [currentTask.id or null]
   taskTitle: [currentTask.title]
   commitSha: [SHA]
   commitMessage: [generated message]
   filesCommitted:
     - [file1]: [description]
     - [file2]: [description]
   ```

   On failure:
   ```
   COMMIT_FAILED
   taskId: [currentTask.id or null]
   taskTitle: [currentTask.title]
   phase: [verification|staging|commit]
   error: [error description]
   details: [error output]
   ```

## Notes

- This command does NOT update memory files
- This command does NOT spawn memory-updater
- For single-task workflow, use `/commit-task` which calls this internally
- For batch workflow, teammates use this directly and return result to orchestrator
