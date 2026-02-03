---
name: dev
description: Start development session and establish context. Optionally resume from a session summary.
argument-hint: "[summary-file]"
---

# Start Development Session

Resume development workflow and establish session context. Optionally load a session summary for continuity across context windows.

## Prerequisites

Repository must be initialized. If memory files don't exist, run `/init-repo` first.

## Usage

```bash
# Normal session start
/dev

# Resume from session summary
/dev _context-summaries/20260125-195500.md
```

## Steps

### 1. Confirm Working Directory

```bash
pwd
```

Verify you are in the project root.

### 2. Check for Session Summary Argument

If `$ARGUMENTS` is provided:
- Verify the file exists
- Read the summary file
- Extract:
  - **Previous Session**: Chain link
  - **Session Chain**: Count of prior sessions
  - **In-Progress Work**: Current task state, next steps
  - **Key Resources**: Links to carry forward
  - **Resume Instructions**: Specific guidance from prior session

If no argument provided, skip to step 4.

### 3. Load Key Resources from Summary

If resuming from a summary, load each resource listed in "Key Resources" into context:
- **Local files** (paths like `../file.md` or `_docs/file.md`): Read the file
- **Web URLs** (https://...): Fetch the URL content

This ensures continuity - the new session has the same reference material as the prior session.

### 4. Load Memory Files

Check that memory files exist:
- `progress.md`
- `decisions.md`

**If memory files don't exist**, report and stop:

```
## Repository Not Initialized

Memory files (progress.md, decisions.md) not found.

Run `/init-repo` to initialize this repository before starting development.
```

If memory files exist, read them:
- `progress.md`: **Active Context section** (current focus, task, next steps) + recent Session Log entries
- `decisions.md`: Architectural decisions, rejected approaches

**Active Context** is the primary source for session state. It contains:
- Current Focus (what we're working on)
- Current Task (if any)
- Recent Decisions (last 2-3)
- Immediate Next Steps

Verify `_docs/task-list.json` exists (do not read contents; task list access is handled by `task-selector` subagent via `/next`).

### 5. Check Repository State

```bash
git status
git log --oneline -5
```

Note uncommitted changes. Git log is verification only; trust memory files as authoritative.

### 6. Report Session Status

**If resuming from summary**, report:

```
## Session Resumed

**From Summary**: [summary filename]
**Session Chain**: [N] prior sessions
**Work Stream**: [topic from summary]

### Resumed State

**In-Progress Task**: [task from summary, or "None"]
**Next Steps**:
1. [from summary]
2. [from summary]

### Key Resources (Carried Forward)
- [resource](link) *(from session [date])*

### Current Repository State
- [clean/dirty]
- [uncommitted changes if any]

### Recommended Action
[Based on in-progress work from summary]
```

**If normal session start**, report:

```
## Session Status

**Repository**: [clean/dirty]
**Last Updated**: [date from Active Context]

### Active Context

**Current Focus**:
- [from Active Context section]

**Current Task**: [from Active Context, or "None"]

**Recent Decisions**:
- [from Active Context section]

**Immediate Next Steps**:
1. [from Active Context]
2. [from Active Context]

### Recent Session Log
[Last 1-2 entries from Session Log section, summarized]

### Recommended Action
[Based on Current Task and Next Steps from Active Context, or "Run `/next` to select a task"]
```

## Notes

- Session summary argument is optional; `/dev` works without it
- When resuming, the summary supplements (not replaces) memory files
- Key resources from prior sessions should be noted for continuity
- If summary file doesn't exist, warn and proceed with normal session start
- Task list contents are accessed only through `/next` (via task-selector subagent) to keep orchestrator context lean
