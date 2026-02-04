# Testing Principles

Project-agnostic principles for effective software testing.

---

## Test Pyramid

| Layer | Coverage | Characteristics |
|-------|----------|-----------------|
| Unit Tests (Base) | 70-80% | Fast, isolated tests of individual components |
| Integration Tests (Middle) | 15-20% | Test interactions between components and external systems |
| End-to-End Tests (Top) | 5-10% | Full system tests simulating user scenarios |

**Principle**: More tests at the base (fast, cheap), fewer at the top (slow, expensive).

---

## Testing Methodologies

### Test-Driven Development (TDD)

Red-Green-Refactor cycle:
1. **Red**: Write a failing test that defines expected behavior
2. **Green**: Write minimal code to make the test pass
3. **Refactor**: Improve code while keeping tests green

### Behavior-Driven Development (BDD)

Focus on business behavior using Given-When-Then syntax:
```gherkin
Given a registered user with valid credentials
When they submit the login form
Then they should be redirected to the dashboard
```

### Arrange-Act-Assert (AAA)

Structure tests with clear phases:
```typescript
it('should calculate total with tax', () => {
  // Arrange
  const cart = new ShoppingCart();
  cart.addItem({ price: 100 });

  // Act
  const total = cart.calculateTotal({ taxRate: 0.1 });

  // Assert
  expect(total).toBe(110);
});
```

---

## Test Quality Principles

### Test Independence
- Each test should run independently without affecting others
- Tests should not depend on execution order
- Each test sets up its own state
- Clean up after tests that modify shared resources

### Deterministic Tests
- Tests should produce same results consistently
- No flakiness from timing, randomness, or external dependencies
- Mock external dependencies to ensure consistency

### Meaningful Coverage
- Aim for high coverage (80%+) but focus on meaningful coverage, not just metrics
- Prioritize: business logic > integration points > utilities
- Every bug fix should include a regression test

### Test Naming
Use descriptive names that explain scenario and expected outcome:
```typescript
// Pattern: should [expected behavior] when [condition]
'should return 401 when credentials are invalid'
'should retry 3 times when network request fails'
'should emit event when state changes'
```

---

## Test Data Management

### Factories and Builders
Create consistent test data with sensible defaults:
```typescript
const createUser = (overrides = {}) => ({
  id: 'user-1',
  name: 'Test User',
  email: 'test@example.com',
  ...overrides
});

// Usage
const adminUser = createUser({ role: 'admin' });
```

### Fixtures
Use shared test fixtures for complex data structures, but ensure tests remain independent.

---

## Advanced Techniques

| Technique | Purpose | When to Use |
|-----------|---------|-------------|
| Property-Based Testing | Verify properties hold for wide range of inputs | Mathematical operations, parsers, serialization |
| Snapshot Testing | Capture and compare component output | UI components, serialized data structures |
| Contract Testing | Verify API contracts between services | Microservices, consumer-driven contracts |
| Mutation Testing | Verify test effectiveness by introducing bugs | Validating test suite quality |

---

## Continuous Testing

- **Automated Execution**: Run tests on every commit through CI/CD
- **Fast Feedback**: Optimize test execution speed for quick feedback
- **Parallelization**: Run tests in parallel to reduce execution time
- **Shift-Left**: Move testing earlier in development lifecycle

---

## Test Checklist

When writing tests, verify:

- [ ] Test name clearly describes scenario and expectation
- [ ] Test follows AAA pattern (Arrange-Act-Assert)
- [ ] Test is independent (no shared mutable state)
- [ ] Test is deterministic (no flakiness)
- [ ] Happy path is covered
- [ ] Edge cases are covered
- [ ] Error conditions are covered
- [ ] Test data is realistic and maintainable
