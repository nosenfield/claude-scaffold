# Initialize Project

Set up project environment and memory bank for development.

## Prerequisites

Verify core documentation exists:
- `/_docs/prd.md`
- `/_docs/architecture.md`
- `/_docs/task-list.json`
- `/_docs/best-practices.md`

If any are missing, stop and report which files are required.

## Steps

1. **Validate Core Documentation**
   ```bash
   ls -la _docs/
   ```
   Confirm all four files exist and are non-empty.

2. **Parse Task List**
   Read `/_docs/task-list.json` and validate JSON structure.
   Confirm it contains a `tasks` array with at least one task.

3. **Run Environment Setup**
   Read `/_docs/architecture.md` for setup commands.
   Execute the documented setup steps:
   ```bash
   npm install
   ```

4. **Verify Working State**
   Run basic validation:
   ```bash
   npm run build
   npm run test
   ```
   If either fails, report the error and stop.

5. **Initialize Memory Bank**
   Create `progress.md` if it doesn't exist:
   ```markdown
   # Progress Log

   ## [TIMESTAMP] - Project Initialized

   **Status**: Environment ready

   **Core Documentation**:
   - prd.md: Present
   - architecture.md: Present
   - task-list.json: Present ([N] tasks)
   - best-practices.md: Present

   **Environment**: Verified (build and tests pass)

   ---
   ```

   Create `decisions.md` if it doesn't exist:
   ```markdown
   # Decision Log

   Architecture and implementation decisions are recorded here.

   ---
   ```

   Create `/_docs/backlog.json` if it doesn't exist:
   ```json
   {
     "items": []
   }
   ```

6. **Report Status**
   Summarize:
   - Core documentation status
   - Environment setup result
   - Number of tasks in task list
   - Number of tasks pending vs complete
   - Recommended next action: `/dev` to start development session
