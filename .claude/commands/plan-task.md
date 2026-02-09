# Plan Task Implementation

Generate an implementation plan for the current in-progress task.

## Prerequisites

A task must be in-progress. If not, run `/next-from-task-list` first.

## Steps

1. **Identify Current Task**
   Use the in-progress task from session context (set by `/next-from-task-list`).
   If no task is in session context, stop and instruct user to run `/next-from-task-list`.

2. **Determine Exploration Target**
   Based on the task, identify what to explore:
   - Feature name or system area from task description
   - Keywords that indicate affected code areas

   Example targets:
   - Task "Add user authentication" → target: "authentication"
   - Task "Fix checkout validation" → target: "checkout validation"

3. **Invoke /map for Exploration**
   Run `/map <target> --depth medium` to create exploration artifact.

   This produces `_docs/maps/{target-slug}.md` with:
   - Entry points
   - Architecture observations
   - Related systems
   - Relevant file paths

4. **Prepare Handoff Payload**
   Extract from the task and exploration:
   ```
   taskId: [task.id]
   taskTitle: [task.title]
   taskDescription: [task.description]
   acceptanceCriteria: [task.acceptanceCriteria]
   references: [task.references]
   explorationArtifact: [path to exploration artifact from /map]
   ```

5. **Spawn task-planner Subagent**
   Invoke the `task-planner` agent with the payload.

   The subagent will:
   - Read the exploration artifact
   - Read architecture and best practices
   - Return a structured implementation plan

6. **Receive and Validate Plan**
   Confirm the plan includes:
   - Affected files list
   - Implementation steps
   - Test scenarios
   - Risk assessment

7. **Present Plan for Approval**
   Display the complete implementation plan.

   ```
   ## Implementation Plan Ready

   [Display full plan from subagent]

   ---

   **Approve this plan?**
   - Reply "approve" to proceed to test writing
   - Reply with feedback to request plan changes
   ```

8. **Store Plan**
   On approval, retain the implementation plan for subsequent stages.

   Recommend next action:
   ```
   Plan approved. Run `/write-task-tests` to write tests.
   ```

## State Management

Store in session context:
- `currentTask`: Full task object
- `explorationArtifact`: Path to exploration artifact
- `implementationPlan`: Approved plan from subagent
