---
name: summarize
description: Summarize session for orchestrator handoff when context is filling
disable-model-invocation: true
---

# Summarize Session for Handoff

Capture session state for orchestrator handoff. Preserves context chains across multiple sessions.

## When to Use

User initiates when `/context` shows high usage (recommended: >70%).

## Steps

### 1. Detect Session Chain

Search conversation for references to previous summaries:
- Look for `_context-summaries/*.md` file references
- Check if user said "resume session based on..." at start

If found, read the previous summary file to:
- Extract the chain of prior sessions (`Previous Session` field)
- Identify resources that should carry forward
- Note any long-running work spanning multiple sessions

### 2. Gather Session Metadata

Ask user (if not obvious from conversation):
- Session topic (1-5 words)
- Whether in-progress work needs handoff

### 3. Generate Timestamp

```bash
date +%Y%m%d-%H%M%S
```

### 4. Collect State from Conversation

Review conversation to extract:

**Completed this session**:
- Tasks finished
- Decisions made
- Implementations completed

**In-progress work**:
- Current task state
- Blockers
- Immediate next steps

**Decisions made**:
- Architectural choices
- Rejected approaches with rationale

**Files modified**:
- Created, modified, deleted

**Open questions**:
- Unresolved items needing user input

### 5. Collect Key Resources

Gather links and references from:

**This session**:
- URLs fetched or referenced
- Documentation consulted
- External resources mentioned
- File paths critical to current work

**Previous summaries** (if session chain exists):
- Carry forward resources still relevant
- Drop resources no longer applicable
- Note which session introduced each resource

### 6. Check Repository State

```bash
git status --short
git diff --name-only
```

### 7. Write Context Summary

Create `_context-summaries/[timestamp].md`:

```markdown
# Session Summary: [Topic]

**Date**: [YYYY-MM-DD]
**Previous Session**: [prior summary filename, or "None (initial session)"]
**Session Chain**: [count] sessions on this work stream
**Purpose**: [1-2 sentence description]

---

## Completed This Session

[List of completed items with outcomes]

## In-Progress Work

**Current Task**: [task ID and title, or "None"]
**State**: [description of where work stands]
**Next Steps**:
1. [immediate next action]
2. [following action]

**Blockers**: [any blocking issues, or "None"]

## Decisions Made

| Decision | Rationale | Alternatives Rejected |
|----------|-----------|----------------------|
| [choice] | [why]     | [what else considered] |

## Files Modified

**Created**:
- [file] - [purpose]

**Modified**:
- [file] - [what changed]

**Deleted**:
- [file] - [why removed]

## Uncommitted Changes

[List from git status, or "None - working tree clean"]

## Key Resources

### From This Session
- [resource description](url or path)

### Carried Forward
- [resource description](url or path) *(from session [date])*

### Dropped (No Longer Relevant)
- [resource] - [why dropped]

## Open Questions

[Unresolved items for user to address, or "None"]

---

## Session Chain History

| Session | Date | Topic | Key Outcome |
|---------|------|-------|-------------|
| [timestamp].md | [date] | [topic] | [main result] |

*[Include rows for all sessions in chain, newest first]*

```

### 8. Update progress.md

Append session entry:

```markdown
## [Date] - [Topic]

**Summary**: [1-2 sentences]
**Context Summary**: `_context-summaries/[timestamp].md`
**Session Chain**: [count] sessions
**Outcome**: [Completed X, handed off Y]
```

### 9. Report Handoff Ready

```
## Session Summarized

**Summary File**: _context-summaries/[timestamp].md
**Session Chain**: [count] sessions on this work stream
**Progress Updated**: Yes

### Handoff Instructions

1. Spawn new Claude Code agent
2. Run `/dev _context-summaries/[timestamp].md`

### Quick Context for New Agent

[2-3 sentence summary including:
- What work stream this continues
- Current state
- Immediate next action]

### Key Resources to Note

[List 2-3 most important resources the new agent should be aware of]
```

## Context Chaining Rules

1. **Always check for prior session**: First action is detecting if this session resumed from a summary
2. **Preserve resource lineage**: Note which session introduced each resource
3. **Prune stale resources**: Don't carry forward resources no longer relevant
4. **Maintain chain history**: Each summary includes full session chain table
5. **Increment chain count**: Track how many sessions have worked on this stream

## Output Quality

The context summary must be:
- **Self-contained**: New agent needs no other context beyond `/dev` output
- **Actionable**: Clear next steps
- **Traceable**: Links back to all prior sessions in chain
- **Resource-rich**: Key references preserved for continuity
