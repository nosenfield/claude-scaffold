# Write Tests

Generate tests for the current task before implementation.

## Prerequisites

- A task must be in-progress
- An implementation plan must be approved

If no plan exists, run `/plan-task` first.

## Steps

1. **Verify Prerequisites**
   Confirm session context contains:
   - `currentTask`: The in-progress task
   - `implementationPlan`: The approved plan

   If missing, instruct user to run `/plan-task` first.

2. **Enable Test-Writing Mode**
   Create marker file to allow test file modifications:
   ```bash
   # Use agent-specific marker for batch-safe execution
   # Falls back to generic marker if CLAUDE_AGENT_ID not available
   touch ".claude/.test-writing-mode${CLAUDE_AGENT_ID:+-$CLAUDE_AGENT_ID}"
   ```
   This signals to the test-file-guard hook that test writes are permitted.
   Agent-specific markers prevent race conditions when multiple teammates write tests concurrently.

3. **Prepare Handoff Payload**
   ```
   taskId: [currentTask.id]
   taskTitle: [currentTask.title]
   implementationPlan: [full plan including affected files and test scenarios]
   acceptanceCriteria: [currentTask.acceptanceCriteria]
   ```

4. **Spawn test-writer Subagent**
   Invoke the `test-writer` agent with the payload.
   
   The subagent will:
   - Explore existing test patterns
   - Create test files with failing tests
   - Verify tests fail for expected reasons

5. **Receive Test Results**
   Confirm the response includes:
   - List of created test files
   - Test count
   - Coverage summary
   - Verification that tests fail (no implementation yet)

6. **Disable Test-Writing Mode**
   Remove marker file to re-enable test protection:
   ```bash
   # Remove agent-specific marker (or generic if no agent ID)
   rm -f ".claude/.test-writing-mode${CLAUDE_AGENT_ID:+-$CLAUDE_AGENT_ID}"
   ```
   This ensures tests cannot be modified during implementation.

7. **Validate Test Creation**
   Run the test suite to confirm tests exist and fail:
   ```bash
   npm run test
   ```
   
   Expected: Tests fail because implementation doesn't exist.

8. **Present Test Summary**
   ```
   ## Tests Created

   [Display test summary from subagent]

   **Test Execution**: [X] failing (expected - no implementation yet)

   ---

   Tests define the acceptance criteria. Run `/implement-task` to make them pass.
   ```

9. **Store Test Information**
   Add to session context:
   - `testFiles`: List of created test file paths

## State Management

Session context after this stage:
- `currentTask`: Full task object
- `implementationPlan`: Approved plan
- `testFiles`: List of test file paths
