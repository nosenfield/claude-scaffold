# Write Tests

Write tests for the planned task before implementation.

## Prerequisites
- Implementation plan must be approved (run `/plan` first)

## Steps

1. Verify plan exists:
   - If no approved plan in context, instruct user to run `/plan`

2. Load test context:
   - Implementation plan with test scenarios
   - Existing test patterns from codebase
   - Test conventions from `/_docs/best-practices.md`

3. Spawn `test-writer` subagent:
   - Provide implementation plan
   - Provide test scenarios
   - Provide existing test patterns

4. Verify test creation:
   ```bash
   npm run test -- --testPathPattern="[new test files]"
   ```

5. Confirm tests fail appropriately:
   - Tests should fail because implementation doesn't exist
   - Tests should NOT fail due to syntax errors or missing imports

6. Report test status:
   - **Tests Created**: [list of files]
   - **Test Count**: [number]
   - **Status**: [failing as expected / errors found]

7. On success:
   - Recommend: "Run `/implement` to write code that passes these tests."

8. On errors:
   - Display error details
   - Fix test setup issues before proceeding
