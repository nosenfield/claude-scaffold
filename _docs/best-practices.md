# Best Practices

Project-specific coding standards and conventions. Agents reference this file for implementation guidance.

**Tech Stack**: TypeScript, Node.js, Express, Jest

---

## Quick Reference

### Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Files | kebab-case | `user-service.ts` |
| Classes | PascalCase | `UserService` |
| Functions | camelCase | `getUserById` |
| Constants | UPPER_SNAKE_CASE | `MAX_RETRY_COUNT` |
| Interfaces | PascalCase with I prefix (optional) | `IUserRepository` |
| Types | PascalCase | `UserResponse` |
| Test files | kebab-case + `.test` | `user-service.test.ts` |

### Import Organization

```typescript
// 1. External dependencies
import express from 'express';
import { z } from 'zod';

// 2. Internal types
import type { UserResponse } from '../types/user.types';

// 3. Internal modules (by layer)
import { UserRepository } from '../repositories/user.repository';
import { validateRequest } from '../middleware/validation';
```

### File Organization

```
src/
├── types/          # Interfaces and type definitions
├── config/         # Configuration and constants
├── repositories/   # Data access layer
├── services/       # Business logic
├── routes/         # HTTP handlers
├── middleware/     # Express middleware
└── utils/          # Shared utilities
```

---

## Code Style

### General Principles

1. **Single Responsibility**: Each function/class does one thing well
2. **Composition over Inheritance**: Prefer composing behaviors over class hierarchies
3. **Explicit over Implicit**: Make dependencies and types explicit

### Class/Module Structure

Order members consistently:

```typescript
class UserService {
  // 1. Static members
  static readonly MAX_USERS = 1000;

  // 2. Instance fields
  private readonly repository: UserRepository;

  // 3. Constructor
  constructor(repository: UserRepository) {
    this.repository = repository;
  }

  // 4. Public methods
  async getUser(id: string): Promise<User> {
    return this.repository.findById(id);
  }

  // 5. Private methods
  private validateId(id: string): boolean {
    return /^[a-f0-9-]{36}$/.test(id);
  }
}
```

### Patterns to Follow

```typescript
// CORRECT: Dependency injection for testability
class OrderService {
  constructor(
    private readonly orderRepo: OrderRepository,
    private readonly paymentService: PaymentService
  ) {}
}
```

### Anti-Patterns to Avoid

```typescript
// WRONG: Hard-coded dependency
class OrderService {
  private orderRepo = new OrderRepository();
}

// CORRECT: Inject dependencies
class OrderService {
  constructor(private readonly orderRepo: OrderRepository) {}
}
```

### Comments and Documentation

When to document:
- Non-obvious business logic
- Public API contracts
- Complex algorithms
- "Why" not "what"

```typescript
/**
 * Calculates the user's subscription tier based on usage history.
 * Uses a 30-day rolling window to smooth out usage spikes.
 *
 * @param userId - The user's unique identifier
 * @returns The calculated tier (free, basic, premium)
 * @throws UserNotFoundError if user doesn't exist
 */
async function calculateTier(userId: string): Promise<Tier> {
  // ...
}
```

---

## TypeScript Standards

### Type Safety

- Enable strict mode in `tsconfig.json`
- Avoid `any`; use `unknown` if type is truly unknown
- Prefer interfaces for object shapes
- Use `readonly` where mutation is not intended

```typescript
// Example: Readonly configuration
interface Config {
  readonly apiUrl: string;
  readonly timeout: number;
}

// Example: Type narrowing
function processValue(value: unknown): string {
  if (typeof value === 'string') {
    return value.toUpperCase();
  }
  throw new Error('Expected string');
}
```

### Async Patterns

- Use async/await consistently
- Handle promise rejections
- Consider timeouts for external calls

```typescript
// Example: Async with error handling and timeout
async function fetchWithTimeout<T>(
  url: string,
  timeoutMs: number = 5000
): Promise<T> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const response = await fetch(url, { signal: controller.signal });
    if (!response.ok) {
      throw new ApiError(`HTTP ${response.status}`, response.status);
    }
    return response.json();
  } finally {
    clearTimeout(timeout);
  }
}
```

### Error Handling

- Use custom error classes for domain errors
- Include error codes for programmatic handling
- Provide helpful error messages for debugging

```typescript
// Example: Domain error class
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

class UserNotFoundError extends DomainError {
  constructor(userId: string) {
    super(`User not found: ${userId}`, 'USER_NOT_FOUND', 404);
  }
}
```

---

## Express Patterns

### Project Structure

- Routes handle HTTP concerns only
- Services contain business logic
- Repositories handle data access
- Middleware handles cross-cutting concerns

### Request Handling

```typescript
// Example: Route handler with validation
router.post('/users',
  validateRequest(CreateUserSchema),
  async (req, res, next) => {
    try {
      const user = await userService.create(req.body);
      res.status(201).json({ data: user });
    } catch (error) {
      next(error);
    }
  }
);
```

### Middleware

```typescript
// Example: Error handling middleware
function errorHandler(
  error: Error,
  req: Request,
  res: Response,
  next: NextFunction
): void {
  if (error instanceof DomainError) {
    res.status(error.statusCode).json({
      error: { code: error.code, message: error.message }
    });
    return;
  }
  // Log unexpected errors, return generic message
  logger.error(error);
  res.status(500).json({
    error: { code: 'INTERNAL_ERROR', message: 'An error occurred' }
  });
}
```

### Validation

- Use Zod for request validation
- Validate at route boundaries
- Return clear validation errors

### Express Anti-Patterns

```typescript
// WRONG: Business logic in route handler
router.post('/orders', async (req, res) => {
  const inventory = await db.query('SELECT * FROM inventory...');
  // 50 more lines of business logic
});

// CORRECT: Delegate to service
router.post('/orders', async (req, res, next) => {
  try {
    const order = await orderService.create(req.body);
    res.status(201).json({ data: order });
  } catch (error) {
    next(error);
  }
});
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

Format: `should [expected behavior] when [condition]`

Example: `should return 401 when credentials are invalid`

### Test Pattern

```typescript
describe('UserService', () => {
  describe('getUser', () => {
    it('should return user when id exists', async () => {
      // Arrange
      const mockRepo = { findById: jest.fn().mockResolvedValue(testUser) };
      const service = new UserService(mockRepo);

      // Act
      const result = await service.getUser('123');

      // Assert
      expect(result).toEqual(testUser);
      expect(mockRepo.findById).toHaveBeenCalledWith('123');
    });

    it('should throw UserNotFoundError when id does not exist', async () => {
      // Arrange
      const mockRepo = { findById: jest.fn().mockResolvedValue(null) };
      const service = new UserService(mockRepo);

      // Act & Assert
      await expect(service.getUser('999')).rejects.toThrow(UserNotFoundError);
    });
  });
});
```

### Mocking External Services

```typescript
// Example: Mocking a repository
const mockUserRepo: jest.Mocked<UserRepository> = {
  findById: jest.fn(),
  create: jest.fn(),
  update: jest.fn(),
  delete: jest.fn(),
};
```

### Coverage Expectations

- Unit tests: 80%
- Integration tests: Key workflows
- Critical paths: 100%

---

## Error Handling

### Error Categories

| Category | When to Use | Example |
|----------|-------------|---------|
| ValidationError | Invalid input | Missing required field |
| NotFoundError | Resource doesn't exist | User ID not found |
| ConflictError | State conflict | Duplicate email |
| AuthorizationError | Permission denied | Insufficient role |

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

### Error Response Format

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request data",
    "details": [
      { "field": "email", "message": "Invalid email format" }
    ]
  }
}
```

---

## Security

### Input Validation

- Validate all input at system boundaries
- Use schema validation (Zod)
- Sanitize data before storage or display

### Authentication

- Use secure token storage (httpOnly cookies)
- Implement token expiration
- Hash passwords with bcrypt (cost factor 12+)

### Sensitive Data

- Never log sensitive data
- Use environment variables for secrets
- Never commit secrets to version control

---

## Performance

### Database

- Use indexes for frequently queried fields
- Avoid N+1 queries (use eager loading)
- Use connection pooling

### Caching

- Cache expensive computations
- Set appropriate TTLs
- Invalidate cache on data changes

### API Calls

- Use async/await consistently
- Handle promise rejections
- Set timeouts for external calls

---

## Git Practices

### Commit Messages

Format: `<type>(<scope>): <description>`

Types:
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code restructuring
- `test`: Test additions/changes
- `docs`: Documentation

Example: `feat(auth): implement JWT token refresh`

### Branch Strategy

- `main`: Production-ready code
- `feature/*`: Feature development
- `fix/*`: Bug fixes

---

## Cross-References

- [architecture.md](architecture.md): System design and module boundaries
- [prd.md](prd.md): Product requirements and acceptance criteria
- [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/): Official TypeScript documentation
