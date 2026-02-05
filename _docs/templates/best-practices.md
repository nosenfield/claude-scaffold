# Best Practices

Project-specific coding standards and conventions. Agents reference this file for implementation guidance.

**Tech Stack**: [Primary language], [Framework], [Database], [Testing framework]

---

## Quick Reference

### Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Files | [convention] | `user-service.ts` |
| Classes | [convention] | `UserService` |
| Functions | [convention] | `getUserById` |
| Constants | [convention] | `MAX_RETRY_COUNT` |
| Interfaces | [convention] | `IUserRepository` |
| Types | [convention] | `UserRole` |
| Test files | [convention] | `user-service.test.ts` |

### Import Organization

```[language]
// 1. External dependencies
[example]

// 2. Internal types
[example]

// 3. Internal modules (by layer or feature)
[example]
```

### File Organization

```
src/
├── [layer or feature]/
│   ├── [component].ts
│   └── [component].test.ts
└── ...
```

---

## Code Style

### General Principles

1. **[Principle]**: [Description with rationale]
2. **[Principle]**: [Description with rationale]
3. **[Principle]**: [Description with rationale]

### Class/Module Structure

Order members consistently:

```[language]
// 1. Static members
// 2. Instance fields
// 3. Constructor
// 4. Public methods
// 5. Private methods
[example class skeleton]
```

### Patterns to Follow

```[language]
// CORRECT: [Description]
[code example]
```

### Anti-Patterns to Avoid

```[language]
// WRONG: [Description]
[code example]

// CORRECT: [Alternative]
[code example]
```

### Comments and Documentation

When to document:
- Non-obvious business logic
- Public API contracts
- Complex algorithms
- "Why" not "what"

```[language]
// Example: Documentation format
[docstring or JSDoc example]
```

---

## [Primary Language] Standards

### Type Safety

[Language-specific type system guidance]

```[language]
// Example: [Description]
[code example]
```

### Async Patterns

[Async/await, promises, or concurrency patterns]

```[language]
// Example: [Description]
[code example]
```

### Error Handling

[Language-specific error/exception patterns]

```[language]
// Example: [Description]
[code example]
```

---

## [Framework] Patterns

### Project Structure

[Framework-specific organization]

### [Core Concept, e.g., Component Lifecycle]

```[language]
// Example: [lifecycle method or hook]
[code example]
```

### [State Management / Data Flow]

[How state is managed]

### [Routing / Navigation]

[Routing patterns if applicable]

### [API Integration / Data Fetching]

[Data fetching patterns]

### [Framework Anti-Patterns]

```[language]
// WRONG: [Common mistake]
[code example]

// CORRECT: [Proper approach]
[code example]
```

---

## Testing

### Test Structure

```
tests/
├── unit/           # Isolated, fast tests
├── integration/    # Tests with dependencies
└── fixtures/       # Test data
```

### Test Naming

Format: `[describe what] [expected behavior] [under what condition]`

Example: `getUserById returns user when id exists`

### Test Pattern

```[language]
describe('[Feature/Module]', () => {
  it('should [expected behavior]', () => {
    // Arrange: Set up test data
    // Act: Execute the function
    // Assert: Verify the result
  });
});
```

### Mocking External Services

```[language]
// Example: Mocking [service type]
[mock example]
```

### Coverage Expectations

- Unit tests: [target %]
- Integration tests: [target %]
- Critical paths: [target %]

---

## Error Handling

### Error Categories

| Category | When to Use | Example |
|----------|-------------|---------|
| [Category] | [Condition] | [Example] |
| [Category] | [Condition] | [Example] |

### Error Pattern

```[language]
// Custom error class pattern
[error class example]
```

### Error Response Format

```json
{
  "error": {
    "code": "[ERROR_CODE]",
    "message": "[User-friendly message]"
  }
}
```

---

## Security

### Input Validation

- [Rule 1]
- [Rule 2]
- [Rule 3]

### Authentication

- [Auth pattern or library]
- [Token handling]

### Sensitive Data

- [Secrets management approach]
- [Data handling rules]

---

## Performance

### [Category 1, e.g., Memory]

- [Guideline]
- [Guideline]

### [Category 2, e.g., Database]

- [Guideline]
- [Guideline]

### [Category 3, e.g., API Calls]

- [Guideline]
- [Guideline]

---

## Git Practices

### Commit Messages

Format: `[type]: [description]`

Types:
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code restructuring
- `test`: Test additions/changes
- `docs`: Documentation

### Branch Strategy

- `main`: Production-ready code
- `[branch-prefix]/[description]`: Feature/fix branches

---

## Cross-References

- [architecture.md](architecture.md): System design and module boundaries
- [prd.md](prd.md): Product requirements and acceptance criteria
- [External standard](https://example.com): [Description]
