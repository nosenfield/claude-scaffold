# Review Implementation

Perform code review on the current task implementation.

## Prerequisites

- Implementation must be complete
- All tests must be passing

If tests aren't passing, run `/implement` first.

## Steps

1. **Verify Prerequisites**
   Confirm session context contains:
   - `currentTask`: The in-progress task
   - `implementationPlan`: The approved plan
   - `filesModified`: List of changed files
   
   Run tests to confirm passing:
   ```bash
   npm run test
   ```
   If tests fail, stop and instruct user to run `/implement`.

2. **Determine Review Type**
   Check session context for `previousReviewIssues`:
   - If absent: `isReReview = false`
   - If present: `isReReview = true`

3. **Prepare Handoff Payload**
   
   For initial review:
   ```
   taskId: [currentTask.id]
   taskTitle: [currentTask.title]
   implementationPlan: [full plan with expected behavior]
   filesModified: [list of changed file paths]
   isReReview: false
   ```
   
   For re-review:
   ```
   taskId: [currentTask.id]
   taskTitle: [currentTask.title]
   implementationPlan: [full plan]
   filesModified: [list of changed file paths]
   isReReview: true
   previousIssues: [blocking issues from last review]
   ```

4. **Spawn code-reviewer Subagent**
   Invoke the `code-reviewer` agent with the payload.
   
   The subagent will:
   - Read all modified files
   - Compare against plan and standards
   - Apply review checklist
   - Return structured review

5. **Receive Review Results**
   Confirm the response includes:
   - Verdict (APPROVE or REQUEST_CHANGES)
   - Blocking issues (if any)
   - Non-blocking issues
   - Checklist results

6. **Handle Review Verdict**

   **If APPROVE with no non-blocking issues:**
   ```
   ## Code Review: APPROVED

   [Display review summary]

   ---

   Implementation approved. Run `/commit` to finalize.
   ```

   **If APPROVE with non-blocking issues:**
   ```
   ## Code Review: APPROVED

   [Display review summary]

   ### Non-Blocking Recommendations

   | # | Issue | Category | Effort | Recommendation |
   |---|-------|----------|--------|----------------|
   | 1 | [description] | [category] | [effort] | [address/defer] |
   | 2 | [description] | [category] | [effort] | [address/defer] |

   ---

   **Choose how to handle these recommendations:**
   - Enter issue numbers to address now (e.g., "1, 3"): loops back to `/implement`
   - Enter "defer all": logs all to backlog, proceeds to `/commit`
   - Enter "skip": proceeds to `/commit` without logging
   - Enter specific numbers to defer (e.g., "defer 2, 3"): logs selected, addresses rest
   ```

   Process user response:
   
   - **Address now**: 
     - Set `reviewFeedback` to selected issues
     - Instruct user to run `/implement`
   
   - **Defer**:
     - Append selected issues to `/_docs/backlog.json`:
       ```json
       {
         "id": "BACKLOG-[next]",
         "sourceTask": "[currentTask.id]",
         "category": "[issue.category]",
         "description": "[issue.description]",
         "file": "[issue.file]",
         "line": "[issue.line]",
         "effort": "[issue.effort]",
         "createdAt": "[ISO timestamp]"
       }
       ```
     - Report items logged
     - If remaining items to address: set `reviewFeedback`, run `/implement`
     - If no remaining items: proceed to `/commit`
   
   - **Skip**:
     - Proceed directly to `/commit`

   **If REQUEST_CHANGES:**
   ```
   ## Code Review: Changes Requested

   [Display blocking issues with file:line references]

   ### Required Fixes
   1. [issue]: [suggestion]
   2. [issue]: [suggestion]

   ---

   Address the blocking issues. Run `/implement` to apply fixes, then `/review` again.
   ```
   Store blocking issues:
   - `reviewFeedback`: List of blocking issues
   - `previousReviewIssues`: Same list (for re-review tracking)

## State Management

Session context after APPROVE (no non-blocking or skipped):
- Ready for `/commit`
- `reviewFeedback` cleared

Session context after APPROVE (addressing non-blocking):
- `reviewFeedback`: Selected non-blocking issues to address
- Returns to `/implement` flow

Session context after REQUEST_CHANGES:
- `reviewFeedback`: Blocking issues for implementer
- `previousReviewIssues`: Issues to verify on re-review
