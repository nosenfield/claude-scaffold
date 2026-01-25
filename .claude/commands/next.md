# Select Next Task

Identify and display the highest-priority unblocked task.

## Steps

1. **Load Task List**
   Read `/_docs/task-list.json`.

2. **Filter Candidates**
   Select tasks where:
   - `status` is "pending"
   - `blockedBy` array is empty OR all blocking tasks have `status: "complete"`

3. **Sort by Priority**
   Order candidates by `priority` field (lower number = higher priority).

4. **Select Task**
   Choose the first task after sorting.

5. **Display Task Details**
   Present the selected task:

   ```
   ## Next Task

   **ID**: [taskId]
   **Title**: [title]
   **Priority**: [priority]

   ### Description
   [description]

   ### Acceptance Criteria
   - [criterion 1]
   - [criterion 2]
   - [criterion 3]

   ### Dependencies
   [blockedBy list or "None"]
   ```

6. **Update Task Status**
   In `/_docs/task-list.json`, set the selected task's status to "in-progress".

7. **Recommend Next Action**
   ```
   Ready to plan implementation. Run `/plan` to continue.
   ```

## Edge Cases

- **No pending tasks**: Report "All tasks complete" and summarize completion status.
- **All pending tasks blocked**: List blocked tasks and their blockers.
