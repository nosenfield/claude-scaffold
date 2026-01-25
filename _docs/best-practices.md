# Best Practices

## Code Style

### General Principles
- Write self-documenting code with clear naming
- Keep functions small and focused (single responsibility)
- Prefer composition over inheritance
- Avoid premature optimization

### Naming Conventions
| Element | Convention | Example |
|---------|------------|---------|
| Files | kebab-case | `user-service.ts` |
| Classes | PascalCase | `UserService` |
| Functions | camelCase | `getUserById` |
| Constants | UPPER_SNAKE_CASE | `MAX_RETRY_COUNT` |
| Interfaces | PascalCase with I prefix (optional) | `IUserRepository` or `UserRepository` |
| Types | PascalCase | `UserResponse` |

### TypeScript Guidelines
- Enable strict mode
- Avoid `any` type; use `unknown` if type is truly unknown
- Prefer interfaces for object shapes
- Use type inference where obvious; explicit types for function signatures
- Use readonly where mutation is not intended

## Testing

### Test Structure
```typescript
describe('[Unit under test]', () => {
  describe('[method or scenario]', () => {
    it('should [expected behavior] when [condition]', () => {
      // Arrange
      // Act
      // Assert
    });
  });
});
```

### Test Naming
- Use descriptive names that explain the scenario
- Format: `should [expected behavior] when [condition]`
- Example: `should return 401 when credentials are invalid`

### Test Coverage
- Aim for meaningful coverage, not 100% coverage
- Prioritize: business logic > integration points > utilities
- Every bug fix should include a regression test

### Test Independence
- Tests should not depend on execution order
- Each test sets up its own state
- Clean up after tests that modify shared resources

## Error Handling

### Error Types
- Use custom error classes for domain errors
- Include error codes for programmatic handling
- Provide helpful error messages for debugging

### Error Pattern
```typescript
class DomainError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly statusCode: number = 500
  ) {
    super(message);
    this.name = this.constructor.name;
  }
}
```

### Error Responses
- Never expose internal errors to clients
- Log full error details server-side
- Return consistent error response format

## API Design

### REST Conventions
- Use nouns for resources, not verbs
- Use HTTP methods semantically (GET, POST, PUT, DELETE)
- Return appropriate status codes
- Version APIs when breaking changes are needed

### Response Format
```typescript
// Success
{
  "data": { ... },
  "meta": { "timestamp": "...", "requestId": "..." }
}

// Error
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Human readable message",
    "details": [ ... ]
  }
}
```

## Git Practices

### Commit Messages
Format: `<type>(<scope>): <description> (<task-id>)`

Types:
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `docs`: Documentation only changes
- `test`: Adding or modifying tests
- `chore`: Maintenance tasks

Example: `feat(auth): implement JWT token refresh (TASK-005)`

### Branch Strategy
- `main`: Production-ready code
- `feature/*`: Feature development
- `fix/*`: Bug fixes

## Security

### Input Validation
- Validate all input at system boundaries
- Use schema validation (e.g., Zod, Joi)
- Sanitize data before storage or display

### Authentication
- Use secure token storage
- Implement token expiration
- Hash passwords with bcrypt (cost factor 12+)

### Sensitive Data
- Never log sensitive data
- Use environment variables for secrets
- Never commit secrets to version control

## Performance

### Database
- Use indexes for frequently queried fields
- Avoid N+1 queries
- Use connection pooling

### Caching
- Cache expensive computations
- Set appropriate TTLs
- Invalidate cache on data changes

### Async Operations
- Use async/await consistently
- Handle promise rejections
- Consider timeouts for external calls
