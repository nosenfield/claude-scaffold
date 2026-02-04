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

### 3. Create Memory Files

Create the memory directory if needed:

```bash
mkdir -p _docs/memory
```

**Create `_docs/memory/progress.md`** if it doesn't exist. Copy from `_docs/templates/progress.md` and update the date:

```bash
cp _docs/templates/progress.md _docs/memory/progress.md
# Update [DATE] placeholders with current date
```

**Create `_docs/memory/decisions.md`** if it doesn't exist. Copy from `_docs/templates/decisions.md`:

```bash
cp _docs/templates/decisions.md _docs/memory/decisions.md
```

**Create `_docs/backlog.json`** if it doesn't exist. Copy from `_docs/templates/backlog.json` and update metadata:

```bash
cp _docs/templates/backlog.json _docs/backlog.json
# Update [PROJECT_NAME] and [ISO_TIMESTAMP] in metadata
```

### 4. Report Initialized State

```
## Repository Initialized

### Documentation Verified
- prd.md: Present
- architecture.md: Present
- task-list.json: Present
- best-practices.md: Present

### Memory Files Created
- _docs/memory/progress.md: Created (from template)
- _docs/memory/decisions.md: Created (from template)
- _docs/backlog.json: Created (from template)

---

**Next Step**: Run `/dev` to start your development session.
```

## Notes

- Run this command once per project, after placing documentation
- If memory files already exist, they are not overwritten
- Templates in `_docs/templates/` provide structure and schema documentation
- After initialization, use `/dev` to start each session
- Environment setup (npm install, etc.) is handled as the first project task via `/next`
