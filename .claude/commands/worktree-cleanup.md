# Worktree Cleanup

Merge or discard a worktree. Prompts the user for their choice.

## Usage

`/worktree-cleanup $ARGUMENTS`

`$ARGUMENTS` is the worktree name (optional if currently inside a worktree).

## Workflow

### Step 1: Determine Worktree Name

```bash
MAIN_ROOT=$(git worktree list --porcelain | head -1 | sed 's/worktree //')
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"
```

**If `$ARGUMENTS` is provided**: Use it as `<name>`.

**If `$ARGUMENTS` is empty**: Check if currently inside a worktree:

```bash
if [[ "$PWD" == *"/.claude/worktrees/"* ]]; then
  BRANCH=$(git branch --show-current)
  NAME=${BRANCH#worktree-}
fi
```

If inference fails, report error and stop:

```
Error: Cannot determine worktree name.
Either run this command from inside the worktree, or provide the name:
  /worktree-cleanup <name>
```

### Step 2: Validate Worktree Exists

```bash
WORKTREE_PATH="$MAIN_ROOT/.claude/worktrees/<name>"
git worktree list --porcelain | grep "worktree.*\.claude/worktrees/<name>$"
```

If not found, report error with `git worktree list` output.

### Step 3: Show Summary and Prompt User

Display worktree state:

```bash
LAST_COMMIT=$(git -C "$WORKTREE_PATH" log -1 --oneline)
DIFF_STAT=$(git diff --stat "$DEFAULT_BRANCH"..."worktree-<name>")
```

Present options:

```
## Worktree Cleanup: <name>

Branch: worktree-<name>
Last commit: <LAST_COMMIT>
Changes vs <default-branch>:
<DIFF_STAT>

Options:
1. Merge -- merge worktree-<name> into <default-branch> and remove worktree
2. Discard -- remove worktree and delete branch (all changes lost)
3. Cancel -- do nothing
```

Wait for user response.

### Step 4a: Merge

**4a-1.** If currently inside the worktree, switch to the main tree root:

```bash
cd "$MAIN_ROOT"
```

**4a-2.** Stash any uncommitted changes in the primary tree (staged or unstaged). The main tree is often dirty when cleanup runs:

```bash
STASHED=false
if ! git -C "$MAIN_ROOT" diff --quiet || ! git -C "$MAIN_ROOT" diff --cached --quiet; then
  git -C "$MAIN_ROOT" stash push -m "worktree-cleanup: before merge worktree-<name>"
  STASHED=true
fi
```

**4a-3.** Check whether the primary tree has the default branch checked out:

```bash
PRIMARY_BRANCH=$(git -C "$MAIN_ROOT" branch --show-current)
```

**4a-4.** If the primary tree is on the default branch (common case):

```bash
git -C "$MAIN_ROOT" merge "worktree-<name>" --no-ff -m "Merge worktree-<name> into <default-branch>"
```

**4a-5.** If the primary tree is on a different branch (another session may be using it):

Create a temporary worktree to perform the merge without touching the primary tree's checked-out branch:

```bash
git worktree add "$MAIN_ROOT/.claude/worktrees/_merge-tmp" "$DEFAULT_BRANCH"
git -C "$MAIN_ROOT/.claude/worktrees/_merge-tmp" merge "worktree-<name>" --no-ff -m "Merge worktree-<name> into <default-branch>"
git worktree remove "$MAIN_ROOT/.claude/worktrees/_merge-tmp"
```

**4a-6.** On merge conflict, stop and report:

```
Merge conflict detected. Conflicting files:
  - <file1>
  - <file2>

Stashed changes remain in stash. After resolving conflicts:
  git stash pop              (if stash was created)
  git worktree remove .claude/worktrees/<name>
  git branch -d worktree-<name>
```

Do not roll back. The user resolves conflicts and cleans up manually.

**4a-7.** On success, clean up worktree and branch:

```bash
git worktree remove "$WORKTREE_PATH"
git branch -d "worktree-<name>"
```

**4a-8.** Restore stashed changes:

```bash
if [ "$STASHED" = true ]; then
  git -C "$MAIN_ROOT" stash pop
fi
```

**4a-9.** Update memory. The session is back in the main tree where `_docs/memory/` files are current. Spawn the memory-updater subagent with accumulated worktree session work:

```
taskTitle: [summary of worktree work]
status: "complete"
commitSha: [merge commit SHA]
filesModified: [files changed in worktree, from diff stat]
decisions: [decisions made during worktree session]
notes: "Worktree: <name>. Merged into <default-branch>."
```

Omit `taskId` (worktree work is ad-hoc).

**4a-10.** Report:

```
Merged worktree-<name> into <default-branch>.
Worktree and branch removed.
Memory updated.
```

### Step 4b: Discard

**4b-1.** If currently inside the worktree, switch to the main tree root:

```bash
cd "$MAIN_ROOT"
```

**4b-2.** Force-remove worktree and branch:

```bash
git worktree remove "$WORKTREE_PATH" --force
git branch -D "worktree-<name>"
```

**4b-3.** Update memory. The session is back in the main tree. Spawn the memory-updater subagent to record the discarded worktree session:

```
taskTitle: "Worktree <name> (discarded)"
status: "partial"
filesModified: []
decisions: [decisions made during worktree session, if any]
notes: "Worktree: <name>. Discarded without merge."
```

Omit `taskId` and `commitSha`.

**4b-4.** Report:

```
Worktree <name> discarded. Branch worktree-<name> deleted.
Memory updated.
```

### Step 4c: Cancel

Report:

```
Cleanup cancelled. Worktree <name> remains active.
```

## Notes

- When merging, `--no-ff` preserves the worktree branch in commit history for traceability
- The temporary merge worktree (`_merge-tmp`) is only created when needed and is removed immediately after the merge
- Memory files (`_docs/memory/`) are git-excluded and not committed in worktrees, so they do not participate in the merge. The orchestrator's conversation context carries worktree session state and writes memory updates after returning to the main tree.
- If merge conflicts occur in a temporary merge worktree, abort the merge and remove the temp worktree before reporting
