# Implement Task

Write code to pass the tests for the current task.

## Prerequisites

- A task must be in-progress
- An implementation plan must be approved
- Tests must be written

If tests don't exist, run `/test` first.

## Steps

1. **Verify Prerequisites**
   Confirm session context contains:
   - `currentTask`: The in-progress task
   - `implementationPlan`: The approved plan
   - `testFiles`: List of test file paths
   
   If missing, instruct user to run earlier commands.

2. **Determine Mode**
   Check session context for `reviewFeedback`:
   - If absent: `mode = "INITIAL"`
   - If present: `mode = "ADDRESS_REVIEW_FEEDBACK"`

3. **Prepare Handoff Payload**
   
   For INITIAL mode:
   ```
   taskId: [currentTask.id]
   taskTitle: [currentTask.title]
   implementationPlan: [full plan with affected files and steps]
   testFiles: [list of test file paths]
   mode: "INITIAL"
   ```
   
   For ADDRESS_REVIEW_FEEDBACK mode:
   ```
   taskId: [currentTask.id]
   taskTitle: [currentTask.title]
   implementationPlan: [full plan]
   testFiles: [list of test file paths]
   mode: "ADDRESS_REVIEW_FEEDBACK"
   reviewFeedback: [blocking issues from code review]
   ```

4. **Spawn implementer Subagent**
   Invoke the `implementer` agent with the payload.
   
   The subagent will:
   - Read tests to understand expected behavior
   - Implement code incrementally
   - Run tests after each change
   - Report completion status

5. **Receive Implementation Results**
   Confirm the response includes:
   - Files modified
   - Test results (all passing)
   - Decisions made
   - Any deviations from plan

6. **Validate Implementation**
   Run full test suite:
   ```bash
   npm run test
   ```
   
   If tests fail, report failure and allow retry.

7. **Present Implementation Summary**
   ```
   ## Implementation Complete

   [Display summary from subagent]

   **Test Results**: [X] passing, [Y] failing

   ### Decisions Made
   [List decisions for memory bank]

   ---

   Ready for code review. Run `/review` to continue.
   ```

8. **Store Implementation Information**
   Update session context:
   - `filesModified`: List of changed files
   - `decisions`: List of implementation decisions
   - Clear `reviewFeedback` if present

## State Management

Session context after this stage:
- `currentTask`: Full task object
- `implementationPlan`: Approved plan
- `testFiles`: List of test file paths
- `filesModified`: List of changed files
- `decisions`: Implementation decisions for memory bank
