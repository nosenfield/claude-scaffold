# Decision Log

This file records architecture and implementation decisions. Entries are append-only.

---

<!-- New entries are added below this line -->

## 2026-02-03: Active Context Section in progress.md (Memory System Enhancement)

**Context**: Evaluated whether scaffold would benefit from adopting a 6-file granular Memory Bank (projectBrief, productContext, systemPatterns, techContext, activeContext, progress) like the ai-project-template repository.

**Decision**: Add Active Context section to progress.md instead of adopting 6-file granular Memory Bank.

**Analysis**:
- ai-project-template's 6-file structure compensates for lack of subagent isolation (Cursor context)
- Our scaffold already has 6 specialized subagents that isolate context (task-selector, memory-updater, etc.)
- Adding mandatory files would increase session-start token cost
- Best practices manual emphasizes minimal CLAUDE.md (<60 lines) and progressive disclosure
- Session summaries already handle cross-session continuity
- Gap identified: no persistent "current focus" tracking between sessions

**Implementation**:
- Added Active Context section at top of progress.md (replaced on each update, not appended)
- Updated memory-updater agent to maintain Active Context section
- Updated /dev skill to report from Active Context at session start
- Session Log section remains append-only below Active Context

**Structure**:
```
progress.md
├── Active Context (REPLACED on each update)
│   ├── Current Focus
│   ├── Current Task
│   ├── Recent Decisions
│   └── Immediate Next Steps
└── Session Log (APPEND-only)
    └── Timestamped entries
```

**Rejected Alternative**: Adopting 6-file granular Memory Bank. Would add overhead without solving problems our subagent architecture already handles.

---

## 2026-01-26: Environment Setup via Task List (R5 Resolution)

**Context**: Evaluated R5 recommendation to extract `/init` into a dedicated initializer subagent, based on Anthropic's "two-agent architecture" pattern.

**Decision**: Remove `/init` command entirely; handle setup through standard task list.

**Analysis**:
- Anthropic's initializer agent (from "Effective harnesses for long-running agents") is designed for autonomous spec-to-feature decomposition
- Our workflow assumes human-provided documentation (prd.md, architecture.md, task-list.json)
- The "pure coordinator" principle cited in the recommendation is from practitioner literature, not official Anthropic guidance
- Environment setup in our scaffold is validation-based, not generative

**Implementation**:
- `/dev` skill handles fresh project state (missing memory files)
- `task-list.json` template includes setup tasks as TASK-001 through TASK-003
- All tasks flow through standard loop: /next → /plan → /implement → /review

**Rejected Alternative**: Extracting setup to subagent would add complexity without capability gain.

---
