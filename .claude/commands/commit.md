# Commit Changes

Commit completed work and update memory bank.

## Prerequisites
- Code review must be approved

## Steps

1. Verify clean state:
   ```bash
   npm run test
   npm run lint
   npm run typecheck
   ```
   - All must pass before committing

2. Stage changes:
   ```bash
   git add -A
   ```

3. Generate commit message:
   - Format: `feat(scope): description`
   - Include task ID in body
   - Reference affected areas

   Example:
   ```
   feat(auth): implement user login flow
   
   Task: TASK-001
   
   - Add login form component
   - Implement authentication service
   - Add session management
   ```

4. Execute commit:
   ```bash
   git commit -m "[message]"
   ```

5. Spawn `memory-updater` subagent:
   - Provide task completion details
   - Provide implementation decisions
   - Update progress.md and decisions.md

6. Mark task complete:
   - Update `/_docs/task-list.json`
   - Set status to `"complete"`
   - Set completedAt to current timestamp

7. Report completion:
   - **Commit**: [hash]
   - **Task**: [id] marked complete
   - **Memory Bank**: updated

8. Recommend next action:
   - "Run `/next` to select next task."
   - Or if session ending: "Run `/dev` to resume later."
