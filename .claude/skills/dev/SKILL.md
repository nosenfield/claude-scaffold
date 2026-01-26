---
name: dev
description: Start development session and establish context. Optionally resume from a session summary.
argument-hint: "[summary-file]"
---

# Start Development Session

Resume development workflow and establish session context. Optionally load a session summary for continuity across context windows.

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

If no argument provided, skip to step 3.

### 3. Load Memory Files

Read in order:
- `progress.md`: Last session summary, completed tasks, in-progress work
- `decisions.md`: Architectural decisions, rejected approaches
- `_docs/task-list.json`: Task statuses, current task

### 4. Check Repository State

```bash
git status
git log --oneline -5
```

Note uncommitted changes. Git log is verification only; trust memory files as authoritative.

### 5. Verify Environment

```bash
npm run build --silent
npm run test --silent
```

If either fails, report the issue before proceeding.

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
**Last Completed Task**: [task ID and title]
**In-Progress Task**: [task ID and title, or "None"]

### Recent Decisions
- [relevant decisions from decisions.md]

### Recommended Action
- If in-progress task exists: "Continue with `/plan` or `/implement`"
- If clean state: "Select next task with `/next`"
```

## Notes

- Session summary argument is optional; `/dev` works without it
- When resuming, the summary supplements (not replaces) memory files
- Key resources from prior sessions should be noted for continuity
- If summary file doesn't exist, warn and proceed with normal session start
