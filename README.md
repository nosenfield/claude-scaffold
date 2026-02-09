# Claude Project Scaffold

A scaffolding system for AI-driven software development with Claude Code agents.

## Overview

This scaffold provides a structured workflow for greenfield project development using Claude Code. It implements:

- **Two-agent architecture**: Initialization and development loop separation
- **TDD enforcement**: Tests before implementation with immutable test contracts
- **Memory persistence**: Session history and architectural decisions across context windows
- **Quality gates**: Hook-based enforcement at workflow boundaries
- **Subagent orchestration**: Specialized agents for planning, testing, implementation, review, and memory updates

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
│   └── settings.json    # Hook configuration
├── .githooks/           # Git hooks (version-controlled)
│   ├── pre-commit       # Quality gates (test, lint, typecheck)
│   └── post-commit      # Commit logging, bypass detection
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
├── _scripts/            # Setup scripts (scaffold-only)
│   └── setup-project.sh # Create new project from scaffold
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

Or use `/execute-task` to run the full workflow (steps 2-7) autonomously for a single task.

### Ad-hoc Workflow (Exploratory)

Use for unplanned work or when task list doesn't apply:

1. `/dev [summary]` - Start development session
2. `/map <target>` - Explore relevant codebase area
3. "Plan this" or describe what to build - Orchestrator invokes task-planner
4. `/write-task-tests` - Write failing tests
5. `/implement-task` - Make tests pass
6. `/review-task` - Code review
7. `/commit-task` - Commit changes

The ad-hoc workflow skips `/next-from-task-list` (no task selection) and uses `/map` exploration as input to planning. Both workflows share the same TDD cycle from `/write-task-tests` onward.

**Note**: Run `/init-repo` once after placing project documentation to initialize memory files (`_docs/memory/progress.md`, `_docs/memory/decisions.md`) and validate core docs. Environment setup (dependency installation, dev server configuration) is handled through the first tasks in `task-list.json`.

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
| Hook | Location | Trigger | Purpose |
|------|----------|---------|---------|
| pre-commit | `.githooks/pre-commit` | `git commit` | Runs test, lint, typecheck before commit |
| post-commit | `.githooks/post-commit` | After commit | Logs commits, detects `--no-verify` bypass |

**Configuration**: Hooks use `core.hooksPath` (Git 2.9+) for version-controlled hooks:
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
| Hook-based quality gates | Advisory (PostToolUse) + Git pre-commit |

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

Items identified for potential enhancement:

- [x] ~~Extract initializer subagent from /init command~~ (resolved: /init-repo skill for scaffold setup; task-selector subagent for context isolation)
- [x] ~~Add CLAUDE.local.md template for personal overrides~~ (documented above)
- [x] ~~Document context clearing strategy~~ (consolidated into /dev; removed /catchup)
- [x] ~~Integrate Explore subagent for read-only context gathering~~ (R6 resolved: `/map` skill with `context: fork` and artifact output)
- [x] ~~Strengthen agent descriptions with when-to-use framing~~ (R7 resolved: all 6 agents updated with trigger conditions, payload requirements, and output expectations)
- [x] ~~Add SubagentStop hook for progress tracking~~ (R8 resolved: `.claude/hooks/log-subagent.sh` logs agent type, prompt excerpt, and output excerpt to `.claude/subagent.log`)
- [ ] Add end-to-end testing guidance with puppeteer MCP (R9)

## References

- [AI-Assisted Development Best Practices Manual](../ai-development-best-practices-manual-v2.md)
- [Claude Code Documentation](https://docs.anthropic.com/claude-code)
