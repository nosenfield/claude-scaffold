# Plan: Integrate Git Worktrees for Ad-hoc Workflows

Date: 2026-03-10
Status: Pending approval
Confidence: High
Tests Required: No

---

## Summary

Create a `/worktree` command that creates a named git worktree, switches the session's working directory into it, and on completion merges back and cleans up. This enables isolated parallel ad-hoc development alongside batch execution.

---

## Context

The scaffold's batch execution has empirically validated isolation (contention detection, specific-file staging, commit lock). Worktree isolation for batch is deferred (see `_docs/notes/worktree-deepdive.md`).

Ad-hoc development has no isolation mechanism. If a developer runs batch execution on the task list while simultaneously doing a bug fix or prototype, there is no way to prevent filesystem interference. Worktrees fill this gap with low implementation cost and native Claude Code support via `EnterWorktree`.

---

## Affected Files

| File | Action | Purpose |
|------|--------|---------|
| `_scripts/bootstrap-worktree.sh` | New | Project-customizable worktree environment setup (default: `npm install` if `package.json` present) |
| `.claude/commands/worktree.md` | New | `/worktree` command: create, merge, discard named worktrees |
| `.gitignore` | Edit | Add `.claude/worktrees/` |
| `_scripts/setup-project.sh` | Edit | Copy `bootstrap-worktree.sh` into new projects |
| `README.md` | Edit | Document `/worktree` in ad-hoc workflow and commands table |
| `QUICKSTART.md` | Edit | Add worktree-isolated ad-hoc example |

---

## Dependencies

- Claude Code `EnterWorktree` tool (available to main session; confirmed in `worktree-deepdive.md` section 2.2)
- `git` CLI with worktree support (standard; no version constraint)
- `_scripts/bootstrap-worktree.sh` must exist before `/worktree` command can call it; both are new in this task

---

## Implementation Steps

### Step 1: Create `_scripts/bootstrap-worktree.sh`

New file with executable permissions. Default implementation:
- Accepts worktree path as first argument
- Runs `npm install --silent` if `package.json` exists in the worktree path
- Header comment documents how to override for non-Node projects (e.g., `pip install`, `bundle install`)

Shared by both the ad-hoc `/worktree` command and the future batch worktree path (if ever implemented).

### Step 2: Create `.claude/commands/worktree.md`

New command file with the following structure:

**Usage section**: Document `$ARGUMENTS` as required. Supported sub-commands:
- `/worktree <name>` or `/worktree create <name>` -- create and enter
- `/worktree merge <name>` -- merge back and clean up
- `/worktree discard <name>` -- abandon and clean up

**Branch base**: Worktrees are always created from the current tip of `main` (or the repository's default branch), regardless of which branch the primary working tree is on. This ensures ad-hoc work starts from a clean, shared baseline.

**Intended usage**: The user opens a new Claude Code instance and runs `/worktree create <name>` as the first command. This should be the first action in the new instance to avoid accidental interaction with the primary working tree. The user then performs ad-hoc development inside the worktree while other instances continue working in the primary working tree undisturbed.

**Phase: Create**

`EnterWorktree` handles both worktree creation and session directory switch as a single operation. It branches from the default remote branch, which matches the "always from main" requirement. The command is a thin wrapper:

1. Call `EnterWorktree` with `name: <name>`. This creates `.claude/worktrees/<name>/` on branch `worktree-<name>`, branching from the default remote branch, and switches the session's working directory into it.
2. Run `_scripts/bootstrap-worktree.sh .claude/worktrees/<name>` (skip with warning if script missing)
3. Confirm success to user

**Phase: Merge**
1. User invokes `/worktree merge <name>` after completing work
2. If the session is currently inside a worktree, `cd` back to the main tree root first (detect via `git rev-parse --show-toplevel` and compare against the repository root)
3. Run `git merge feature/<name> --no-ff --no-edit` from the main tree
4. On success: `git worktree remove .claude/worktrees/<name>` and `git branch -d feature/<name>`
5. On conflict: stop and report for user resolution; do not roll back

**Phase: Discard**
1. User invokes `/worktree discard <name>` to abandon work
2. If the session is currently inside the worktree being discarded, `cd` back to the main tree root first
3. Run `git worktree remove .claude/worktrees/<name> --force`
4. Run `git branch -D feature/<name>`
5. Confirm cleanup to user

**State management section**: Document that the existing ad-hoc workflow (`/plan-task`, `/write-task-tests`, `/implement-task`, `/review-task`, `/commit-task`) runs unchanged inside the worktree once the session directory has switched. The commit lock in `commit-implementation.md` is retained for ad-hoc work inside worktrees (single-session, no contention).

### Step 3: Add `.claude/worktrees/` to `.gitignore`

Add under the existing "Ephemeral lock/marker files" comment block. Prevents worktree directories from appearing as untracked files in the main tree.

### Step 4: Update `_scripts/setup-project.sh`

Add a second `cp` line after line 85 of `setup-project.sh` (which copies `poll-inbox.sh`):

```bash
cp "$SCAFFOLD_DIR"/_scripts/bootstrap-worktree.sh _scripts/
```

The existing `chmod +x _scripts/*` on line 86 already covers new scripts in the directory.

### Step 5: Update `README.md`

- Add `/worktree` to the Commands table with purpose: "Create/merge/discard named worktree for isolated ad-hoc development"
- Update the Ad-hoc Workflow section to document worktree-isolated usage

### Step 6: Update `QUICKSTART.md`

Add a worktree-isolated variant to the Ad-hoc section showing:
1. `/worktree <name>` before `/plan-task <description>`
2. Normal ad-hoc workflow inside the worktree
3. `/worktree merge <name>` after `/commit-task`

---

## Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| `bootstrap-worktree.sh` missing in pre-existing projects | Low | `/worktree` checks for script existence; skips bootstrap with warning if absent |
| Stale commit lock blocks ad-hoc commit inside worktree | Low | Existing 5-minute auto-break in `git-commit-lock.sh` handles this; no new code needed |
| `npm install` overhead per worktree | Low | Bootstrap is optional and skippable; exploratory work may not need it |

---

## What Does Not Change

- Batch execution workflow (no worktrees; existing isolation layers retained)
- Single-task workflow (`/execute-task`, `/execute-task-auto`)
- All agent definitions
- Commit lock (`git-commit-lock.sh`) -- retained for all workflows
- Contention detection (`compute-waves.md`)
- Memory update paths (orchestrator-only writes)
- Pre-commit hooks and quality gates
