---
name: map
description: Explore and map codebase to identify files related to a specific system, feature, or pattern. Use when planning implementation, understanding unfamiliar code areas, or documenting architecture.
argument-hint: <target> [--depth quick|medium|thorough]
context: fork
agent: general-purpose
allowed-tools: Read, Write, Grep, Glob, Bash(git *)
disable-model-invocation: false
---

# Map Command

Explore and map the codebase to identify files related to a specific system, feature, or mechanic.

## Arguments

- `target`: The system, feature, pattern, or mechanic to explore
- `--depth`: Exploration depth (default: medium)
  - `quick`: 2-3 searches, fastest results
  - `medium`: 5-10 searches, follow references one level
  - `thorough`: Comprehensive multi-strategy search, full dependency mapping

## Process

1. Parse target and depth from arguments
2. Identify search strategies based on target type:
   - Feature: Search for feature flags, routes, components
   - System: Search for module boundaries, entry points
   - Pattern: Search for implementations, usages
   - Mechanic: Search for business logic, state management
3. Execute searches using appropriate tools:
   - `Glob` for file patterns
   - `Grep` for code patterns
   - `Read` for file inspection
   - `Bash` for git history (git log, git diff only)
4. Map dependencies between discovered files
5. Synthesize findings into structured output
6. Save output to `_docs/maps/{target-slug}-{YYYYMMDD-HHMMSS}.md` using [template.md](template.md)
7. Return summary and file path

## Constraints

- NEVER modify existing codebase files (exploration is read-only)
- ONLY write to `_docs/maps/` for output artifacts
- Bash commands limited to: git log, git diff, git status
- Return concise summaries with absolute file paths
- Do NOT include file contents unless specifically relevant

## Output

Save exploration artifact to `_docs/maps/{target-slug}-{YYYYMMDD-HHMMSS}.md` where:
- `target-slug`: target converted to lowercase with spaces replaced by hyphens
- `YYYYMMDD-HHMMSS`: current timestamp (e.g., `20260130-143022`)

Use the format defined in [template.md](template.md). See [examples/sample.md](examples/sample.md) for a well-formed example.

After saving, return:

```
Exploration saved to: _docs/maps/{target-slug}-{YYYYMMDD-HHMMSS}.md

Summary: [2-3 sentence overview]

Entry points:
- [file1]
- [file2]
```

## Error Handling

If target cannot be found:
1. Report what was searched
2. Suggest alternative search terms
3. Ask for clarification if target is ambiguous
