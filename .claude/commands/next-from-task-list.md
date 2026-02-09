# Select Next Task

Identify and select the highest-priority unblocked task.

## Steps

1. **Spawn task-selector Subagent**
   Invoke the `task-selector` agent with prompt: `" "` (single space).

   The subagent will:
   - Read and parse task-list.json
   - Filter for pending, unblocked tasks
   - Sort by priority
   - Update selected task status to in-progress
   - Return selected task or edge case status

2. **Handle Response**

   **If TASK_SELECTED:**
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

   ### References
   [references list or "None"]

   ### Dependencies
   [blockedBy list or "None"]

   ---

   Ready to plan implementation. Run `/plan` to continue.
   ```

   **If NO_PENDING_TASKS:**
   ```
   ## All Tasks Complete

   **Completed**: [N] of [N] tasks

   All tasks in the task list have been completed.
   ```

   **If ALL_TASKS_BLOCKED:**
   ```
   ## All Pending Tasks Blocked

   The following tasks are waiting on dependencies:

   | Task | Blocked By |
   |------|------------|
   | [taskId]: [title] | [blockers] |

   Resolve blocking tasks or update task-list.json to unblock.
   ```

3. **Store Task Context**
   On TASK_SELECTED, retain the task object for subsequent stages:
   - `currentTask`: Full task object from subagent

## State Management

Session context after successful selection:
- `currentTask`: Selected task object (id, title, description, acceptanceCriteria, references)
