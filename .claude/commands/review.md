# Code Review

Review implementation for quality and correctness.

## Prerequisites
- Implementation must be complete with passing tests

## Steps

1. Verify implementation state:
   ```bash
   npm run test
   ```
   - If tests failing, instruct user to run `/implement` first

2. Identify changed files:
   ```bash
   git diff --name-only
   ```

3. Load review context:
   - Implementation plan
   - Changed files
   - Project standards from `/_docs/best-practices.md`

4. Spawn `code-reviewer` subagent:
   - Provide implementation plan
   - Provide changed file paths
   - Provide quality standards

5. Present review findings:
   ```
   ## Code Review: [Task ID]
   
   **Verdict**: [approve/request-changes]
   
   ### Blocking Issues
   [list or "None"]
   
   ### Non-Blocking Issues
   [list or "None"]
   
   ### Suggestions
   [list or "None"]
   ```

6. On approval:
   - Recommend: "Run `/commit` to commit changes."

7. On request-changes:
   - List required fixes
   - Recommend: "Address blocking issues, then run `/review` again."
   - Return to `/implement` if code changes needed
