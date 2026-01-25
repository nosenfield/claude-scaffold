# Select Next Task

Select and display the next task to implement.

## Steps

1. Read `/_docs/task-list.json`

2. Filter tasks:
   - Status is `"pending"` or `"in-progress"`
   - No unmet dependencies (all `blockedBy` tasks are `"complete"`)

3. Sort by priority:
   - Primary: `priority` field (ascending, 1 is highest)
   - Secondary: `id` field (ascending)

4. Select first available task

5. Display task details:
   - **Task ID**: [id]
   - **Priority**: [priority]
   - **Category**: [category]
   - **Description**: [description]
   - **Acceptance Criteria**: [steps]
   - **Dependencies**: [blockedBy]

6. Update task status to `"in-progress"` in task-list.json

7. Recommend next action:
   ```
   Run `/plan` to create implementation plan for this task.
   ```

## If No Tasks Available

Report completion status:
- All tasks complete: "Project complete. All tasks finished."
- Blocked tasks exist: "Remaining tasks are blocked. Review dependencies."
