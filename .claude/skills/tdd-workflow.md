---
name: tdd-workflow
description: You MUST use this when implementing any feature or fixing any bug
---

# Test-Driven Development Workflow

## Core Principle

Tests are written BEFORE implementation. Tests define the contract. Implementation satisfies the contract.

## The TDD Cycle

```
1. RED    → Write a failing test
2. GREEN  → Write minimal code to pass
3. REFACTOR → Improve code, keep tests passing
```

## Workflow Steps

### Step 1: Understand Requirements
- Read task acceptance criteria
- Identify expected behaviors
- List edge cases and error conditions

### Step 2: Write Tests First
- Create test file before implementation file
- Write tests for expected behaviors
- Include happy path, edge cases, and error handling
- Run tests → they should FAIL (no implementation exists)

### Step 3: Implement Incrementally
- Write minimal code to pass ONE test
- Run tests after each change
- Do not write more code than necessary to pass current tests
- Repeat until all tests pass

### Step 4: Refactor
- Improve code structure and readability
- Run tests after each refactor
- Tests must remain passing
- Do not add functionality during refactor

## Rules

### Test Immutability
- NEVER modify test assertions to make tests pass
- NEVER delete tests to avoid failures
- If a test seems wrong, report as blocker
- Tests can only be modified by test-writer during /test phase

### Test Quality
- Each test should test ONE behavior
- Tests should be independent (no shared state)
- Use descriptive test names
- Follow Arrange-Act-Assert pattern

### Implementation Constraints
- Only write code that makes a test pass
- Do not write code "for later"
- Do not optimize prematurely
- Keep functions small and focused

## Anti-Patterns to Avoid

### Testing Anti-Patterns
- Writing tests after implementation
- Testing implementation details instead of behavior
- Tests that depend on execution order
- Mocking everything (test real integrations when possible)

### Implementation Anti-Patterns
- Writing all code before running tests
- Modifying tests to match incorrect implementation
- Skipping edge case tests
- Ignoring failing tests

## Benefits

1. **Clear Requirements**: Tests document expected behavior
2. **Confidence**: Changes are validated immediately
3. **Design**: TDD encourages modular, testable code
4. **Regression Prevention**: Existing tests catch breaks
5. **Progress Tracking**: Test pass count shows progress
