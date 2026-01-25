# Implement Task

Implement code to pass the written tests.

## Prerequisites
- Tests must be written (run `/test` first)
- Tests should be failing (no implementation yet)

## Steps

1. Verify tests exist:
   - If no tests in context, instruct user to run `/test`

2. Load implementation context:
   - Approved implementation plan
   - Test file locations and expectations
   - Architecture constraints from `/_docs/architecture.md`

3. Spawn `implementer` subagent:
   - Provide implementation plan
   - Provide test locations
   - Provide architecture constraints

4. Monitor implementation:
   - Subagent implements incrementally
   - Runs tests after each change
   - Continues until all tests pass

5. Verify completion:
   ```bash
   npm run test
   npm run typecheck
   ```

6. Report implementation status:
   - **Files Modified**: [list]
   - **Tests**: [all passing / X failing]
   - **Type Check**: [pass / errors]

7. On all tests passing:
   - Recommend: "Run `/review` for code review."

8. On failures:
   - Display failing tests
   - Continue implementation or request guidance
