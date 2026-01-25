---
paths:
  - "_docs/task-list.json"
  - "**/task-list.json"
---

# Task List Protection Rules

The task list is an immutable contract defining project scope.

## Allowed Modifications
- `status`: May change to `"in-progress"` or `"complete"`
- `completedAt`: May set to ISO 8601 timestamp when completing

## Prohibited Modifications
- NEVER modify `id`, `description`, `priority`, `category`, or `steps`
- NEVER remove tasks from the list
- NEVER add new tasks without explicit user approval
- NEVER reorder tasks

## Rationale
Task definitions represent agreed requirements. Changing them mid-implementation obscures scope changes and breaks traceability.

## If Modification Seems Necessary
Stop and ask the user:
```
The task [ID] may need modification because [reason].
Current: [current value]
Proposed: [proposed change]

Approve this change? (yes/no)
```
