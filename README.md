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
│   ├── commands/        # Workflow commands (/init, /dev, /next, etc.)
│   ├── hooks/           # Quality gate scripts
│   ├── rules/           # File protection policies
│   ├── skills/          # Reusable workflow patterns
│   └── settings.json    # Hook configuration
├── _docs/               # Core documentation (read-only for agents)
│   ├── prd.md           # Product requirements template
│   ├── architecture.md  # System design template
│   ├── task-list.json   # Development tasks
│   ├── best-practices.md # Coding standards
│   └── backlog.json     # Deferred issues registry
├── _scripts/            # Git hooks and setup scripts
│   └── pre-commit       # Git pre-commit hook (requires installation)
├── progress.md          # Append-only session history
├── decisions.md         # Append-only decision log
├── CLAUDE.md            # Project context for Claude Code
└── .mcp.json            # MCP server configuration
```

## Development Workflow

1. `/init` - Initialize environment (first time)
2. `/dev` - Start development session (load context)
3. `/next` - Select next task
4. `/plan` - Plan implementation
5. `/test` - Write failing tests
6. `/implement` - Make tests pass
7. `/review` - Code review
8. `/commit` - Commit and update memory

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

#### 2025-01-25: Two-Phase Pre-Commit Quality Gates

**Context**: The scaffold has `.claude/hooks/pre-commit-check.sh` running on Claude's Stop event, but no git-level pre-commit hook. This leaves a gap if commits bypass the Claude workflow.

**Decision**: Implement belt-and-suspenders quality gates at both layers.

**Implementation**:
| Phase | Hook | Trigger | Purpose |
|-------|------|---------|---------|
| Phase 1 | `.claude/hooks/pre-commit-check.sh` | Claude Stop event | Early feedback during Claude workflow |
| Phase 2 | `_scripts/pre-commit` | `git commit` | Final enforcement regardless of commit source |

**Installation** (required for Phase 2):
```bash
cp _scripts/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

**Rationale**:
- Claude's Stop hook provides early feedback during the `/implement` → `/review` → `/commit` cycle
- Git's pre-commit hook ensures quality gates run even for manual commits
- Same checks (test, lint, typecheck) run at both layers for consistency
- Defense-in-depth: if one layer is bypassed, the other catches issues

**Trade-off**: Checks may run twice during `/commit` (once at Stop, once at git commit). Accepted as minor overhead for increased reliability.

---

## Best Practices Alignment

This scaffold follows the AI-Assisted Development Best Practices Manual (v2). Key alignments:

| Practice | Implementation |
|----------|----------------|
| CLAUDE.md under 60 lines | ~53 lines |
| Path-scoped rules | 5 rules in `.claude/rules/` |
| Structured subagent output | All agents define exact output format |
| Test immutability | Triple enforcement: rule + hook + agent instruction |
| Append-only memory | progress.md and decisions.md |
| Hook-based quality gates | Advisory (PostToolUse) + Strict (Stop) |

## Known Gaps and Future Improvements

Items identified for potential enhancement:

- [ ] Scope pre-commit-check.sh to workflow boundaries only
- [ ] Extract initializer subagent from /init command
- [ ] Add CLAUDE.local.md template for personal overrides
- [ ] Document context clearing strategy for long sessions
- [ ] Integrate Explore subagent for read-only context gathering
- [ ] Add end-to-end testing guidance with puppeteer MCP

## References

- [AI-Assisted Development Best Practices Manual](../ai-development-best-practices-manual-v2.md)
- [Claude Code Documentation](https://docs.anthropic.com/claude-code)
