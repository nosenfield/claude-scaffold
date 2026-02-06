---
paths:
  - "_docs/memory/progress.md"
  - "_docs/memory/decisions.md"
  - "CLAUDE.md"
---

# Memory Bank Rules

Memory bank files provide persistent context across sessions. They must be maintained carefully to preserve project history.

## File Purposes

| File | Purpose | Update Frequency |
|------|---------|------------------|
| _docs/memory/progress.md | Session history, completed work | After each task completion |
| _docs/memory/decisions.md | Architecture and implementation decisions | When significant decisions made |
| CLAUDE.md | Project context for Claude Code | Rarely, when project structure changes |

## _docs/memory/progress.md Rules

**Structure**: Two sections with different update patterns.

### Active Context Section

Located at top of file, between `## Active Context` and `## Session Log`.

**Content**:
- Current Focus (what we're working on)
- Current Task (if any)
- Recent Decisions (last 2-3)
- Immediate Next Steps

**Operations**:
- REPLACE entire section on each update: Yes
- This is what `/dev` reads at session start

### Session Log Section

Located below Active Context, after `<!-- New entries are added below this line -->`.

**Entry Format**:
```markdown
## YYYY-MM-DD - [Title]
**Summary**: [1-2 sentences describing what was done]
**Changes**: [file1], [file2], [file3]
**Commit**: [hash] | **Chain**: [N]
---
```

**Operations**:
- APPEND new entries: Yes (immediately after marker comment)
- Modify existing entries: No
- Delete entries: No
- Reorder entries: No

## _docs/memory/decisions.md Rules

**Structure**: Append-only log of architectural decisions.

**Entry Format**:
```markdown
## YYYY-MM-DD: [Title]
**Context**: [1-2 sentences on why decision was needed]
**Decision**: [what was decided]
**Rationale**: [why this choice; key rejected alternatives inline]
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
