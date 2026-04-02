# Parallelize Task List

Convert a linear (v1.x) task list to a parallel (v2.0) task list with wave computation.

**Usage**: `/parallelize-task-list <path-to-linear-task-list.json>`

The converted file is written to the same directory with `-parallel` appended to the filename.
Example: `_docs/task-list.json` produces `_docs/task-list-parallel.json`.

## Prerequisites

- Input file must exist at the provided path
- Tasks must have `filesTouched` arrays (can be empty)
- Tasks must have `blockedBy` arrays (can be empty)

## Step 1: Resolve Paths

```
inputPath = $ARGUMENTS
outputPath = replace ".json" with "-parallel.json" in inputPath
```

## Step 2: Validate

Read the input file. Check `metadata.version`:

- If version starts with `2.`: Stop. Report "Task list is already v2.0. Use `/compute-waves` to recompute waves."
- If version starts with `1.` or is missing: Proceed.

## Step 3: Migrate Fields

For each task, add fields if not present:

```
task.assignedAgent = null
task.result = null
```

## Step 4: Map Statuses

For each task:

```
if task.status == "complete":
    keep "complete"
else if task.status == "in-progress":
    keep "in-progress"
else if task.blockedBy is not empty:
    task.status = "blocked"
else:
    task.status = "eligible"
```

## Step 5: Update Metadata

```
metadata.version = "2.0.0"
metadata.maxConcurrency = 4
```

## Step 6: Update Schema Block

Replace the `_schema` block with the `_schema` from `_docs/templates/task-list-parallel.json`.

## Step 7: Write Output File

Write the converted JSON to `outputPath`. Do NOT modify the input file. Preserve task field ordering:

```
id, title, description, priority, executionWave, status, acceptanceCriteria, references, filesTouched, blockedBy, assignedAgent, result, completedAt
```

Set `executionWave` to `null` on all tasks at this stage. `/compute-waves` will populate it.

## Step 8: Compute Waves

Run `/compute-waves` against the output file to generate `waveSummary` and populate `executionWave` on each task.

## Step 9: Report

```
## Task List Parallelized

**Source**: [inputPath]
**Output**: [outputPath]
**Version**: 1.x -> 2.0.0
**Tasks**: [N]

### Schema Changes
- Added `assignedAgent`, `result` fields to [N] tasks
- Added `executionWave` to [N] tasks
- Added `waveSummary` with [W] waves
- Added `maxConcurrency: 4` to metadata
- Updated `_schema` to v2.0

### Status Mapping
- [N] tasks set to `eligible` (wave 0, no unmet dependencies)
- [M] tasks set to `blocked` (waves 1+, have dependencies)
- [P] tasks preserved as `complete`
- [Q] tasks preserved as `in-progress`

[Include wave summary table from /compute-waves output]
```

## Warnings

### Empty filesTouched

If any tasks have empty `filesTouched` arrays, warn:

```
### Warning: Empty filesTouched

The following tasks have empty filesTouched arrays:
- TASK-NNN: [title]

These tasks will not trigger contention detection. Populate filesTouched
for accurate parallel scheduling.
```

### Missing blockedBy

If any tasks lack `blockedBy` arrays, add an empty array and warn:

```
### Warning: Missing blockedBy

Added empty blockedBy to:
- TASK-NNN: [title]

These tasks will be placed in wave 0 (no dependencies).
```
