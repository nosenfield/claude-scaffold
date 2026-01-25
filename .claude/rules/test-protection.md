---
paths:
  - "**/*.test.ts"
  - "**/*.spec.ts"
  - "**/*.test.tsx"
  - "**/*.spec.tsx"
  - "**/*.test.js"
  - "**/*.spec.js"
  - "__tests__/**"
  - "tests/**"
---

# Test File Protection Rules

Tests define acceptance criteria. Implementation must satisfy tests, not the reverse.

## Core Principle
Tests are contracts. When a test fails, the implementation is wrong.

## Allowed Modifications
- Adding new test cases
- Adding new test files
- Improving test descriptions for clarity
- Fixing test setup/teardown that has bugs (not assertions)

## Prohibited Modifications
- NEVER change assertions to make tests pass
- NEVER delete tests to avoid failures
- NEVER weaken test conditions (e.g., changing `toBe` to `toContain`)
- NEVER comment out failing tests

## If Test Seems Wrong
Stop and ask the user:
```
Test [name] in [file] may have incorrect expectations:

Current assertion: [assertion]
Actual behavior: [what code does]

Options:
1. Fix implementation to match test
2. Confirm test should be modified (requires approval)

Which approach?
```

## Rationale
Modifying tests to pass defeats TDD. Tests encode requirements; changing them changes requirements.
