# Worktree

Find or create a named worktree and switch the session into it.

Creates an isolated git worktree branched from the repository's default branch. If the worktree already exists (e.g., resuming from a previous session), enters it without re-creating.

## Usage

`/worktree $ARGUMENTS`

`$ARGUMENTS` is the worktree name (required). Example: `/worktree bugfix-auth`

## Workflow

### Step 1: Parse Arguments

Extract `<name>` from `$ARGUMENTS`. If empty, report error and stop:

```
Error: Worktree name required.
Usage: /worktree <name>
```

### Step 2: Determine Repository State

```bash
MAIN_ROOT=$(git worktree list --porcelain | head -1 | sed 's/worktree //')
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"
WORKTREE_PATH="$MAIN_ROOT/.claude/worktrees/<name>"
BRANCH_NAME="worktree-<name>"
```

### Step 3: Detect Existing Worktree

```bash
git worktree list --porcelain | grep "worktree.*\.claude/worktrees/<name>$"
```

- **Match found** --> Go to Step 5 (Enter)
- **No match** --> Go to Step 4 (Create)

### Step 4: Create Worktree

**4a.** Validate that branch `worktree-<name>` does not already exist (orphan from prior incomplete cleanup):

```bash
git branch --list "worktree-<name>"
```

If it exists, report error and stop:

```
Branch worktree-<name> already exists but no worktree found.
This may be from incomplete cleanup. To fix:
  git branch -D worktree-<name>
Then retry /worktree <name>
```

**4b.** Create the worktree from the default branch:

```bash
git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME" "$DEFAULT_BRANCH"
```

This creates a new directory and branch without touching the primary tree's HEAD or checked-out branch.

**4c.** Switch the session directory:

```bash
cd "$WORKTREE_PATH"
```

**4d.** Run bootstrap if available:

```bash
if [ -x "$MAIN_ROOT/_scripts/bootstrap-worktree.sh" ]; then
  "$MAIN_ROOT/_scripts/bootstrap-worktree.sh" "$WORKTREE_PATH"
fi
```

If the script does not exist, skip silently. Pre-existing projects without the script are a normal case.

**4e.** Report:

```
Worktree "<name>" created.
Branch: worktree-<name> (from <default-branch>)
Directory: .claude/worktrees/<name>/

Your session is now in the worktree. Run your workflow normally.
When done: /worktree-cleanup
```

### Step 5: Enter Existing Worktree

**5a.** Switch the session directory:

```bash
cd "$WORKTREE_PATH"
```

**5b.** Get current state:

```bash
LAST_COMMIT=$(git log -1 --oneline)
```

**5c.** Report:

```
Entered worktree "<name>".
Branch: worktree-<name>
Last commit: <LAST_COMMIT>

Your session is now in the worktree. Continue your workflow.
When done: /worktree-cleanup
```

No bootstrap during enter -- dependencies were installed during creation.

## State Management

- The ad-hoc workflow (`/plan-task`, `/write-task-tests`, `/implement-task`, `/review-task`, `/commit-task`) runs inside the worktree. `/commit-task` detects the worktree and skips the memory-updater spawn; git commit proceeds normally.
- Each worktree has its own git index. Staging and commits are fully isolated from the primary tree.
- The commit lock in `/commit-implementation` is retained but will not contend with the primary tree (separate index, separate branch).
- **Memory**: The orchestrator's conversation context persists across the worktree boundary. Do NOT run `/dev` inside the worktree -- the session already has context from before entering. `/worktree-cleanup` spawns the memory-updater after returning to the main tree, where `_docs/memory/` files are current. Worktree memory files on disk are stale and should be ignored.
- Ignored dependencies (`node_modules`, `venv`, etc.) are not present in a fresh worktree. The bootstrap script reinstalls them during creation.

## Notes

- Worktree directories: `.claude/worktrees/<name>/`
- Worktree branches: `worktree-<name>`
- Default branch detection falls back to `main` if `origin/HEAD` is not set
- To resume work in a worktree from a new session, run `/worktree <name>` again -- it detects the existing worktree and enters it
