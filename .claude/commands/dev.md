# Start Development Session

Resume development workflow and establish session context.

## Steps

1. **Confirm Working Directory**
   ```bash
   pwd
   ```
   Verify you are in the project root.

2. **Load Memory Files**
   Read in order:
   - `progress.md`: Last session summary, completed tasks, in-progress work
   - `decisions.md`: Architectural decisions, rejected approaches
   - `_docs/task-list.json`: Task statuses, current task

3. **Check Repository State**
   ```bash
   git status
   git log --oneline -5
   ```
   Note uncommitted changes. Git log is verification only; trust memory files as authoritative.

4. **Verify Environment**
   ```bash
   npm run build --silent
   npm run test --silent
   ```
   If either fails, report the issue before proceeding.

5. **Report Session Status**
   Summarize:
   - Repository state (clean/dirty)
   - Last completed task
   - Current in-progress task (if any)
   - Recent decisions relevant to current work
   - Recommended action:
     - If in-progress task exists: "Continue with `/plan` or `/implement`"
     - If clean state: "Select next task with `/next`"
