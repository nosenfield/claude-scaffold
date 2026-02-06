---
paths:
  - "_docs/backlog.json"
  - "**/backlog.json"
---

# Backlog Protection Rules

The backlog tracks deferred non-blocking issues from code reviews. It serves as a tech debt registry.

## Structure

```json
{
  "items": [
    {
      "id": "BACKLOG-001",
      "sourceTask": "TASK-001",
      "category": "security|performance|maintainability|convention",
      "description": "Issue description",
      "file": "path/to/file.ts",
      "lineHint": 42,
      "createdAt": "ISO timestamp"
    }
  ]
}
```

## Workflow

When code-reviewer identifies non-blocking issues:
1. Orchestrator presents each suggestion to the user
2. User chooses one of:
   - **Address**: Fix the issue now (blocks task completion)
   - **Defer**: Add to backlog for later resolution
   - **Skip**: Ignore the suggestion (not recorded)
3. Deferred items are appended to backlog.json

## Permitted Operations

| Operation | Permitted | Actor |
|-----------|-----------|-------|
| Read backlog | Yes | Any agent |
| Append new item | Yes | Orchestrator (when user chooses "defer") |
| Delete resolved item | Yes | User or orchestrator when addressed |
| Modify item details | No | User only (manual edit) |

## ID Generation

New items receive sequential IDs:
1. Read existing items
2. Find highest BACKLOG-NNN number
3. Assign BACKLOG-(NNN+1)

## Adding Items

When user chooses "defer" for a non-blocking issue:

```json
{
  "id": "BACKLOG-[next]",
  "sourceTask": "[current task ID]",
  "category": "[from code-reviewer]",
  "description": "[from code-reviewer]",
  "file": "[from code-reviewer]",
  "lineHint": "[from code-reviewer]",
  "createdAt": "[current ISO timestamp]"
}
```

## Resolving Items

When a backlog item is addressed, delete it from the items array.

## Backlog Review

Periodically review backlog for:
- Accumulating security issues (should be rare)
- Items that could be batched together
- Items in files scheduled for modification
