---
name: tdd-workflow
description: You MUST use this when implementing any feature or fixing any bug
---

# Test-Driven Development Workflow

## Core Principle
Tests define requirements. Write tests first, then implement.

## Workflow Sequence

### 1. Understand Requirements
- Read task definition completely
- Identify acceptance criteria
- Clarify ambiguities before writing code

### 2. Write Failing Tests
- Create test file before implementation file
- Write tests that define expected behavior
- Cover: happy path, edge cases, error conditions
- Run tests; confirm they fail for the right reason

### 3. Implement Minimally
- Write only enough code to pass tests
- Do not add functionality beyond test coverage
- Run tests after each change

### 4. Refactor
- Clean up code while keeping tests green
- Extract common patterns
- Improve naming and structure

### 5. Verify
- All tests pass
- Type check passes
- Lint passes

## Anti-Patterns to Avoid

### Writing Tests After Implementation
- Leads to tests that verify what code does, not what it should do
- Misses edge cases
- Creates false confidence

### Modifying Tests to Pass
- If implementation doesn't match test, implementation is wrong
- Changing assertions hides bugs
- Breaks the contract

### Testing Implementation Details
- Test behavior, not internal structure
- Tests should survive refactoring
- Focus on inputs and outputs

### Skipping Edge Cases
- Null/undefined handling
- Empty collections
- Boundary values
- Error conditions

## Test Structure

```typescript
describe('[Unit/Feature]', () => {
  describe('[method/scenario]', () => {
    it('should [expected behavior] when [condition]', () => {
      // Arrange
      const input = ...;
      
      // Act
      const result = doThing(input);
      
      // Assert
      expect(result).toEqual(expected);
    });
  });
});
```

## When Tests Fail

1. Read the error message completely
2. Identify which assertion failed
3. Determine if test or implementation is wrong
4. If test is wrong: get approval before modifying
5. If implementation is wrong: fix implementation
