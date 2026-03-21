# Claude Project Scaffold

A scaffolding system for AI-driven software development with Claude Code agents.

## Overview

This scaffold provides a structured workflow for greenfield project development using Claude Code. It implements:

- **Subagent orchestration**: Specialized agents for planning, testing, implementation, review, and memory updates
- **TDD enforcement**: Tests before implementation with immutable test contracts
- **Memory persistence**: Session history and architectural decisions across context windows
- **Quality gates**: Hook-based enforcement at workflow boundaries

## Scaffold Structure

This repository is a **template**, not a project. Run `setup-project.sh` to create a new project from it.

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
- `_docs/templates/` is not copied -- templates are placed at their target locations
- Scaffold development files (memory, maps, context-summaries, notes) are not copied
- `CLAUDE.template.md` becomes the project's `CLAUDE.md`
- `setup-project.sh`, `README.md`, and `QUICKSTART.md` stay in the scaffold
- Placeholders (`[PROJECT_NAME]`, `[ISO_TIMESTAMP]`) are replaced during setup

### Claude Code Hooks

Configured in `.claude/settings.json`:

| Event | Script | Matcher | Mode |
|-------|--------|---------|------|
| `PostToolUse` | `quality-gate.sh` | `Write\|Edit\|MultiEdit` | Advisory (warns, does not block) |
| `PreToolUse` | `test-file-guard.sh` | `Write\|Edit\|MultiEdit` | Blocking (denies test file edits outside test-writer) |
| `SubagentStop` | `log-subagent.sh` | All | Logs agent completion with prompt/output excerpts |
| `TeammateIdle` | `log-subagent.sh` | All | Logs teammate idle events |
| `TaskCompleted` | `log-subagent.sh` | All | Logs task completion events |

Git hooks use `core.hooksPath .githooks` (configured by `setup-project.sh`).

## Document Templates

The `_docs/templates/` directory is the single source of truth for all document templates. When creating a new project with `setup-project.sh`:

1. Templates are copied from `_docs/templates/` to `_docs/`
2. Placeholders (`[PROJECT_NAME]`, `[ISO_TIMESTAMP]`) are replaced
3. User customizes the copied files
4. `/init-repo` validates and creates memory files

Templates provide:
- Structure and placeholder guidance
- Schema documentation (critical for `task-list.json` and `backlog.json`)
- Reference for expected formats

### Template Files

| Template | Purpose | Agent Dependency |
|----------|---------|------------------|
| `prd.md` | Product requirements structure | None (guidance only) |
| `architecture.md` | System design structure | task-planner, implementer, code-reviewer |
| `task-list-linear.json` | Task schema with `_schema` documentation | **task-selector** (strict format) |
| `best-practices.md` | Coding standards skeleton | test-writer, implementer, code-reviewer, task-planner |
| `backlog.json` | Deferred issues schema | code-reviewer |
| `progress.md` | Memory file structure | memory-updater |
| `decisions.md` | Decision log structure | memory-updater |

### Critical: task-list.json Schema

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

### Batch Schema (v2.0)

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

## Commands and Skills

### Skills (User-Invocable)

| Skill | Purpose |
|-------|---------|
| `/dev [summary]` | Start development session; optionally resume from context summary |
| `/init-repo` | One-time scaffold initialization (validates docs, creates memory files) |
| `/map <target>` | Codebase exploration with artifact output (runs in forked context) |
| `/summarize` | Session handoff summary for context window management |

### Commands — Single-Task Workflow

| Command | Purpose |
|---------|---------|
| `/next-from-task-list` | Select next task via task-selector subagent |
| `/plan-task [description]` | Plan implementation (task-list mode or ad-hoc with argument) |
| `/write-task-tests` | Write failing tests from implementation plan |
| `/implement-task` | Implement code to pass tests |
| `/review-task` | Code review via code-reviewer subagent |
| `/commit-task` | Commit implementation + update memory |
| `/commit-implementation` | Commit implementation only (no memory update; used by batch teammates) |
| `/execute-task` | Run full single-task workflow with plan approval pause |
| `/execute-task-auto` | Run full single-task workflow autonomously (no pauses) |

### Commands — Batch Workflow

| Command | Purpose |
|---------|---------|
| `/compute-waves` | Compute execution waves from dependency graph (prerequisite for batch) |
| `/next-batch-from-list` | Select parallelizable tasks from current wave |
| `/batch-execute-task-auto` | Single-session batch orchestrator (spawns teammate agents per wave) |
| `/batch-execute-chained` | Multi-session super-orchestrator (launches `claude -p` per wave) |
| `/execute-one-wave` | Execute one wave in a `claude -p` subprocess (used by `/batch-execute-chained`) |
| `/execute-task-from-batch` | Full dev cycle for a single task (teammate workflow) |

### Commands -- Worktree (Ad-hoc Isolation)

| Command | Purpose |
|---------|---------|
| `/worktree <name>` | Find or create named worktree and switch session into it |
| `/worktree-cleanup [name]` | Merge or discard a worktree (interactive) |

## Development Workflow

### Task-List Workflow (Structured)

Use when working through predefined tasks in `task-list.json`:

1. `/dev [summary]` - Start development session (optionally resume from summary)
2. `/next-from-task-list` - Select next task from task list
3. `/plan-task` - Plan implementation
4. `/write-task-tests` - Write failing tests
5. `/implement-task` - Make tests pass
6. `/review-task` - Code review
7. `/commit-task` - Commit and update memory

Or use shorthand commands:
- `/execute-task` - Runs steps 2-7 with a plan approval pause
- `/execute-task-auto` - Runs steps 2-7 fully autonomously (no pauses)

### Ad-hoc Workflow (Exploratory)

Use for unplanned work or when task list doesn't apply:

1. `/dev [summary]` - Start development session
2. `/plan-task <description>` - Plan implementation (runs `/map` internally, then invokes task-planner)
3. `/write-task-tests` - Write failing tests
4. `/implement-task` - Make tests pass
5. `/review-task` - Code review
6. `/commit-task` - Commit changes

The ad-hoc workflow skips `/next-from-task-list` (no task selection). `/plan-task` accepts a description argument directly, runs `/map` exploration, and invokes the task-planner agent without requiring a task-list entry. Both workflows share the same TDD cycle from `/write-task-tests` onward.

### Worktree-Isolated Ad-hoc

Use when performing ad-hoc work alongside batch execution or another active session:

1. Open a **new Claude Code instance**
2. `/dev` - Start development session
3. `/worktree <name>` - Find or create isolated worktree from default branch
4. `/plan-task <description>` - Plan implementation
5. `/write-task-tests` - Write failing tests
6. `/implement-task` - Make tests pass
7. `/review-task` - Code review
8. `/commit-task` - Commit changes (commits to worktree branch)
9. `/worktree-cleanup` - Merge into default branch and clean up

The original instance continues undisturbed in the primary working tree.

To resume work in a worktree from a new session, run `/worktree <name>` again -- it detects the existing worktree and enters it.

### Batch Workflow (Parallel Execution)

Use when executing multiple tasks in parallel from a wave-based task list (v2.0 schema with `waveSummary`):

**Prerequisites**: Run `/compute-waves` once after creating `task-list.json` to compute the dependency graph and assign execution waves.

**Option A — Single-session** (up to ~5 waves):
```
/dev -> /compute-waves -> /batch-execute-task-auto
```
Spawns teammate agents within the current session. Each teammate runs `/execute-task-from-batch` (plan -> tests -> implement -> review -> commit). Good for smaller task lists where context overflow is not a concern.

**Option B — Session-chained** (any number of waves):
```
/dev -> /compute-waves -> /batch-execute-chained
```
Launches a fresh `claude -p` subprocess per wave. Each subprocess runs `/execute-one-wave`, which creates a team, spawns teammates, collects results, updates memory, then exits. The super-orchestrator monitors completion and advances to the next wave. Recommended for large task lists (28+ tasks / 5+ waves) to avoid context overflow.

**Teammate lifecycle** (within each wave):
```
TeamCreate -> Spawn worker teammates -> Workers execute /execute-task-from-batch
  -> SendMessage delivers result -> Shutdown handshake -> TeamDelete
```

**Commit distinction**: Teammates use `/commit-implementation` (commit only, no memory update). The orchestrator handles memory updates centrally after collecting all teammate results.

### Setup Note

Run `/init-repo` once after placing project documentation to initialize memory files (`_docs/memory/progress.md`, `_docs/memory/decisions.md`) and validate core docs. Environment setup (dependency installation, dev server configuration) is handled through the first tasks in `task-list.json`.

## Context Management

Claude Code has a 200k token context limit. When context fills, use `/summarize` to hand off to a new agent.

### Monitoring Context

Run `/context` periodically to check usage. Recommended handoff threshold: 70%.

### Handoff Workflow

1. Run `/summarize` when context is filling
2. Skill captures: completed work, in-progress state, decisions, files modified, key resources
3. Spawn new agent
4. Run `/dev _docs/context-summaries/[timestamp].md` to resume

### Session Chaining

The `/summarize` skill automatically detects if the current session resumed from a prior summary. When chaining sessions:

- Resources are carried forward with lineage tracking
- Session chain history is preserved
- Stale resources are pruned
- Full chain table maintained in each summary

### Why Not Auto-Compaction?

Auto-compaction is lossy and may discard task-specific state. Manual `/summarize` ensures:
- Explicit control over what persists
- Resource links preserved
- Session chain traceable
- Clean handoff to new agent

## Best Practices Alignment

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
