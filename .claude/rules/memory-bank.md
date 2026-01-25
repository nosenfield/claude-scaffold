---
paths:
  - "progress.md"
  - "decisions.md"
  - "CLAUDE.md"
---

# Memory Bank Rules

Memory bank files provide persistent context across sessions. They must be maintained carefully to preserve project history.

## File Purposes

| File | Purpose | Update Frequency |
|------|---------|------------------|
| progress.md | Session history, completed work | After each task completion |
| decisions.md | Architecture and implementation decisions | When significant decisions made |
| CLAUDE.md | Project context for Claude Code | Rarely, when project structure changes |

## progress.md Rules

**Structure**: Append-only log with newest entries at bottom.

**Entry Format**:
```markdown
## [YYYY-MM-DD HH:MM] - Task [ID]: [Title]

**Status**: [Complete/Partial/Blocked]

**Changes**:
- [file path]: [what changed]

**Outcome**: [one-sentence summary]

---
```

**Operations**:
- APPEND new entries: Yes
- Modify existing entries: No
- Delete entries: No
- Reorder entries: No

## decisions.md Rules

**Structure**: Append-only log of architectural decisions.

**Entry Format**:
```markdown
## [YYYY-MM-DD] - [Decision Title]

**Context**: [why decision was needed]

**Decision**: [what was decided]

**Alternatives Considered**:
- [option]: [why rejected]

**Consequences**: [implications]

---
```

**Operations**:
- APPEND new decisions: Yes
- Modify existing decisions: No (decisions are historical record)
- Delete decisions: No
- Add follow-up notes: Yes (as new entry referencing original)

## CLAUDE.md Rules

**Structure**: Project configuration and context for Claude Code.

**Sections**:
- Project overview
- Commands (build, test, run)
- Architecture summary
- Critical constraints

**Operations**:
- Update commands when they change: Yes
- Update architecture summary after major changes: Yes
- Add new constraints: Yes
- Remove constraints: Only with user approval
- Keep under 60 lines: Yes (per best practices)

## General Principles

1. **Append, don't overwrite**: History is valuable
2. **Timestamps matter**: Always include date/time
3. **Reference tasks**: Link entries to task IDs
4. **Be concise**: Memory files load into context
5. **File paths**: Include for traceability
