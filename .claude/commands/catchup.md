# Catchup

Read recent changes and summarize current project state.

## Steps

1. Read git history:
   ```bash
   git log --oneline -10
   git diff --stat HEAD~5..HEAD
   ```

2. Read memory bank:
   - `progress.md`: recent session entries
   - `decisions.md`: recent decisions

3. Read task status:
   - `/_docs/task-list.json`: completion statistics

4. Summarize current state:

   ```
   ## Project Status
   
   ### Recent Activity
   - Last commit: [date] - [message]
   - Recent sessions: [count from progress.md]
   
   ### Task Progress
   - Complete: [X] / [total]
   - In Progress: [task id if any]
   - Blocked: [count]
   - Pending: [count]
   
   ### Recent Decisions
   [list from decisions.md]
   
   ### Modified Areas
   [summary of recently changed files/modules]
   ```

5. Identify next steps:
   - If task in progress: "Continue with `/plan` or `/implement`"
   - If clean slate: "Run `/next` to select next task"
   - If issues detected: "Address [specific issue] first"
