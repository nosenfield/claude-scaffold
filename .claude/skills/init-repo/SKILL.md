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

See README.md for documentation requirements.
```

### 2. Validate Task List Structure

```bash
# Verify JSON is valid
cat _docs/task-list.json | head -20
```

Confirm the file contains valid JSON with a `tasks` array.

### 3. Create Memory Files

**Create `progress.md`** if it doesn't exist:

```markdown
# Progress Log

This file tracks session history and completed work. Entries are append-only.

---

<!-- New entries are added below this line -->

## [DATE] - Project Initialized

**Status**: Repository initialized, ready for development
**Core Documentation**: Verified present
**Next Step**: Run `/dev` to start development session

---
```

**Create `decisions.md`** if it doesn't exist:

```markdown
# Decision Log

This file records architecture and implementation decisions. Entries are append-only.

---

<!-- New entries are added below this line -->
```

**Create `_docs/backlog.json`** if it doesn't exist:

```json
{
  "items": []
}
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
- progress.md: Created
- decisions.md: Created
- _docs/backlog.json: Created

---

**Next Step**: Run `/dev` to start your development session.
```

## Notes

- Run this command once per project, after placing documentation
- If memory files already exist, they are not overwritten
- After initialization, use `/dev` to start each session
- Environment setup (npm install, etc.) is handled as the first project task via `/next`
