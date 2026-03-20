# Plan: Integrate Git Worktrees for Ad-hoc Workflows

Date: 2026-03-10
Status: Pending approval
Confidence: High
Tests Required: No
Supersedes: `_docs/plans/worktree-adhoc-integration.md`

---

## Summary

Create a `/worktree` command that creates a named git worktree from `main`, switches the session's working directory into it, and on completion merges back and cleans up. This enables isolated parallel ad-hoc development alongside batch execution or other ad-hoc work.

---

## Context

The scaffold's batch execution has empirically validated isolation (contention detection, specific-file staging, commit lock). Worktree isolation for batch is deferred (see `_docs/notes/worktree-deepdive.md`).

Ad-hoc development has no isolation mechanism. If a developer runs batch execution on the task list while simultaneously doing a bug fix or prototype, there is no way to prevent filesystem interference. Worktrees fill this gap with low implementation cost.

### Target Use Case

1. User is on branch `some-feature` with an active Claude Code instance (A) performing ad-hoc development
2. User opens a **new** Claude Code instance (B) and runs `/worktree create <name>`
3. Instance B creates a worktree from `main` and works in complete filesystem isolation
4. Both instances operate simultaneously without interference

---

## Affected Files

| File | Action | Purpose |
|------|--------|---------|
| `_scripts/bootstrap-worktree.sh` | New | Project-customizable worktree environment setup (dependency install, build artifacts) |
| `.claude/commands/worktree.md` | New | `/worktree` command: create, enter, merge, discard named worktrees |
| `.gitignore` | Edit | Add `.claude/worktrees/` |
| `_scripts/setup-project.sh` | Edit | Copy `bootstrap-worktree.sh` into new projects |
| `README.md` | Edit | Document `/worktree` in commands table and ad-hoc workflow section |
| `QUICKSTART.md` | Edit | Add worktree-isolated ad-hoc example |

---

## Dependencies

- `git` CLI with worktree support (standard; no version constraint)

### Why Not `EnterWorktree`

Claude Code's `EnterWorktree` tool creates a worktree from the current HEAD. The target use case requires branching from `main` while the primary tree may be on any branch. Switching the primary tree to `main` first (via `git checkout`) would disrupt any concurrent instance working in that tree. Using `git worktree add` with an explicit base ref avoids touching the primary tree's checked-out branch entirely.

The tradeoff: we lose `EnterWorktree`'s automatic exit-prompt cleanup, but the `/worktree merge` and `/worktree discard` sub-commands fully own the lifecycle via git CLI.

---

## Implementation Steps

### Step 1: Create `_scripts/bootstrap-worktree.sh`

New file with executable permissions. Accepts the worktree path as its first argument. Default implementation:

```bash
#!/bin/bash
# Bootstrap a git worktree with project dependencies.
#
# Called by /worktree create after the worktree directory is created.
# Customize this script for your project's dependency manager and build tools.
#
# Usage: bootstrap-worktree.sh <worktree-path>

set -e

WORKTREE_PATH="${1:?Usage: bootstrap-worktree.sh <worktree-path>}"

# Node.js
if [ -f "$WORKTREE_PATH/package.json" ]; then
  echo "Installing Node dependencies..."
  (cd "$WORKTREE_PATH" && npm install --silent)
fi

# Python (virtualenv)
if [ -f "$WORKTREE_PATH/requirements.txt" ]; then
  echo "Installing Python dependencies..."
  (cd "$WORKTREE_PATH" && python3 -m venv .venv && .venv/bin/pip install -q -r requirements.txt)
fi

# Ruby (Bundler)
if [ -f "$WORKTREE_PATH/Gemfile" ]; then
  echo "Installing Ruby dependencies..."
  (cd "$WORKTREE_PATH" && bundle install --quiet)
fi
```

The script runs from the primary tree root (not from inside the worktree) and receives the worktree's absolute path. Projects customize this file for their specific needs -- the defaults cover common ecosystems.

### Step 2: Create `.claude/commands/worktree.md`

New command file with the following structure:

**Usage section**: Document `$ARGUMENTS` as required. Supported sub-commands:
- `/worktree create <name>` -- create and enter a new worktree
- `/worktree enter <name>` -- enter an existing worktree (for resuming across sessions)
- `/worktree merge [name]` -- merge back into `main` and clean up
- `/worktree discard [name]` -- abandon and clean up

For `enter`, `merge`, and `discard`, `[name]` is optional if the session is currently inside a worktree (infer from the current branch name by stripping the `worktree-` prefix).

**Branch naming**: All worktree branches use the convention `worktree-<name>`. Worktree directories are placed at `.claude/worktrees/<name>/`.

**Intended usage**: The user opens a new Claude Code instance and runs `/worktree create <name>` as the first command. This should be the first action in the new instance to avoid accidental interaction with the primary working tree.

---

#### Phase: Create

Uses `git worktree add` directly to create a worktree from the default branch without modifying the primary tree's checked-out branch. This is safe to run while other instances are working in the primary tree.

1. Determine the repository's default branch:
   ```bash
   git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'
   ```
   Fall back to `main` if the above fails.

2. Validate preconditions:
   - Verify `.claude/worktrees/<name>/` does not already exist
   - Verify branch `worktree-<name>` does not already exist

3. Create the worktree with an explicit base ref:
   ```bash
   git worktree add .claude/worktrees/<name> -b worktree-<name> <default-branch>
   ```
   This creates a new worktree directory and branch from `<default-branch>` without touching the primary tree's HEAD or checked-out branch.

4. Switch the session's working directory:
   ```bash
   cd .claude/worktrees/<name>
   ```

5. Run bootstrap script from the **main tree root** (the script exists in the primary tree, not the worktree):
   ```bash
   <main-tree-root>/_scripts/bootstrap-worktree.sh <absolute-path-to-worktree>
   ```
   Skip with warning if `_scripts/bootstrap-worktree.sh` does not exist (pre-existing projects that haven't adopted this file).

6. Confirm to user:
   ```
   Worktree "<name>" created.
   Branch: worktree-<name> (from <default-branch>)
   Directory: .claude/worktrees/<name>/

   Run your ad-hoc workflow normally (/plan-task, /implement-task, etc.).
   When done: /worktree merge   or   /worktree discard
   ```

---

#### Phase: Enter

Resumes work in an existing worktree across a new Claude Code session. Used when a session ends (context limit, crash, user closes it) and the user needs to continue in the same worktree.

1. User invokes `/worktree enter <name>` (or `/worktree enter` if name can be inferred).

2. Verify the worktree exists:
   ```bash
   git worktree list | grep ".claude/worktrees/<name>"
   ```
   If not found, report error with `git worktree list` output.

3. Switch the session's working directory:
   ```bash
   cd .claude/worktrees/<name>
   ```

4. Confirm to user:
   ```
   Entered worktree "<name>".
   Branch: worktree-<name>
   Last commit: <short log of HEAD>

   Continue your ad-hoc workflow (/plan-task, /implement-task, etc.).
   When done: /worktree merge   or   /worktree discard
   ```

No bootstrap is run during `enter` -- dependencies were installed during `create`.

---

#### Phase: Merge

Merges the worktree branch into the default branch without switching what the primary tree has checked out. This is safe to run while other instances are working in the primary tree.

1. User invokes `/worktree merge [name]` after completing work.

2. Determine the worktree name:
   - If `[name]` provided, use it.
   - If omitted, infer from the current branch: `git branch --show-current` should be `worktree-<name>`; strip the prefix.
   - If inference fails, report error and ask user to provide the name.

3. Determine the repository root (main tree):
   ```bash
   git worktree list --porcelain | head -1 | sed 's/worktree //'
   ```

4. Determine the default branch (same logic as Create step 1).

5. Check whether the primary tree currently has the default branch checked out:
   ```bash
   git -C <main-tree-root> branch --show-current
   ```

6. **If the primary tree is on the default branch** (no other instance working on a different branch):
   ```bash
   git -C <main-tree-root> merge worktree-<name> --no-ff -m "Merge worktree-<name> into <default-branch>"
   ```

7. **If the primary tree is on a different branch** (another instance may be using it):
   Merging into the default branch requires it to be checked out somewhere. Create a temporary worktree for the merge:
   ```bash
   git worktree add .claude/worktrees/_merge-tmp <default-branch>
   git -C .claude/worktrees/_merge-tmp merge worktree-<name> --no-ff -m "Merge worktree-<name> into <default-branch>"
   git worktree remove .claude/worktrees/_merge-tmp
   ```
   This performs the merge on the default branch without disturbing the primary tree's checked-out branch.

8. On success:
   ```bash
   git worktree remove .claude/worktrees/<name>
   git branch -d worktree-<name>
   ```
   Confirm to user: merged into `<default-branch>`, worktree removed.

9. On merge conflict: stop and report. Print the conflicting files. Do not roll back. Instruct user to resolve conflicts and then manually clean up with `git worktree remove` and `git branch -d`.

---

#### Phase: Discard

1. User invokes `/worktree discard [name]` to abandon work.

2. Determine the worktree name (same inference logic as Merge step 2).

3. Determine the repository root (same logic as Merge step 3).

4. If the session is currently inside the worktree being discarded, `cd` to the main tree root first.

5. Clean up:
   ```bash
   git worktree remove .claude/worktrees/<name> --force
   git branch -D worktree-<name>
   ```

6. Confirm to user: worktree and branch removed.

---

#### State Management

Document in the command file:
- The existing ad-hoc workflow (`/plan-task`, `/write-task-tests`, `/implement-task`, `/review-task`, `/commit-task`) runs unchanged inside the worktree once the session directory has switched.
- Each worktree has its own git index. Staging and commits are fully isolated from the primary tree.
- The commit lock in `commit-implementation.md` is retained but will not contend with the primary tree (separate index, separate branch).
- **Memory files**: `_docs/memory/` files are git-excluded and stale in worktrees. No seeding is needed. The orchestrator's conversation context persists across the worktree boundary. `/dev` should NOT be called inside the worktree. Memory updates are written after `/worktree-cleanup` returns the session to the main tree, where `_docs/memory/` files are current.
- **Ignored dependencies** (`node_modules`, `venv`, etc.) are not present in a fresh worktree. The bootstrap script (`_scripts/bootstrap-worktree.sh`) reinstalls them during `/worktree create`.

---

### Step 3: Add `.claude/worktrees/` to `.gitignore`

Add after line 22 (under the existing "Ephemeral lock/marker files" comment block):

```
.claude/worktrees/
```

This prevents worktree directories from appearing as untracked files in the main tree.

### Step 4: Update `_scripts/setup-project.sh`

Add a second `cp` line after line 85 (which copies `poll-inbox.sh`):

```bash
cp "$SCAFFOLD_DIR"/_scripts/bootstrap-worktree.sh _scripts/
```

The existing `chmod +x _scripts/*` on line 86 already covers new scripts in the directory.

### Step 5: Update `README.md`

**Commands table** (after line 231, the last batch command row):

Add a new section:

```markdown
### Commands -- Worktree (Ad-hoc Isolation)

| Command | Purpose |
|---------|---------|
| `/worktree create <name>` | Create named worktree from `main` and switch into it |
| `/worktree enter <name>` | Resume work in an existing worktree |
| `/worktree merge [name]` | Merge worktree branch into `main` and clean up |
| `/worktree discard [name]` | Abandon worktree and delete branch |
```

**Ad-hoc Workflow section** (after line 262): Add a subsection:

```markdown
#### Worktree-Isolated Ad-hoc (Parallel)

Use when performing ad-hoc work alongside batch execution or another active session:

1. Open a **new Claude Code instance**
2. `/worktree create <name>` - Create isolated worktree from `main`
3. `/plan-task <description>` - Plan implementation
4. `/write-task-tests` - Write failing tests
5. `/implement-task` - Make tests pass
6. `/review-task` - Code review
7. `/commit-task` - Commit changes (commits to worktree branch)
8. `/worktree merge` - Merge into `main` and clean up

The original instance continues undisturbed in the primary working tree.
```

### Step 6: Update `QUICKSTART.md`

Add after line 92 (after the ad-hoc one-liner):

```markdown
**Ad-hoc in worktree (parallel-safe)**:
```
(new instance) /worktree create <name> -> /plan-task <description> -> ... -> /commit-task -> /worktree merge
```
```

---

## Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Merge conflicts when merging worktree branch into `main` | Low | Merge phase reports conflicts and stops; user resolves manually |
| Dependency install overhead per worktree | Low | Bootstrap runs only when dependency files exist; script is customizable per project |
| `bootstrap-worktree.sh` missing in pre-existing projects | Low | Create phase checks for script existence; skips bootstrap with warning if absent |
| Memory files in worktree are stale | Low | Orchestrator context persists across worktree boundary; memory written after cleanup returns to main tree. `/dev` must not be called inside worktree. |
| Temporary merge worktree left behind on conflict | Low | Merge phase documents cleanup instructions; `_merge-tmp` is a known name for manual removal |

---

## What Does Not Change

- Batch execution workflow (no worktrees; existing isolation layers retained)
- Single-task workflow (`/execute-task`, `/execute-task-auto`)
- All agent definitions
- Commit lock (`git-commit-lock.sh`) -- retained for all workflows
- Contention detection (`compute-waves.md`)
- Memory update paths (orchestrator-only writes)
- Pre-commit hooks and quality gates
- `_scripts/setup-project.sh` (edited only to add bootstrap copy line)

---

## Changes from Previous Plans

### From `worktree-adhoc-integration.md` (original plan)

| Finding | Severity | Resolution |
|---------|----------|------------|
| `EnterWorktree` branches from HEAD, not `main` | HIGH | Replaced `EnterWorktree` with `git worktree add ... <default-branch>` |
| Branch name mismatch (`feature/<name>` vs `worktree-<name>`) | HIGH | All references use `worktree-<name>` consistently |
| `bootstrap-worktree.sh` path broken after directory switch | MEDIUM | Bootstrap is now inline in the command, runs after `cd` into worktree |
| Merge/discard lifecycle conflict with `EnterWorktree` exit prompt | MEDIUM | `EnterWorktree` eliminated; command fully owns lifecycle via git CLI |
| Implicit merge target branch | LOW | Merge phase explicitly targets the default branch |
| `bootstrap-worktree.sh` over-engineered | LOW | Removed separate script; inline conditional. Removed `setup-project.sh` edit |

### From first revision (vet feedback)

| Finding | Severity | Resolution |
|---------|----------|------------|
| `git checkout <default-branch>` in Create disrupts concurrent instances | HIGH | Replaced `EnterWorktree` + checkout with `git worktree add` which never touches the primary tree's HEAD |
| `git -C <main-tree-root> checkout <default-branch>` in Merge disrupts concurrent instances | HIGH | Merge phase now detects primary tree's current branch; uses temporary merge worktree when default branch is not checked out |

### From second revision (session continuity + ignored files)

| Finding | Severity | Resolution |
|---------|----------|------------|
| No way to resume worktree work across Claude Code sessions | MEDIUM | Added `/worktree enter <name>` sub-command |
| Worktrees lack gitignored dependencies (`node_modules`, `venv`, etc.) | MEDIUM | Restored `bootstrap-worktree.sh` as project-customizable script; covers Node, Python, Ruby by default |
| Inline Node-only bootstrap insufficient for project-agnostic scaffold | MEDIUM | Bootstrap script replaces inline conditional; projects customize for their ecosystem |
| Memory files are stale in worktrees (initial-commit versions, not current) | LOW | Documented as acceptable: worktree is independent work stream, `/dev` still starts, ad-hoc workflow builds own context |
