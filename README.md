# Claude Project Scaffold

A scaffolding system for AI-driven software development with Claude Code agents.

## Overview

This scaffold provides a structured workflow for greenfield project development using Claude Code. It implements:

- **Subagent orchestration**: Specialized agents for planning, testing, implementation, review, and memory updates
- **TDD enforcement**: Tests before implementation with immutable test contracts
- **Memory persistence**: Session history and architectural decisions across context windows
- **Quality gates**: Hook-based enforcement at workflow boundaries

## Scaffold Structure

```
scaffold/
├── .claude/
│   ├── agents/          # Specialized subagents
│   ├── commands/        # Workflow commands (/next-from-task-list, /plan-task, etc.)
│   ├── hooks/           # Claude Code quality gate scripts
│   ├── rules/           # File protection policies
│   ├── skills/          # Extended capabilities
│   │   ├── dev/         # Session start (with resume support)
│   │   ├── init-repo/   # One-time scaffold initialization
│   │   ├── map/         # Codebase exploration with artifacts
│   │   └── summarize/   # Context handoff
│   └── settings.json    # Hooks, permissions, and environment variables
├── .githooks/           # Git hooks (version-controlled)
│   ├── pre-commit       # Quality gates (test, lint, typecheck)
│   ├── post-commit      # Commit logging, bypass detection
│   ├── git-commit-lock.sh # Serialize parallel commits (batch workflow)
│   └── protect-hookspath.sh # Guard against Husky overwriting core.hooksPath
├── _docs/               # Project documentation
│   ├── templates/       # Document templates (source of truth)
│   │   ├── prd.md           # Product requirements structure
│   │   ├── architecture.md  # System design structure
│   │   ├── task-list.json   # Task schema (critical for task-selector agent)
│   │   ├── best-practices.md # Coding standards skeleton
│   │   ├── backlog.json     # Deferred issues schema
│   │   ├── progress.md      # Memory file structure
│   │   └── decisions.md     # Decision log structure
│   ├── best-practices.md # Concrete example (copied to new projects)
│   ├── principles/      # Project-agnostic engineering principles
│   ├── maps/            # /map output artifacts (timestamped)
│   ├── context-summaries/ # Session handoff summaries
│   └── memory/          # Persistent memory (scaffold development only)
│       ├── progress.md  # Session state + history
│       └── decisions.md # Append-only decision log
├── _scripts/            # Setup and utility scripts
│   ├── setup-project.sh # Create new project from scaffold
│   └── poll-inbox.sh   # Poll teammate message inbox (batch workflow)
├── CLAUDE.md            # Project context for Claude Code
└── .mcp.json            # MCP server configuration
```

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
| `task-list.json` | Task schema with `_schema` documentation | **task-selector** (strict format) |
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

See `_docs/templates/task-list.json` for full schema documentation.

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

## Design Decisions

Decisions made during scaffold development are recorded below.

### Decision Log

#### 2025-01-25: Manual Context Loading via /dev

**Context**: Evaluated whether to add a SessionStart hook for automatic context injection at session start.

**Decision**: Keep manual context loading via `/dev` command.

**Rationale**:
- Not all orchestrator sessions require full project context
- Some sessions may be quick questions or unrelated tasks
- Explicit `/dev` command gives users control over when to initialize the orchestrator as a development partner
- Reduces unnecessary token overhead for short sessions

**Alternative Considered**: SessionStart hook to auto-inject progress.md and task state. Rejected because automatic injection assumes all sessions are development sessions.

---

#### 2025-01-25: Git Pre-Commit Hook for Quality Gates

**Context**: Quality gates need to run before code is committed. Initially considered a Claude Stop hook, but this would run on every response (including simple questions), causing unnecessary latency.

**Decision**: Use git pre-commit hook as the single enforcement point.

**Implementation**:

Git hooks (`.githooks/`, via `core.hooksPath`):

| Hook | Trigger | Purpose |
|------|---------|---------|
| `pre-commit` | `git commit` | Runs test, lint, typecheck before commit |
| `post-commit` | After commit | Logs commits, detects `--no-verify` bypass |
| `git-commit-lock.sh` | Called by batch orchestrator | Serializes parallel commits to prevent staging contamination |
| `protect-hookspath.sh` | Called by pre-commit | Guards against Husky or other tools overwriting `core.hooksPath` |

Claude Code hooks (`.claude/settings.json`):

| Event | Script | Matcher | Mode |
|-------|--------|---------|------|
| `PostToolUse` | `quality-gate.sh` | `Write\|Edit\|MultiEdit` | Advisory (warns, does not block) |
| `PreToolUse` | `test-file-guard.sh` | `Write\|Edit\|MultiEdit` | Blocking (denies test file edits outside test-writer) |
| `SubagentStop` | `log-subagent.sh` | All | Logs agent completion with prompt/output excerpts |
| `TeammateIdle` | `log-subagent.sh` | All | Logs teammate idle events |
| `TaskCompleted` | `log-subagent.sh` | All | Logs task completion events |

**Configuration**: Git hooks use `core.hooksPath` (Git 2.9+) for version-controlled hooks:
```bash
git config core.hooksPath .githooks
```

This is configured automatically by `setup-project.sh` when creating a new project.

**Rationale**:
- Git commit is the correct enforcement boundary—nothing commits without passing
- Avoids unnecessary checks on non-commit operations (`/dev`, `/next`, Q&A)
- Single source of truth for quality gate logic
- Works regardless of commit source (Claude or human)
- `core.hooksPath` keeps hooks version-controlled and visible (modern Husky-style pattern)

**Alternative Rejected**: Claude Stop hook running on every response. This caused 10-30s delays after every interaction, even simple questions.

---

#### 2026-01-26: /init-repo Skill for Scaffold Initialization

**Context**: Setup responsibilities (doc validation, memory file creation, backlog.json) were initially placed in `task-list.json` as TASK-001 through TASK-003. However, these are scaffold infrastructure tasks, not project features -- they don't belong in the user's task list.

**Decision**: Create `/init-repo` skill for one-time scaffold initialization. Remove setup tasks from `task-list.json`.

**Implementation**:
- `/init-repo` skill validates core docs, creates `progress.md`, `decisions.md`, `backlog.json`
- `/dev` requires initialization (reports and stops if memory files missing)
- `task-list.json` template contains only placeholder project tasks
- Environment setup (dependencies, dev server) remains as first user task in task list

**Rationale**:
- Scaffold infrastructure tasks should not modify the user's task list
- One-time setup is invoked explicitly, not discovered through `/next`
- User controls when initialization runs
- Clean separation: /init-repo = scaffold setup, task-list.json = project work

**Alternative Rejected**: Keeping setup tasks in task-list.json. This modifies the user's file with scaffold concerns and conflates infrastructure with project work.

---

#### 2026-01-26: Task-Selector Subagent for Context Isolation

**Context**: The `/next-from-task-list` command previously read `task-list.json` directly, pulling the full task list into the orchestrator's context window.

**Decision**: Create `task-selector` subagent to isolate task-list.json reads from the orchestrator.

**Implementation**:
- `.claude/agents/task-selector.md` reads task-list.json and returns only the selected task
- `/next-from-task-list` spawns task-selector instead of reading the file directly
- `/dev` verifies task-list.json exists but does not read contents

**Rationale**:
- Task list can be large; loading it pollutes the orchestrator's context
- Subagent explores extensively but returns only a condensed selection
- Aligns with context isolation principle from best practices manual

**Alternative Rejected**: Continue reading task-list.json directly in /next-from-task-list. This pulls unnecessary content into the orchestrator's limited context window.

---

#### 2026-01-30: /map Converted from Command to Skill (R6 Resolution)

**Context**: The `/map` command was implemented as a simple command file. Analysis of Claude Code skills vs commands revealed skills offer additional capabilities: `context: fork` for isolated execution, `agent` specification, `allowed-tools` restrictions, and supporting files.

**Decision**: Convert `/map` from command to skill with forked context and supporting files.

**Implementation**:
- `.claude/skills/map/SKILL.md` - Core skill with frontmatter: `context: fork`, `agent: general-purpose`, `allowed-tools: Read, Write, Grep, Glob, Bash(git *)`
- `.claude/skills/map/template.md` - Standardized exploration artifact format
- `.claude/skills/map/examples/sample.md` - Well-formed example output
- Output artifacts: `_docs/maps/{target-slug}-{YYYYMMDD-HHMMSS}.md`
- Deleted `.claude/commands/map.md`

**Rationale**:
- `context: fork` executes exploration in isolated subagent context, preventing orchestrator token bloat
- `allowed-tools` enforces read-only exploration (Write only for artifact output)
- Supporting files standardize artifact format and provide examples
- Aligns with "orchestrator-managed exploration" pattern from session 7

**Key Finding**: Skills are a strict superset of commands. Both are user-invocable via `/name`, but skills add frontmatter configuration, supporting files, and subagent execution.

**Alternative Rejected**: Keep as command. While functional, commands cannot fork context or specify agent type, missing key architectural benefits.

---

#### 2026-02-01: Dual Workflow Support via Agent Descriptions (R7 Resolution)

**Context**: Subagent descriptions previously used rigid skill-triggered phrasing ("Use when /skill is invoked"), tightly coupling agents to specific skills. This prevented ad-hoc usage where the orchestrator might invoke agents directly after `/map` exploration.

**Decision**: Strengthen agent descriptions with when-to-use framing and make `taskId` optional across workflow agents.

**Implementation**:
- All 6 agent descriptions updated to lead with timing triggers ("Use after...", "Use when...")
- Changed from "Use when /skill is invoked" to "Typically invoked via /skill" (soft coupling)
- Made `taskId` optional in task-planner, test-writer, implementer, code-reviewer
- Output formats handle missing taskId: `Task: [taskId if provided, otherwise taskTitle]`
- Established payload convention: unmarked fields = required; `(optional)` annotation = optional

**Rationale**:
- Descriptions should contain when-to-use information, not what-it-does (per best practices manual Section 6.4)
- Soft coupling enables orchestrator to recognize when to use agents outside skill invocation
- Optional `taskId` allows same agents to serve both task-list and ad-hoc workflows
- Return types in descriptions (APPROVE/REQUEST_CHANGES, TASK_SELECTED) aid orchestrator routing

**Alternative Rejected**: Modify `/plan-task` skill to accept ad-hoc requests. This would add complexity; strengthened descriptions achieve the same goal by enabling orchestrator recognition of the `/map` → task-planner pattern.

---

## Best Practices Alignment

This scaffold follows the AI-Assisted Development Best Practices Manual (v2). Key alignments:

| Practice | Implementation |
|----------|----------------|
| CLAUDE.md under 60 lines | ~53 lines |
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

**Inappropriate content:**
- Project architecture decisions (use CLAUDE.md)
- Code style rules (use linters and hooks)
- Task-specific instructions (use path-scoped rules)

## Known Gaps and Future Improvements

### Resolved

- [x] ~~Extract initializer subagent from /init command~~ (R5: /init-repo skill + task-selector subagent)
- [x] ~~Add CLAUDE.local.md template for personal overrides~~ (documented above)
- [x] ~~Document context clearing strategy~~ (consolidated into /dev; removed /catchup)
- [x] ~~Integrate Explore subagent for read-only context gathering~~ (R6: `/map` skill with `context: fork`)
- [x] ~~Strengthen agent descriptions with when-to-use framing~~ (R7: all 6 agents updated)
- [x] ~~Add SubagentStop hook for progress tracking~~ (R8: `log-subagent.sh` handles SubagentStop, TeammateIdle, TaskCompleted)
- [x] ~~Prevent Husky from overriding core.hooksPath~~ (D-011: `protect-hookspath.sh`)

### Open

- [ ] Add end-to-end testing guidance with puppeteer MCP (R9)
- [ ] Update `_docs/templates/task-list.json` to include v2.0 batch fields (template still uses v1.x schema; batch commands populate v2.0 fields at runtime via `/compute-waves`)

## References

- [AI-Assisted Development Best Practices Manual](../ai-development-best-practices-manual-v2.md)
- [Claude Code Documentation](https://docs.anthropic.com/claude-code)
