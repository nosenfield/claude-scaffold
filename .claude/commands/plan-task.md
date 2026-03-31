# Plan Task Implementation

Generate an implementation plan for a task.

## Usage

```
/plan-task                          # Task-list mode: uses in-progress task from session context
/plan-task Add dark mode support    # Ad-hoc mode: uses argument as task description
```

## Steps

1. **Determine Task Source**

   **If `$ARGUMENTS` is provided** (ad-hoc mode):
   - Use the argument text as both `taskTitle` and `taskDescription`
   - No `taskId`, `acceptanceCriteria`, or `references` (task-planner treats these as optional)
   - Continue to step 2

   **If no `$ARGUMENTS`** (task-list mode):
   - Use the in-progress task from session context (set by `/next-from-task-list`)
   - If no task is in session context, stop and instruct user:
     ```
     No task in session context. Either:
     - Run `/next-from-task-list` to select a task, or
     - Run `/plan-task <description>` for ad-hoc planning
     ```

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

   **Task-list mode** (from session context):
   ```
   taskId: [task.id]
   taskTitle: [task.title]
   taskDescription: [task.description]
   acceptanceCriteria: [task.acceptanceCriteria]
   references: [task.references]
   explorationArtifact: [path to exploration artifact from /map]
   ```

   **Ad-hoc mode** (from $ARGUMENTS):
   ```
   taskTitle: [argument text]
   taskDescription: [argument text]
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
   - Tests Required field (yes/no)
   - Test scenarios (when tests required)
   - Risk assessment

7. **Proof the Plan**

   Spawn the `plan-proofer` agent with:
   ```
   taskTitle: [from step 1]
   taskDescription: [from step 1]
   acceptanceCriteria: [from step 1, if available]
   implementationPlan: [full plan text from step 5]
   explorationArtifact: [path from step 3]
   ```

   The proofer independently verifies file existence, internal consistency,
   criteria coverage, step ordering, and scope alignment.

   **If APPROVE**: Proceed to step 8.

   **If REQUEST_REVISION**: Re-spawn the `task-planner` with the original
   payload plus an additional field:
   ```
   prooferFeedback: [Revisions Needed section from proofer output]
   ```
   Run the proofer again on the revised plan. Regardless of the second
   verdict, proceed to step 8 with the latest plan and proof attached.
   (Max one retry -- no infinite loops.)

8. **Present Plan for Approval**
   Display the complete implementation plan.

   **If proofer approved (no issues):**
   ```
   ## Implementation Plan Ready

   [Display full plan from subagent]

   Plan verified by proofer (no issues).

   ---

   **Approve this plan?**
   - Reply "approve" to proceed
   - Reply with feedback to request plan changes
   ```

   **If proofer found issues (first or second pass):**
   ```
   ## Implementation Plan Ready

   [Display full plan from subagent]

   ---

   ## Proofer Findings

   [Display proof output]

   ---

   **Approve this plan?**
   - Reply "approve" to proceed
   - Reply with feedback to request plan changes
   ```

9. **Route Next Action**
   On approval, retain the implementation plan in session context.

   **If plan includes `Tests Required: yes`:**
   Invoke `/write-task-tests` to write tests before implementation.

   **If plan includes `Tests Required: no`:**
   Invoke `/implement-task` directly (skip test writing phase).

   Do NOT implement directly without invoking the appropriate command.
   The commands provide subagent isolation (test-writer, implementer agents).

## State Management

Store in session context:
- `currentTask`: Full task object (task-list mode) or `{ title: $ARGUMENTS, description: $ARGUMENTS }` (ad-hoc mode)
- `explorationArtifact`: Path to exploration artifact
- `implementationPlan`: Approved plan from subagent (includes Tests Required field used for routing)
