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
      "line": 42,
      "effort": "low|medium|high",
      "createdAt": "ISO timestamp",
      "resolvedAt": null,
      "resolvedBy": null
    }
  ]
}
```

## Permitted Operations

| Operation | Permitted | Actor |
|-----------|-----------|-------|
| Read backlog | Yes | Any agent |
| Append new item | Yes | Orchestrator (via /review defer) |
| Mark item resolved | Yes | User or orchestrator when addressed |
| Modify item details | No | User only (manual edit) |
| Delete item | No | User only (manual edit) |

## ID Generation

New items receive sequential IDs:
1. Read existing items
2. Find highest BACKLOG-NNN number
3. Assign BACKLOG-(NNN+1)

## Adding Items

When deferring non-blocking issues from code review:

```json
{
  "id": "BACKLOG-[next]",
  "sourceTask": "[current task ID]",
  "category": "[from code-reviewer]",
  "description": "[from code-reviewer]",
  "file": "[from code-reviewer]",
  "line": "[from code-reviewer]",
  "effort": "[from code-reviewer]",
  "createdAt": "[current ISO timestamp]",
  "resolvedAt": null,
  "resolvedBy": null
}
```

## Resolving Items

When a backlog item is addressed (manually or via dedicated task):

```json
{
  "resolvedAt": "[current ISO timestamp]",
  "resolvedBy": "[task ID or 'manual']"
}
```

Do NOT remove resolved items. They serve as historical record.

## Backlog Review

Periodically review backlog for:
- Accumulating security issues (should be rare)
- High-effort items that could be batched
- Items in files scheduled for modification
