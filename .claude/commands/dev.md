# Start Development Session

Resume development workflow and establish session context.

## Steps

1. **Confirm Working Directory**
   ```bash
   pwd
   ```
   Verify you are in the project root.

2. **Load Previous Context**
   Read `progress.md` to understand:
   - Last completed task
   - Last session summary
   - Any in-progress work

3. **Check Repository State**
   ```bash
   git status
   git log --oneline -5
   ```
   Note any uncommitted changes or recent commits.

4. **Load Task State**
   Read `/_docs/task-list.json`:
   - Count tasks by status (pending, in-progress, complete)
   - Identify any task marked in-progress

5. **Verify Environment**
   Run quick validation:
   ```bash
   npm run build --silent
   npm run test --silent
   ```
   If either fails, report the issue before proceeding.

6. **Report Session Status**
   Summarize:
   - Repository state (clean/dirty)
   - Last completed task
   - Current in-progress task (if any)
   - Next pending task
   - Recommended action:
     - If in-progress task exists: "Continue with `/plan` or `/implement`"
     - If clean state: "Select next task with `/next`"
