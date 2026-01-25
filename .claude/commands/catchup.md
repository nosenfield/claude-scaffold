# Catch Up

Summarize recent work and current project state for context recovery.

## Purpose

Use this command when:
- Starting a new session after a break
- Recovering context after `/clear`
- Onboarding to an unfamiliar project state

## Steps

1. **Read Git History**
   ```bash
   git log --oneline -10
   git diff --stat HEAD~5..HEAD
   ```
   Summarize recent commits and changed files.

2. **Read Progress Log**
   Read `progress.md`:
   - Extract last 3-5 entries
   - Identify last completed task
   - Note any in-progress work mentioned

3. **Read Decision Log**
   Read `decisions.md`:
   - Extract recent decisions
   - Note any architectural patterns established

4. **Load Task State**
   Read `/_docs/task-list.json`:
   - Count tasks by status
   - Identify in-progress task (if any)
   - Identify next pending task

5. **Check Working Directory**
   ```bash
   git status
   npm run test --silent 2>&1 | tail -5
   ```
   Report uncommitted changes and test status.

6. **Generate Summary**
   ```
   ## Project Status

   ### Recent Activity
   - Last commit: [SHA] [message] ([date])
   - Last completed task: [taskId] - [title]
   - Recent commits: [count] in last [timeframe]

   ### Task Progress
   - Complete: [N] tasks
   - In Progress: [N] tasks
   - Pending: [N] tasks

   ### Current State
   - Working directory: [clean/dirty]
   - Test status: [passing/failing]
   - In-progress task: [taskId - title OR "None"]

   ### Recent Decisions
   - [decision 1]
   - [decision 2]

   ### Recommended Action
   [Based on state, suggest next command]
   ```

## Context Recovery

If an in-progress task exists, restore session context:
- `currentTask`: Load from task-list.json
- Check for existing test files in expected locations
- Check for implementation files in expected locations

Suggest appropriate resume point:
- No tests yet: `/plan` or `/test`
- Tests exist, failing: `/implement`
- Tests passing: `/review`
- Review approved: `/commit`
