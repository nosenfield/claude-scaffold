---
paths:
  - "_docs/task-list.json"
  - "**/task-list.json"
---

# Task List Protection Rules

The task list is the authoritative source for project work items. It must remain stable to ensure reliable progress tracking across sessions.

## Immutable Fields

NEVER modify these fields on any task:
- `id`: Task identifier
- `title`: Task name
- `description`: Task details
- `priority`: Task ordering
- `acceptanceCriteria`: Definition of done
- `references`: Documentation pointers for agent context
- `blockedBy`: Dependency list

## Mutable Fields

ONLY these fields may be modified:
- `status`: One of "pending", "in-progress", "complete"
- `completedAt`: ISO timestamp when status becomes "complete"

## Allowed Operations

| Operation | Permitted | Actor |
|-----------|-----------|-------|
| Read task list | Yes | Any agent |
| Update status field | Yes | Orchestrator, memory-updater |
| Update completedAt field | Yes | memory-updater |
| Add new task | No | User only (manual edit) |
| Remove task | No | User only (manual edit) |
| Modify task details | No | User only (manual edit) |

## Status Transitions

```
pending → in-progress    (via /next-from-task-list command)
in-progress → complete   (via /commit-task command)
in-progress → pending    (only if task is abandoned, requires user approval)
```

## Validation

Before any write to task-list.json:
1. Parse existing JSON
2. Identify changed fields
3. Reject if immutable field modified
4. Reject if status transition invalid
5. Proceed only if changes are permitted
