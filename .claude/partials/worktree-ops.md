# Worktree Operations

Centralized procedures for creating, merging, and removing git worktrees. Referenced by `/worktree`, `/worktree-cleanup`, `/execute-one-wave`, and `/batch-execute-task-auto`.

---

## Procedure: Create Worktree

**Parameters:**
- `name` (required): worktree name (e.g., `TASK-007` or `bugfix-auth`)
- `source_ref` (optional): branch or ref to branch from. Defaults to primary tree's current branch (fallback: default branch, then `main`)

**Steps:**

1. Determine main tree root:
   ```bash
   MAIN_ROOT=$(git worktree list --porcelain | head -1 | sed 's/worktree //')
   ```

2. Determine source ref (if not provided by caller):
   ```bash
   SOURCE_BRANCH=$(git -C "$MAIN_ROOT" branch --show-current)
   ```
   If empty (detached HEAD):
   ```bash
   SOURCE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
   SOURCE_BRANCH="${SOURCE_BRANCH:-main}"
   ```

3. Set paths:
   ```bash
   WORKTREE_PATH="$MAIN_ROOT/.claude/worktrees/<name>"
   BRANCH_NAME="worktree-<name>"
   ```

4. Validate branch does not exist:
   ```bash
   git branch --list "worktree-<name>"
   ```
   If the branch exists, stop and report error:
   ```
   Error: Branch worktree-<name> already exists but no worktree was found.
   This may be from incomplete cleanup. To fix:
     git branch -D worktree-<name>
   Then retry.
   ```

5. Create worktree:
   ```bash
   git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME" "$SOURCE_BRANCH"
   ```

6. Store source branch (requires `worktreeConfig` extension):
   ```bash
   git config extensions.worktreeConfig true
   git -C "$WORKTREE_PATH" config --worktree worktree.sourceBranch "$SOURCE_BRANCH"
   ```

7. Bootstrap (if script exists):
   ```bash
   if [ -x "$MAIN_ROOT/_scripts/bootstrap-worktree.sh" ]; then
     "$MAIN_ROOT/_scripts/bootstrap-worktree.sh" "$WORKTREE_PATH"
   fi
   ```
   If the script does not exist, skip silently.

**Returns:** `WORKTREE_PATH`, `BRANCH_NAME`, `SOURCE_BRANCH`

---

## Procedure: Merge Worktree

**Parameters:**
- `name` (required): worktree name
- `target_branch` (optional): branch to merge into. Defaults to the stored `worktree.sourceBranch` config value, then the default branch

**Steps:**

1. Determine main tree root:
   ```bash
   MAIN_ROOT=$(git worktree list --porcelain | head -1 | sed 's/worktree //')
   ```

2. Set paths:
   ```bash
   WORKTREE_PATH="$MAIN_ROOT/.claude/worktrees/<name>"
   BRANCH_NAME="worktree-<name>"
   ```

3. Determine target branch:
   ```bash
   TARGET_BRANCH=$(git -C "$WORKTREE_PATH" config --worktree worktree.sourceBranch 2>/dev/null)
   ```
   If empty: use the `target_branch` parameter if provided, otherwise fall back to:
   ```bash
   DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
   TARGET_BRANCH="${DEFAULT_BRANCH:-main}"
   ```

4. Check primary tree's current branch:
   ```bash
   PRIMARY_BRANCH=$(git -C "$MAIN_ROOT" branch --show-current)
   ```

5a. If `PRIMARY_BRANCH == TARGET_BRANCH` (common case):
   ```bash
   git -C "$MAIN_ROOT" merge "$BRANCH_NAME" --no-ff -m "Merge $BRANCH_NAME into $TARGET_BRANCH"
   ```

5b. If `PRIMARY_BRANCH != TARGET_BRANCH` (another session is using the primary tree):
   ```bash
   git worktree add "$MAIN_ROOT/.claude/worktrees/_merge-tmp" "$TARGET_BRANCH"
   git -C "$MAIN_ROOT/.claude/worktrees/_merge-tmp" merge "$BRANCH_NAME" --no-ff -m "Merge $BRANCH_NAME into $TARGET_BRANCH"
   git worktree remove "$MAIN_ROOT/.claude/worktrees/_merge-tmp"
   ```

6. On merge conflict: return `MERGE_CONFLICT` with the list of conflicting files. Do not remove the worktree.

7. On success: remove worktree and branch:
   ```bash
   git worktree remove "$WORKTREE_PATH"
   git branch -d "$BRANCH_NAME"
   ```

**Returns:** `MERGE_SUCCESS` with merge commit SHA, or `MERGE_CONFLICT` with conflicting file list

---

## Procedure: Remove Worktree

**Parameters:**
- `name` (required): worktree name

**Steps:**

1. Determine main tree root:
   ```bash
   MAIN_ROOT=$(git worktree list --porcelain | head -1 | sed 's/worktree //')
   ```

2. Force-remove worktree and delete branch:
   ```bash
   git worktree remove "$MAIN_ROOT/.claude/worktrees/<name>" --force
   git branch -D "worktree-<name>"
   ```

**Returns:** (none)
