---
paths:
  - "progress.md"
  - "decisions.md"
---

# Memory Bank Rules

Memory bank files preserve context across sessions. Maintain their integrity.

## progress.md

### Structure
```markdown
# Progress Log

## [ISO Date] - Session [N]
- **Task**: [ID or "Session start"]
- **Outcome**: [summary]
- **Files Modified**: [list]
- **Next Steps**: [recommendation]
```

### Rules
- ALWAYS append new entries; never overwrite
- Use ISO 8601 dates (YYYY-MM-DD)
- Keep entries concise (3-5 bullet points)
- Include file paths for traceability

## decisions.md

### Structure
```markdown
# Decision Log

## [ISO Date] - [Decision Title]
- **Context**: [why decision was needed]
- **Options Considered**: [alternatives]
- **Decision**: [what was chosen]
- **Rationale**: [why]
- **Implications**: [consequences]
```

### Rules
- Document decisions that affect architecture or approach
- Do not document trivial implementation choices
- Link to relevant files or tasks
- Append only; preserve history

## General Rules
- Never delete historical entries
- Correct errors by appending corrections, not editing
- Keep language factual and neutral
