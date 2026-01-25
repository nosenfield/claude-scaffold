# Plan Task Implementation

Plan implementation for the current task.

## Steps

1. Identify current task:
   - Read `/_docs/task-list.json`
   - Find task with status `"in-progress"`
   - If none, instruct user to run `/next` first

2. Gather context for planning:
   - Task definition and acceptance criteria
   - Relevant sections from `/_docs/architecture.md`
   - Related code patterns from existing codebase

3. Spawn `task-planner` subagent:
   - Provide task definition
   - Provide architecture context
   - Request implementation plan

4. Review returned plan:
   - Verify steps are concrete and actionable
   - Verify affected files are identified
   - Verify test scenarios cover acceptance criteria

5. Present plan for approval:
   ```
   ## Implementation Plan for [Task ID]
   
   [Plan content from subagent]
   
   ---
   Approve this plan? (yes/no/revise)
   ```

6. On approval:
   - Store plan in working memory
   - Recommend: "Run `/test` to write tests for this plan."

7. On revision request:
   - Gather feedback
   - Re-run planning with additional constraints
