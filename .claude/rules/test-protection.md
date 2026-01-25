---
paths:
  - "**/*.test.ts"
  - "**/*.test.tsx"
  - "**/*.spec.ts"
  - "**/*.spec.tsx"
  - "**/*.test.js"
  - "**/*.test.jsx"
  - "**/*.spec.js"
  - "**/*.spec.jsx"
  - "**/__tests__/**"
  - "**/tests/**"
---

# Test File Protection Rules

Tests are contracts that define expected behavior. They must remain immutable during implementation to preserve TDD integrity.

## Core Principle

Tests define the contract. Implementation satisfies the contract. Never modify the contract to match a faulty implementation.

## Immutable Elements

During implementation (`/implement` command), NEVER modify:
- Test assertions (`expect()`, `assert()`, etc.)
- Test descriptions (`it()`, `test()`, `describe()` strings)
- Expected values in assertions
- Mock return values that define expected behavior

## Permitted Operations by Stage

| Stage | Create Tests | Modify Tests | Delete Tests |
|-------|--------------|--------------|--------------|
| /test (test-writer) | Yes | N/A (new files) | No |
| /implement (implementer) | No | No | No |
| /review (code-reviewer) | No | No | No |
| Manual (user) | Yes | Yes | Yes |

## When Tests Seem Wrong

If tests assert incorrect behavior:

1. **Do NOT modify the test**
2. Report as blocker to orchestrator:
   ```
   BLOCKER: Test assertion appears incorrect
   File: [test file path]
   Line: [line number]
   Issue: [description of apparent error]
   Expected behavior: [what implementation should do]
   Test expects: [what test asserts]
   ```
3. Wait for user resolution
4. User may manually fix test or confirm test is correct

## Permitted Test Additions

The test-writer subagent MAY:
- Create new test files
- Add new test cases to existing files
- Add helper functions and fixtures

These additions must not modify existing assertions.

## Rationale

Test immutability ensures:
- Acceptance criteria remain stable
- Regressions are caught, not hidden
- Implementation matches specification
- Progress is measurable (tests passing)
