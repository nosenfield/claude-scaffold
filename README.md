# Claude Project Scaffold

A scaffolding system for AI-driven software development with Claude Code agents.

## Overview

This scaffold provides a structured workflow for greenfield project development using Claude Code. It implements:

- **Subagent orchestration**: Specialized agents for planning, testing, implementation, review, and memory updates
- **TDD enforcement**: Tests before implementation with immutable test contracts
- **Memory persistence**: Session history and architectural decisions across context windows
- **Quality gates**: Hook-based enforcement at workflow boundaries

## Getting Started

This repository is a **template**, not a project. See [QUICKSTART.md](QUICKSTART.md) for setup instructions:

1. Run `setup-project.sh` to create a new project
2. Add core documentation (prd.md, architecture.md, task-list.json, best-practices.md)
3. Run `/init-repo` to initialize scaffold memory
4. Choose a workflow (see Decision Guide below)

---

## Workflows

### Decision Guide

Use this flowchart to choose the right workflow. Five questions lead to 10 workflows.

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

Or with plan approval pause: `/execute-task` (runs the full cycle for one task, pauses at plan approval and code review).

#### #4 Linear Manual (Worktree)

Same as #3, isolated in a worktree.

```
/dev -> /worktree <name> -> /next-from-task-list -> /plan-task -> ... -> /commit-task -> /worktree-cleanup
```

#### #5 Linear Automated

Single command executes entire linear task list. Session-chained: one `claude -p` subprocess per task, fresh context each time. No Agent Teams required.

```
/dev -> /execute-all-tasks
```

#### #6 Linear Automated (Worktree)

Same as #5, isolated in a worktree.

```
/dev -> /worktree <name> -> /execute-all-tasks -> /worktree-cleanup
```

#### #7 Parallel Manual

Step-by-step execution from a parallel task list. Execute each task in the current wave, then advance to the next wave.

**Prerequisite**: Run `/compute-waves` once to compute dependency graph and assign execution waves.

```
/dev -> /compute-waves -> /next-batch-from-list -> (execute each task manually) -> repeat per wave
```

#### #8 Parallel Manual (Worktree)

Same as #7, isolated in a worktree.

```
/dev -> /worktree <name> -> /compute-waves -> /next-batch-from-list -> ... -> /worktree-cleanup
```

#### #9 Parallel Auto (Single Orchestrator)

Single session spawns teammate agents per wave. Good for smaller task lists (< ~5 waves). Requires Agent Teams.

**Prerequisite**: `/compute-waves` (orchestrator runs it automatically if needed).

```
/dev -> /batch-execute-task-auto
```

Teammate lifecycle per wave:
```
TeamCreate -> Spawn workers -> Workers run /execute-task-from-batch
  -> SendMessage delivers result -> Shutdown handshake -> TeamDelete
```

Worktrees are created automatically per teammate -- no manual `/worktree` needed.

#### #10 Parallel Auto (Multi-Orchestrator)

Session-chained: fresh `claude -p` per wave. Recommended for large task lists (5+ waves / 28+ tasks). Requires Agent Teams.

**Prerequisite**: `/compute-waves` (orchestrator runs it automatically if needed).

```
/dev -> /batch-execute-chained
```

Each subprocess runs `/execute-one-wave`, which creates a team, spawns teammates, collects results, updates memory, then exits. The super-orchestrator monitors completion and advances to the next wave.

Worktrees are created automatically per teammate -- no manual `/worktree` needed.

### Worktree Isolation

Worktrees provide git index isolation -- separate staging areas and working directories.

**When automatic**: Parallel automated workflows (#9, #10) create worktrees per teammate to prevent staging contamination during concurrent commits.

**When manual**: Use `/worktree <name>` before starting any workflow when you need to work on something alongside an existing session. This applies to workflows #2, #4, #6, #8.

**How it works**:
- `/worktree <name>` creates a new git worktree branched from the default branch at `.claude/worktrees/<name>/`
- Work proceeds normally inside the worktree (all commands work the same)
- `/worktree-cleanup` merges (or discards) the worktree branch back to the default branch
- Memory updates happen after cleanup returns to the main tree
- To resume a worktree from a new session, run `/worktree <name>` again -- it detects and enters the existing worktree

### Commit Distinction

| Command | Scope | Used By |
|---------|-------|---------|
| `/commit-task` | Commit + memory update | Single-task workflows (#1-#8) |
| `/commit-implementation` | Commit only (no memory update) | Batch teammates (#9, #10) |

In batch workflows, teammates use `/commit-implementation`. The orchestrator handles memory updates centrally after collecting all teammate results.

---

## Command Reference

### Skills (User-Invocable)

| Skill | Purpose |
|-------|---------|
| `/dev [summary]` | Start development session; optionally resume from context summary |
| `/init-repo` | One-time scaffold initialization (validates docs, creates memory files) |
| `/map <target>` | Codebase exploration with artifact output (runs in forked context) |
| `/summarize` | Session handoff summary for context window management |

### Single-Task Commands

| Command | Purpose |
|---------|---------|
| `/next-from-task-list` | Select next task via task-selector subagent |
| `/plan-task [description]` | Plan implementation (task-list mode or ad-hoc with argument) |
| `/write-task-tests` | Write failing tests from implementation plan |
| `/implement-task` | Implement code to pass tests |
| `/review-task` | Code review via code-reviewer subagent |
| `/commit-task` | Commit implementation + update memory |
| `/commit-implementation` | Commit implementation only (no memory update; used by batch teammates) |
| `/execute-task` | Full single-task workflow with plan approval pause |
| `/execute-task-auto` | Full single-task workflow autonomously (no pauses) |
| `/execute-all-tasks` | Execute entire linear task list (session-chained, one `claude -p` per task) |

### Batch Commands

| Command | Purpose |
|---------|---------|
| `/compute-waves` | Compute execution waves from dependency graph |
| `/next-batch-from-list` | Select parallelizable tasks from current wave |
| `/batch-execute-task-auto` | Single-session batch orchestrator (spawns teammates per wave) |
| `/batch-execute-chained` | Multi-session super-orchestrator (launches `claude -p` per wave) |
| `/execute-one-wave` | Execute one wave in a `claude -p` subprocess (internal, used by `/batch-execute-chained`) |
| `/execute-task-from-batch` | Full dev cycle for a single task (teammate workflow) |

### Worktree Commands

| Command | Purpose |
|---------|---------|
| `/worktree <name>` | Find or create named worktree and switch session into it |
| `/worktree-cleanup [name]` | Merge or discard a worktree (interactive) |

---

## Scaffold Structure

### Scaffold source (this repo)

```
scaffold/
├── .claude/                 # Agents, commands, hooks, rules, skills, settings
├── .githooks/               # Git hooks (pre-commit, post-commit, commit lock, hookspath guard)
├── _docs/
│   ├── templates/           # Source-of-truth document templates
│   │   ├── prd.md
│   │   ├── architecture.md
│   │   ├── task-list-linear.json
│   │   ├── best-practices.md
│   │   ├── backlog.json
│   │   ├── progress.md
│   │   ├── decisions.md
│   │   └── git-exclude
│   ├── principles/          # Project-agnostic engineering principles
│   ├── context-summaries/   # Scaffold dev session summaries
│   ├── maps/                # Scaffold dev /map artifacts
│   ├── memory/              # Scaffold dev memory
│   └── notes/               # Scaffold dev notes
├── _scripts/
│   ├── setup-project.sh     # Creates new projects
│   ├── poll-inbox.sh        # Batch workflow utility
│   └── bootstrap-worktree.sh # Worktree dependency installer (project-customizable)
├── CLAUDE.md                # Scaffold dev instructions
├── CLAUDE.template.md       # Template for new projects (becomes CLAUDE.md)
├── QUICKSTART.md            # Getting started guide
├── README.md                # This file
└── .mcp.json                # MCP server configuration
```

### New project (after `setup-project.sh`)

```
my-project/
├── .claude/                 # Full copy of agents, commands, hooks, rules, skills, settings
├── .githooks/               # Git hooks (core.hooksPath configured automatically)
├── _docs/
│   ├── principles/          # Engineering principles (read-only reference)
│   ├── context-summaries/   # Empty -- populated by /summarize
│   ├── maps/                # Empty -- populated by /map
│   ├── memory/
│   │   ├── progress.md      # From templates/ -- initialized by /init-repo
│   │   └── decisions.md     # From templates/ -- initialized by /init-repo
│   ├── prd.md               # From templates/ -- customize with project requirements
│   ├── architecture.md      # From templates/ -- customize with system design
│   ├── templates/
│   │   ├── task-list-linear.json    # Linear task schema reference
│   │   └── task-list-parallel.json  # Parallel/batch task schema reference
│   ├── task-list.json       # From templates/ -- populate with project tasks
│   ├── best-practices.md    # From templates/ -- customize coding standards
│   └── backlog.json         # From templates/ -- initially empty
├── _scripts/
│   ├── poll-inbox.sh        # Batch workflow teammate inbox polling
│   └── bootstrap-worktree.sh # Worktree dependency installer
├── _logs/                   # Empty -- populated by git hooks
├── CLAUDE.md                # From CLAUDE.template.md -- customize for project
└── .mcp.json                # MCP server configuration
```

**Key differences**:
- Scaffold development files (memory, maps, context-summaries, notes) are not copied
- `CLAUDE.template.md` becomes the project's `CLAUDE.md`
- `setup-project.sh`, `README.md`, and `QUICKSTART.md` stay in the scaffold
- Placeholders (`[PROJECT_NAME]`, `[ISO_TIMESTAMP]`) are replaced during setup

---

## Architecture Reference

### Document Templates

The `_docs/templates/` directory is the single source of truth for all document templates. When creating a new project with `setup-project.sh`:

1. Templates are copied from `_docs/templates/` to `_docs/`
2. Placeholders (`[PROJECT_NAME]`, `[ISO_TIMESTAMP]`) are replaced
3. User customizes the copied files
4. `/init-repo` validates and creates memory files

| Template | Purpose | Agent Dependency |
|----------|---------|------------------|
| `prd.md` | Product requirements structure | None (guidance only) |
| `architecture.md` | System design structure | task-planner, implementer, code-reviewer |
| `task-list-linear.json` | Task schema with `_schema` documentation | **task-selector** (strict format) |
| `best-practices.md` | Coding standards skeleton | test-writer, implementer, code-reviewer, task-planner |
| `backlog.json` | Deferred issues schema | code-reviewer |
| `progress.md` | Memory file structure | memory-updater |
| `decisions.md` | Decision log structure | memory-updater |

### Task List Schema (Linear v1.0)

The `task-selector` agent expects tasks in this exact format:

```json
{
  "tasks": [
    {
      "id": "TASK-001",
      "title": "Task name",
      "description": "Detailed description",
      "priority": 1,
      "status": "pending",
      "acceptanceCriteria": ["Criterion 1", "Criterion 2"],
      "references": ["architecture.md#relevant-section"],
      "blockedBy": [],
      "completedAt": null
    }
  ]
}
```

Required fields: `id`, `title`, `description`, `priority`, `status`, `acceptanceCriteria`, `references`, `blockedBy`, `completedAt`

See `_docs/templates/task-list-linear.json` for full schema documentation.

### Task List Schema (Parallel v2.0)

For batch/parallel execution, `/compute-waves` extends the task list with wave assignments:

```json
{
  "version": "2.0.0",
  "waveSummary": [
    { "wave": 0, "taskIds": ["TASK-001"], "taskCount": 1 },
    { "wave": 1, "taskIds": ["TASK-002", "TASK-003"], "taskCount": 2 }
  ],
  "tasks": [
    {
      "id": "TASK-001",
      "title": "Task name",
      "description": "Detailed description",
      "priority": 1,
      "status": "eligible",
      "executionWave": 0,
      "assignedAgent": null,
      "affectedPaths": ["src/module.ts", "src/module.test.ts"],
      "acceptanceCriteria": ["Criterion 1"],
      "references": ["architecture.md#relevant-section"],
      "blockedBy": [],
      "completedAt": null
    }
  ]
}
```

**Additional v2.0 fields**:

| Field | Type | Purpose |
|-------|------|---------|
| `waveSummary` | array (root) | Wave-to-task mapping computed by `/compute-waves` |
| `executionWave` | int | Wave assignment (0-based); tasks in the same wave run in parallel |
| `assignedAgent` | string\|null | Teammate name (set during batch execution) |
| `affectedPaths` | array | Expected file paths for contention detection across parallel tasks |

**Status values** (v2.0 extends v1.x):

| Status | Meaning |
|--------|---------|
| `pending` | Not yet processed by `/compute-waves` |
| `eligible` | Ready to execute (all dependencies met) |
| `blocked` | Waiting on `blockedBy` dependencies |
| `in-progress` | Currently being executed by an agent |
| `complete` | Successfully finished |
| `failed` | Execution failed |

### Hooks

Configured in `.claude/settings.json`:

| Event | Script | Matcher | Mode |
|-------|--------|---------|------|
| `PostToolUse` | `quality-gate.sh` | `Write\|Edit\|MultiEdit` | Advisory (warns, does not block) |
| `PreToolUse` | `test-file-guard.sh` | `Write\|Edit\|MultiEdit` | Blocking (denies test file edits outside test-writer) |
| `SubagentStop` | `log-subagent.sh` | All | Logs agent completion with prompt/output excerpts |
| `TeammateIdle` | `log-subagent.sh` | All | Logs teammate idle events |
| `TaskCompleted` | `log-subagent.sh` | All | Logs task completion events |

Git hooks use `core.hooksPath .githooks` (configured by `setup-project.sh`).

### Context Management

Claude Code has a 200k token context limit. When context fills, use `/summarize` to hand off to a new agent.

**Monitoring**: Run `/context` periodically. Recommended handoff threshold: 70%.

**Handoff**:
1. Run `/summarize` when context is filling
2. Skill captures: completed work, in-progress state, decisions, files modified, key resources
3. Spawn new agent
4. Run `/dev _docs/context-summaries/[timestamp].md` to resume

**Session Chaining**: `/summarize` automatically detects prior summaries. Resources carry forward with lineage tracking, session chain history is preserved, stale resources are pruned.

**Why not auto-compaction?** Auto-compaction is lossy and may discard task-specific state. Manual `/summarize` ensures explicit control, preserved resource links, and traceable session chains.

### Best Practices Alignment

This scaffold follows the AI-Assisted Development Best Practices Manual (v2). Key alignments:

| Practice | Implementation |
|----------|----------------|
| CLAUDE.md under 60 lines | ~50 lines |
| Path-scoped rules | 5 rules in `.claude/rules/` |
| Structured subagent output | All agents define exact output format |
| Agent descriptions = when-to-use | All 6 agents lead with timing triggers |
| Test immutability | Triple enforcement: rule + hook + agent instruction |
| Persistent memory | _docs/memory/progress.md (Active Context replaced; Session Log appended) and _docs/memory/decisions.md (appended) |
| Hook-based quality gates | Git pre-commit (enforcement) + PostToolUse (advisory) + PreToolUse (test guard) + SubagentStop/TeammateIdle/TaskCompleted (logging) |

---

## Personal Overrides (CLAUDE.local.md)

Create a `CLAUDE.local.md` file in the project root for personal project-specific preferences. Claude Code automatically adds this file to .gitignore.

**Appropriate content:**
- Sandbox URLs and local environment endpoints
- Preferred test data and fixtures
- Personal workflow preferences
- Local tool paths or configurations

**Alternative for git worktrees:** Import from home directory instead, which works better across multiple worktrees:
```markdown
# In CLAUDE.md
@~/.claude/my-project-preferences.md
```

## References

- [AI-Assisted Development Best Practices Manual](../ai-development-best-practices-manual-v2.md)
- [Claude Code Documentation](https://docs.anthropic.com/claude-code)
