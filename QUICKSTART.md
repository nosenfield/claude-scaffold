# Project Setup Quickstart

Guide for setting up and running a new project using the claude-project-template scaffold.

---

## Phase 1: Project Setup

### Step 1: Run setup-project.sh

```bash
cd /path/to/claude-project-template/scaffold
./_scripts/setup-project.sh <project-name>
```

Creates a new project directory with scaffold infrastructure (commands, agents, hooks, rules, settings).

---

### Step 2: Add Core Documentation

Add project-specific documentation to `_docs/`, using the corresponding template in `_docs/templates/` as a starting point:

- `prd.md` - Product requirements (supports Features, User Stories, or Systems structure)
- `architecture.md` - System design (tech stack, components, data models)
- `task-list.json` - Development tasks (see `_docs/templates/task-list-linear.json` for required schema fields)
- `best-practices.md` - Coding standards and project conventions

Update `CLAUDE.md` with project-specific instructions.

Commit changes.

---

### Step 3: Run /init-repo

```bash
/init-repo
```

Initializes scaffold memory files (`_docs/memory/progress.md`, `_docs/memory/decisions.md`) and validates documentation structure.

---

## Phase 2: Development Workflow

### Step 4: Start Development Session

```bash
/dev
```

Loads memory files, reports session status, and recommends next action.

To resume from a prior session:
```bash
/dev _docs/context-summaries/<timestamp>.md
```

---

### Step 5: Execute Tasks

**Single task (autonomous)**:
```
/dev -> /execute-task-auto
```
Or `/execute-task` for autonomous execution with pauses for plan approval and non-blocking code review issues.

**Single task (manual steps)**:
```
/dev -> /next-from-task-list -> /plan-task -> /write-task-tests -> /implement-task -> /review-task -> /commit-task
```

**Batch (session-chained, for large task lists)**:
```
/dev -> /compute-waves -> /batch-execute-chained
```
Launches a fresh `claude -p` subprocess per wave, avoiding context overflow. Recommended for 28+ tasks / 5+ waves.

**Batch (parallel execution)**:
```
/dev -> /compute-waves -> /batch-execute-task-auto
```
`/compute-waves` converts the linear task list into a wave-based parallel schema (v2.0) by computing a dependency graph from `blockedBy` fields. You can run it manually to review parallelization before execution, or skip it -- the batch orchestrator will run it automatically if needed.

Spawns teammate agents for each task in the current wave. Good for smaller task lists (up to ~5 waves).

**Ad-hoc (no task list)**:
```
/dev -> /plan-task <description> -> /write-task-tests -> /implement-task -> /review-task -> /commit-task
```

**Ad-hoc in worktree (parallel-safe)**:
```
(new instance) /worktree <name> -> /plan-task <description> -> ... -> /commit-task -> /worktree-cleanup
```

---

### Commit Distinction

| Command | Scope | Used By |
|---------|-------|---------|
| `/commit-task` | Commit + memory update | Single-task orchestrator |
| `/commit-implementation` | Commit only (no memory update) | Batch teammates |

In batch workflows, teammates use `/commit-implementation`. The orchestrator handles memory updates centrally after collecting results.

---

## Context Management

When context fills (~70%), run `/summarize` to hand off to a new session. Resume with `/dev _docs/context-summaries/<timestamp>.md`.
