---
name: init-repo
description: Initialize scaffold for a new project. Run once after placing project documentation.
---

# Initialize Repository

One-time scaffold setup after project documentation is in place.

## Prerequisites

The user must have placed these files in `_docs/`:
- `prd.md` - Product requirements
- `architecture.md` - System design
- `task-list.json` - Project tasks
- `best-practices.md` - Coding standards

Templates are available in `_docs/templates/` for reference.

## Steps

### 1. Validate Core Documentation

Check that all required files exist:

```bash
ls -la _docs/prd.md _docs/architecture.md _docs/task-list.json _docs/best-practices.md
```

**If any file is missing**, report and stop:

```
## Missing Documentation

The following required files are not present:
- [list missing files]

Please create these files before running /init-repo.

Templates are available in `_docs/templates/`:
- prd.md
- architecture.md
- task-list.json
- best-practices.md

See README.md for documentation requirements.
```

### 2. Validate Task List Structure

```bash
# Verify JSON is valid
cat _docs/task-list.json | head -20
```

Confirm the file contains valid JSON with a `tasks` array. The expected schema is documented in `_docs/templates/task-list.json`.

### 3. Validate Memory Files

Memory files are created by `setup-project.sh`. Verify they exist:

```bash
ls -la _docs/memory/progress.md _docs/memory/decisions.md _docs/backlog.json
```

**If any file is missing**, report and stop:

```
## Missing Memory Files

The following memory files are not present:
- [list missing files]

These files should have been created by setup-project.sh.
Run setup-project.sh again or copy from _docs/templates/:
- progress.md → _docs/memory/
- decisions.md → _docs/memory/
- backlog.json → _docs/
```

### 3b. Replace Date Placeholders

Replace `[DATE]` placeholders in memory files with today's date:

```bash
sed -i '' "s/\[DATE\]/$(date +%Y-%m-%d)/g" _docs/memory/progress.md
```

This ensures the initial progress log has real dates instead of template placeholders.

### 4. Protect Git Hooks Path

If the project has a `package.json`, inject the `postprepare` script to guard against Husky/lefthook overwriting `core.hooksPath`:

```bash
ls package.json 2>/dev/null
```

**If `package.json` exists:**

Check whether `postprepare` is already defined. If not, add it to the `scripts` section:

```json
"postprepare": "./.githooks/protect-hookspath.sh"
```

If the `scripts` object doesn't exist, create it. If `postprepare` already exists, append the guard using `&&`:

```json
"postprepare": "<existing> && ./.githooks/protect-hookspath.sh"
```

Report whether the injection was performed.

**If `package.json` does not exist**, skip this step silently.

### 5. Report Initialized State

```
## Repository Initialized

### Documentation Verified
- prd.md: Present
- architecture.md: Present
- task-list.json: Present
- best-practices.md: Present

### Memory Files Verified
- _docs/memory/progress.md: Present
- _docs/memory/decisions.md: Present
- _docs/backlog.json: Present

### Git Hooks Protection
- [Injected postprepare guard / Already present / No package.json]

---

**Next Step**: Run `/dev` to start your development session.
```

## Notes

- Run this command once per project, after customizing documentation
- Memory files are created by `setup-project.sh`; this skill validates them
- Templates in `_docs/templates/` provide structure and schema documentation
- After initialization, use `/dev` to start each session
- Environment setup (npm install, etc.) is handled as the first project task via `/next-from-task-list`
