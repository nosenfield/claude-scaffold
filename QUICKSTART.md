# SnakeBreaker-Claude-Batched: Quickstart Guide

This document tracks the setup and workflow execution for validating the batch workflow scaffold.

---

## Phase 1: Project Setup (Completed)

### Step 1: Run setup-project.sh

```bash
cd /path/to/claude-project-template/scaffold
./_scripts/setup-project.sh SnakeBreaker-Claude-Batched
```

**Expected**: Creates new project directory with scaffold infrastructure.

**Actual**: Project created at `/Users/nosenfield/Desktop/Cursor Projects/SnakeBreaker-Claude-Batched`

**Discrepancies**: None observed.

---

### Step 2: Add Core Documentation

Added project-specific documentation:
- `_docs/prd.md` - Product requirements
- `_docs/architecture.md` - System design
- `_docs/task-list.json` - Development tasks (37 tasks, 14 waves)
- `_docs/best-practices.md` - Coding standards

Set Claude signature in CLAUDE.md.

**Commits**:
- `b827639` - adds starting documentation
- `12681c4` - reset task-list.json
- `b033677` - sets signature divider

**Discrepancies**: None observed.

---

### Step 3: Run /init-repo

```bash
/init-repo
```

**Expected**: Initializes scaffold memory files, validates documentation.

**Actual**: Memory files created/updated in `_docs/memory/`.

**Discrepancies**:
- Memory files have template placeholders (`[DATE]`) that were not replaced with actual dates.

---

## Phase 2: Development Workflow (In Progress)

### Step 4: Start Development Session

```bash
/dev
```

**Expected**: Loads memory files, reports session status, shows current task and next steps.

**Actual**: Session started successfully. Memory files loaded.

**Discrepancy D-002**: Recommended `/next-from-task-list` (single-task) instead of `/next-batch-from-list` (batch) despite v2.0.0 schema with waveSummary present.

---

### Step 5: Execute Batch (Autonomous)

```bash
/batch-execute-task-auto
```

**Note**: This command handles task selection internally (no need for separate `/next-batch-from-list`).

**Expected**: Spawns teammate agents for each task, executes in parallel, collects results.

**Actual**:
- TASK-001 assigned to `worker-001`
- Task marked `in-progress` in task-list.json
- Teammate stalled silently - no files created, no result reported

**Root Cause (D-004)**: Orchestrator prompt to teammate is underspecified. See analysis below.

---

### Step 5a: Diagnose Teammate Stall

**Investigation**:
1. Researched Claude Code hooks for teammate logging
2. Empirically verified `SubagentStop` fires for teammates (spawned test teammate in scaffold repo)
3. Analyzed `batch-execute-task-auto.md` and `execute-task-from-batch.md` communication flow

**Findings**:
- `SubagentStop` hook already captures teammate events (name, ID, prompt)
- D-003 revised: `TeammateIdle` IS valid but not needed (SubagentStop suffices)
- D-004 identified: orchestrator prompt construction is the root cause

**D-004 Details**: The orchestrator tells the teammate to "run `/execute-task-from-batch`" but:
1. Does not construct a self-contained prompt with task context
2. Does not include explicit `SendMessage` instruction for result reporting
3. Teammate is an independent Claude Code process that needs everything in the prompt

**Required Fix**: Update `batch-execute-task-auto.md` step 3c and `execute-task-from-batch.md` Phase 6.

---

## Discrepancy Log

See [scaffold-run-0-notes.md](_docs/context-summaries/scaffold-run-0-notes.md) for detailed discrepancy tracking.

**Summary**: 4 issues found
- D-001 (LOW): `/init-repo` does not replace `[DATE]` placeholders
- D-002 (MEDIUM): `/dev` recommends single-task instead of batch workflow
- D-003 (LOW, revised): `TeammateIdle` hook not configured; `SubagentStop` already covers teammates
- D-004 (HIGH): Teammate stall - underspecified prompt in batch orchestrator

---

## Workflow Reference

### Single Task Workflow
```
/dev -> /next-from-task-list -> /plan-task -> /write-task-tests -> /implement-task -> /review-task -> /commit-task
```

### Batch Workflow
```
/dev -> /next-batch-from-list -> /batch-execute-task-auto
```

Each teammate in batch workflow executes:
```
/execute-task-from-batch (includes: plan -> tests -> implement -> review -> commit)
```
