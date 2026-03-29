# Worktree

Find or create a named worktree and switch the session into it.

Creates an isolated git worktree branched from the primary tree's current branch. If the worktree already exists (e.g., resuming from a previous session), enters it without re-creating.

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

### Step 2: Detect Existing Worktree

Compute `MAIN_ROOT` and `WORKTREE_PATH`:

```bash
MAIN_ROOT=$(git worktree list --porcelain | head -1 | sed 's/worktree //')
WORKTREE_PATH="$MAIN_ROOT/.claude/worktrees/<name>"
```

Check whether the worktree already exists:

```bash
git worktree list --porcelain | grep "worktree.*\.claude/worktrees/<name>$"
```

- **Match found** --> Go to Step 4 (Enter)
- **No match** --> Go to Step 3 (Create)

### Step 3: Create Worktree

Execute the **Create Worktree** procedure from `.claude/partials/worktree-ops.md` with:
- name: `<name>` (from `$ARGUMENTS`)

If the procedure reports a branch-exists error, stop and surface the error to the user.

On success, the procedure returns `WORKTREE_PATH`, `BRANCH_NAME`, and `SOURCE_BRANCH`.

Switch into the new worktree:

```bash
cd "$WORKTREE_PATH"
```

Report:

```
Worktree "<name>" created.
Branch: worktree-<name> (from <SOURCE_BRANCH>)
Directory: .claude/worktrees/<name>/

Your session is now in the worktree. Run your workflow normally.
When done: /worktree-cleanup
```

### Step 4: Enter Existing Worktree

**4a.** Switch the session directory:

```bash
cd "$WORKTREE_PATH"
```

**4b.** Get current state:

```bash
LAST_COMMIT=$(git log -1 --oneline)
```

**4c.** Report:

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
- Source branch is the primary tree's current branch at creation time; falls back to default branch (then `main`) if in detached HEAD
- Source branch is stored in git config (`worktree.sourceBranch`) for cleanup to read
- To resume work in a worktree from a new session, run `/worktree <name>` again -- it detects the existing worktree and enters it
