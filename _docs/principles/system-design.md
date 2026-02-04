# System Design Principles

Project-agnostic principles for building composable, maintainable systems.

---

## Black Box Principle

A well-designed component hides implementation details and exposes only its interface.

### Core Questions

When designing any module, function, or service:

1. **Could someone reimplement this using only the interface?**
   - If yes: abstraction is clean
   - If no: implementation details have leaked

2. **Does this component have one obvious job?**
   - Single responsibility at the interface level
   - Clear purpose from external perspective

3. **What should be hidden vs. exposed?**
   - Hide: algorithms, data structures, optimization strategies
   - Expose: inputs, outputs, error conditions, behavioral guarantees

### Replaceability Test

> If a module cannot be reimplemented by understanding only its interface, the abstraction has leaked.

**Signs of leaky abstractions:**
- Callers need to know internal state
- Order of method calls matters unexpectedly
- Error messages expose implementation details
- Performance characteristics require internal knowledge

---

## Composability

Build larger systems from smaller, well-defined units that combine predictably.

### Composition Principles

| Principle | Description |
|-----------|-------------|
| **Self-contained** | Each component handles its complete responsibility |
| **Minimal overlap** | No ambiguous boundaries between components |
| **Predictable combination** | Output of A can be input to B without transformation |
| **Independent evolution** | Components can be upgraded without cascading changes |

### Composition Patterns

**Pipeline Composition**
```
Input → Component A → Component B → Component C → Output
```
Each component transforms data; output type matches next component's input type.

**Aggregation Composition**
```
         ┌→ Component A ─┐
Input ───┼→ Component B ─┼→ Aggregator → Output
         └→ Component C ─┘
```
Multiple components process same input; results combine.

**Layered Composition**
```
┌─────────────────────────┐
│   Presentation Layer    │ ← Uses services, not implementation
├─────────────────────────┤
│    Business Layer       │ ← Uses data access, not database
├─────────────────────────┤
│   Data Access Layer     │ ← Uses database adapter
└─────────────────────────┘
```
Each layer depends only on the layer below via interface.

---

## Input/Output Contracts

Clear agreements on data structures between components enable composition and replaceability.

### Contract Elements

| Element | Description | Example |
|---------|-------------|---------|
| **Input Schema** | Structure and types of accepted input | `{ userId: string, options?: Options }` |
| **Output Schema** | Structure and types of returned output | `{ data: User, meta: Metadata }` |
| **Error Schema** | Structure of error responses | `{ code: string, message: string }` |
| **Invariants** | Guarantees that always hold | "Output array is sorted by date" |
| **Preconditions** | Requirements before invocation | "userId must be non-empty" |
| **Postconditions** | Guarantees after successful invocation | "User exists in database" |

### Contract Documentation

```typescript
/**
 * Retrieves user by ID.
 *
 * @input userId - Non-empty string identifier
 * @output User object with profile data
 * @throws NotFoundError - User does not exist
 * @throws ValidationError - userId is empty or malformed
 * @invariant Returned user.id === input userId
 */
function getUser(userId: string): Promise<User>
```

### Contract Testing

Verify contracts between components explicitly:

```typescript
describe('UserService contract', () => {
  it('returns user matching requested id', async () => {
    const result = await userService.getUser('user-123');
    expect(result.id).toBe('user-123'); // Invariant
  });

  it('throws NotFoundError for missing user', async () => {
    await expect(userService.getUser('nonexistent'))
      .rejects.toThrow(NotFoundError); // Error contract
  });
});
```

---

## Hexagonal Architecture (Ports and Adapters)

Core business logic is independent of external concerns.

### Structure

```
                    ┌─────────────────────┐
    HTTP Adapter ──→│                     │←── Database Adapter
                    │    Core Domain      │
   CLI Adapter ────→│   (Business Logic)  │←── Message Queue Adapter
                    │                     │
   Test Adapter ───→│                     │←── Mock Adapter
                    └─────────────────────┘
                           ↑     ↑
                         Ports (Interfaces)
```

### Principles

- **Core domain**: Pure business logic with no external dependencies
- **Ports**: Interfaces defining how core interacts with outside world
- **Adapters**: Implementations that connect ports to actual infrastructure

### Benefits

| Benefit | Description |
|---------|-------------|
| **Testability** | Core can be tested with mock adapters |
| **Flexibility** | Swap infrastructure without changing business logic |
| **Clarity** | Clear separation between "what" and "how" |
| **Independence** | Core has no knowledge of HTTP, databases, etc. |

### Example

```typescript
// Port (interface)
interface UserRepository {
  findById(id: string): Promise<User | null>;
  save(user: User): Promise<void>;
}

// Core domain uses port
class UserService {
  constructor(private repo: UserRepository) {}

  async updateEmail(userId: string, email: string): Promise<void> {
    const user = await this.repo.findById(userId);
    if (!user) throw new NotFoundError();
    user.email = email;
    await this.repo.save(user);
  }
}

// Adapter implements port
class PostgresUserRepository implements UserRepository {
  async findById(id: string): Promise<User | null> {
    // PostgreSQL-specific implementation
  }
}

// Test adapter
class InMemoryUserRepository implements UserRepository {
  private users = new Map<string, User>();
  // In-memory implementation for tests
}
```

---

## API-First Design

Define interfaces before implementation; treat APIs as products.

### Process

1. **Define contract first**: Schema, endpoints, error responses
2. **Review contract**: Stakeholders agree before implementation
3. **Generate artifacts**: Types, mocks, documentation from contract
4. **Implement to contract**: Implementation satisfies defined interface
5. **Validate continuously**: Tests verify contract compliance

### Contract-First Benefits

- **Parallel development**: Frontend and backend work simultaneously
- **Clear expectations**: No ambiguity about interface behavior
- **Documentation**: Contract is the documentation
- **Mocking**: Generate mocks from contract for testing

---

## Design Checklist

When designing a component:

- [ ] **Interface clarity**: Can someone use this knowing only the interface?
- [ ] **Single responsibility**: Does it have one obvious job?
- [ ] **Input contract**: Are inputs clearly defined with types and constraints?
- [ ] **Output contract**: Are outputs clearly defined with guarantees?
- [ ] **Error contract**: Are error conditions documented and consistent?
- [ ] **Replaceability**: Could this be reimplemented without changing callers?
- [ ] **Composability**: Can output feed into other components?
- [ ] **Independence**: Does it depend only on interfaces, not implementations?

---

## Anti-Patterns

### Leaky Abstraction
```typescript
// Bad: Caller needs to know about internal caching
userService.getUser(id, { bypassCache: true });

// Better: Service handles caching transparently
userService.getUser(id); // Always returns fresh or cached as appropriate
```

### Implicit Contracts
```typescript
// Bad: Caller must know to call methods in order
auth.setToken(token);
auth.setUser(user);
auth.initialize(); // Fails if called before setToken/setUser

// Better: Explicit contract in single call
auth.initialize({ token, user });
```

### Over-Coupling
```typescript
// Bad: Service knows about HTTP response format
class UserService {
  getUser(id: string): { status: 200, body: User } // HTTP leaked into domain
}

// Better: Service returns domain object; adapter handles HTTP
class UserService {
  getUser(id: string): User // Pure domain
}
```
