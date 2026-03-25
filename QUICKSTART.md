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

### Step 2: Add Core Documentation

Add project-specific documentation to `_docs/`, using the corresponding template in `_docs/templates/` as a starting point:

- `prd.md` - Product requirements (supports Features, User Stories, or Systems structure)
- `architecture.md` - System design (tech stack, components, data models)
- `task-list.json` - Development tasks (see `_docs/templates/task-list-linear.json` for required schema fields)
- `best-practices.md` - Coding standards and project conventions

Update `CLAUDE.md` with project-specific instructions.

Commit changes.

### Step 3: Run /init-repo

```bash
/init-repo
```

Initializes scaffold memory files (`_docs/memory/progress.md`, `_docs/memory/decisions.md`) and validates documentation structure.

---

## Phase 2: Choose Your Workflow

Use the decision flowchart to select the right workflow for your situation.

### Decision Flowchart

```
Q1: Do you have a task list?
|
+-- No
|   |
|   Q4: Working on other tasks in this repo at the same time?
|   |
|   +-- No ... #1  Ad-hoc manual
|   +-- Yes .. #2  Ad-hoc manual (worktree)
|
+-- Yes
    |
    Q2: Do you want parallel execution?
    |
    +-- No (Linear)
    |   |
    |   Q3: Manual or automated?
    |   |
    |   +-- Manual
    |   |   |
    |   |   Q4: Concurrent?
    |   |   +-- No ... #3  Linear manual
    |   |   +-- Yes .. #4  Linear manual (worktree)
    |   |
    |   +-- Automated
    |       |
    |       Q4: Concurrent?
    |       +-- No ... #5  Linear automated
    |       +-- Yes .. #6  Linear automated (worktree)
    |
    +-- Yes (Parallel)
        |
        Q3: Manual or automated?
        |
        +-- Manual
        |   |
        |   Q4: Concurrent?
        |   +-- No ... #7  Parallel manual
        |   +-- Yes .. #8  Parallel manual (worktree)
        |
        +-- Automated
            |
            Q5: Project size?
            +-- Small (< 5 waves) ... #9   Parallel auto (single orchestrator)
            +-- Large (5+ waves) .... #10  Parallel auto (multi-orchestrator)
```

### Workflow Reference

#### #1 Ad-hoc Manual

No task list. Full manual control over each step.

```
/dev -> /plan-task <description> -> /write-task-tests -> /implement-task -> /review-task -> /commit-task
```

#### #2 Ad-hoc Manual (Worktree)

Same as #1, isolated in a worktree for concurrent work.

```
/dev -> /worktree <name> -> /plan-task <description> -> ... -> /commit-task -> /worktree-cleanup
```

#### #3 Linear Manual

Step-by-step execution from a linear task list. Repeat for each task.

```
/dev -> /next-from-task-list -> /plan-task -> /write-task-tests -> /implement-task -> /review-task -> /commit-task
```

#### #4 Linear Manual (Worktree)

Same as #3, isolated in a worktree.

```
/dev -> /worktree <name> -> /next-from-task-list -> /plan-task -> ... -> /commit-task -> /worktree-cleanup
```

#### #5 Linear Automated

Single command executes entire linear task list. Session-chained (one `claude -p` per task).

```
/dev -> /execute-all-tasks
```

#### #6 Linear Automated (Worktree)

Same as #5, isolated in a worktree.

```
/dev -> /worktree <name> -> /execute-all-tasks -> /worktree-cleanup
```

#### #7 Parallel Manual

Step-by-step execution from a parallel task list. Execute each task in the current wave, then advance.

**Prerequisite**: Run `/compute-waves` once to compute dependency graph.

```
/dev -> /compute-waves -> /next-batch-from-list -> (execute each task manually) -> repeat per wave
```

#### #8 Parallel Manual (Worktree)

Same as #7, isolated in a worktree.

```
/dev -> /worktree <name> -> /compute-waves -> /next-batch-from-list -> ... -> /worktree-cleanup
```

#### #9 Parallel Auto (Single Orchestrator)

Single session spawns teammate agents per wave. Good for smaller task lists (< ~5 waves).

**Prerequisite**: Run `/compute-waves` once (or let the orchestrator run it automatically).

```
/dev -> /compute-waves -> /batch-execute-task-auto
```

Worktrees are created automatically per teammate -- no manual `/worktree` needed.

#### #10 Parallel Auto (Multi-Orchestrator)

Session-chained: fresh `claude -p` per wave. Recommended for large task lists (5+ waves / 28+ tasks).

**Prerequisite**: Run `/compute-waves` once (or let the orchestrator run it automatically).

```
/dev -> /compute-waves -> /batch-execute-chained
```

Worktrees are created automatically per teammate -- no manual `/worktree` needed.

### Commit Distinction

| Command | Scope | Used By |
|---------|-------|---------|
| `/commit-task` | Commit + memory update | Single-task workflows (#1-#8) |
| `/commit-implementation` | Commit only (no memory update) | Batch teammates (#9, #10) |

In batch workflows, teammates use `/commit-implementation`. The orchestrator handles memory updates centrally after collecting results.

---

## Phase 3: Context Management

When context fills (~70%), run `/summarize` to hand off to a new session. Resume with `/dev _docs/context-summaries/<timestamp>.md`.
