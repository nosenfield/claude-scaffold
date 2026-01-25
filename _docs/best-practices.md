# Best Practices

## Code Style

### TypeScript

- Use strict mode (`"strict": true` in tsconfig.json)
- Prefer `interface` over `type` for object shapes
- Use explicit return types on exported functions
- Avoid `any`; use `unknown` when type is truly unknown
- Use `readonly` for immutable properties

### Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Files | kebab-case | `user-service.ts` |
| Classes | PascalCase | `UserService` |
| Functions | camelCase | `getUserById` |
| Constants | SCREAMING_SNAKE | `MAX_RETRY_COUNT` |
| Interfaces | PascalCase with I prefix (optional) | `User` or `IUser` |

### File Organization

- One class/component per file
- Co-locate tests with source files or in `__tests__` directory
- Group related functionality in directories
- Index files for public exports only

## Testing

### Test Structure

```typescript
describe('[Unit/Feature]', () => {
  beforeEach(() => {
    // Setup
  });

  describe('[method/scenario]', () => {
    it('should [expected behavior] when [condition]', () => {
      // Arrange
      // Act
      // Assert
    });
  });
});
```

### Test Naming

- `should [expected behavior] when [condition]`
- Be specific: "should return null when user not found"
- Not vague: "should work correctly"

### Coverage Targets

- Unit tests: 80%+ line coverage
- Critical paths: 100% coverage
- Edge cases: explicitly tested

## Error Handling

- Use custom error classes for domain errors
- Always catch and handle async errors
- Log errors with context (user ID, request ID, etc.)
- Return meaningful error messages to clients

```typescript
class NotFoundError extends Error {
  constructor(resource: string, id: string) {
    super(`${resource} not found: ${id}`);
    this.name = 'NotFoundError';
  }
}
```

## Git Practices

### Commit Messages

Format: `type(scope): description`

Types:
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `test`: Adding or updating tests
- `docs`: Documentation changes
- `chore`: Maintenance tasks

### Branch Naming

- `feature/[task-id]-short-description`
- `fix/[task-id]-short-description`
- `refactor/[task-id]-short-description`

## Security

- Never commit secrets or credentials
- Use environment variables for configuration
- Validate all external input
- Use parameterized queries for database access
- Sanitize output to prevent XSS

## Performance

- Avoid N+1 queries
- Use pagination for list endpoints
- Cache expensive computations
- Profile before optimizing
