# Plan Task Implementation

Generate an implementation plan for the current in-progress task.

## Prerequisites

A task must be in-progress. If not, run `/next` first.

## Steps

1. **Identify Current Task**
   Read `/_docs/task-list.json`.
   Find the task with `status: "in-progress"`.
   If none found, stop and instruct user to run `/next`.

2. **Prepare Handoff Payload**
   Extract from the task:
   ```
   taskId: [task.id]
   taskTitle: [task.title]
   taskDescription: [task.description]
   acceptanceCriteria: [task.acceptanceCriteria]
   ```

3. **Spawn task-planner Subagent**
   Invoke the `task-planner` agent with the payload.
   
   The subagent will:
   - Read architecture and best practices
   - Explore the codebase
   - Return a structured implementation plan

4. **Receive and Validate Plan**
   Confirm the plan includes:
   - Affected files list
   - Implementation steps
   - Test scenarios
   - Risk assessment

5. **Present Plan for Approval**
   Display the complete implementation plan.
   
   ```
   ## Implementation Plan Ready

   [Display full plan from subagent]

   ---
   
   **Approve this plan?**
   - Reply "approve" to proceed to test writing
   - Reply with feedback to request plan changes
   ```

6. **Store Plan**
   On approval, retain the implementation plan for subsequent stages.
   
   Recommend next action:
   ```
   Plan approved. Run `/test` to write tests.
   ```

## State Management

Store in session context:
- `currentTask`: Full task object
- `implementationPlan`: Approved plan from subagent
