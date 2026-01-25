# Start Development Session

Start or resume a development session.

## Steps

1. Confirm working directory:
   ```bash
   pwd
   ```

2. Load session context:
   - Read `progress.md` for previous session summary
   - Read `/_docs/task-list.json` for current task status

3. Check git status:
   ```bash
   git status
   git log --oneline -5
   ```

4. Run environment setup:
   ```bash
   npm install
   npm run build
   ```

5. Verify working state:
   ```bash
   npm run test
   ```

6. Report session status:
   - **Last Session**: [summary from progress.md]
   - **Current Branch**: [git branch]
   - **Uncommitted Changes**: [yes/no]
   - **Tasks Completed**: [count]
   - **Tasks Remaining**: [count]
   - **Build Status**: [success/failure]
   - **Test Status**: [passing/failing]

7. Recommend next action:
   - If tests failing: "Address failing tests before new work"
   - If uncommitted changes: "Review and commit pending changes"
   - Otherwise: "Run `/next` to select next task"
