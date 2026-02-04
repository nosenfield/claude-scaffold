# Code Quality Principles

Project-agnostic principles for writing maintainable, readable code.

---

## SOLID Principles

### Single Responsibility Principle (SRP)
Each class or module should have one reason to change, focusing on a single responsibility.

### Open/Closed Principle (OCP)
Software entities should be open for extension but closed for modification.

### Liskov Substitution Principle (LSP)
Derived classes must be substitutable for their base classes without altering program correctness.

### Interface Segregation Principle (ISP)
Clients should not be forced to depend on interfaces they do not use.

### Dependency Inversion Principle (DIP)
High-level modules should not depend on low-level modules; both should depend on abstractions.

---

## Clean Code Practices

| Practice | Description |
|----------|-------------|
| Meaningful Names | Use descriptive, intention-revealing names for variables, functions, and classes |
| Function Size | Keep functions small (typically 5-15 lines), doing one thing well |
| Comment Quality | Write self-documenting code; comments should explain why, not what |
| DRY | Don't Repeat Yourself - eliminate code duplication through abstraction |
| YAGNI | You Aren't Gonna Need It - avoid implementing features before required |
| KISS | Keep It Simple - prefer simple solutions over complex ones |

---

## Code Organization

- **Consistent Formatting**: Use automated formatters (Prettier, Black, gofmt) to enforce style
- **Logical Structure**: Group related functionality together, separate concerns clearly
- **Module Cohesion**: High cohesion within modules, low coupling between modules
- **Package Organization**: Structure by feature or domain, not by technical layer when appropriate
- **Import Management**: Keep imports organized, remove unused dependencies

---

## Readability

### Naming Conventions
Follow language-specific conventions (camelCase, snake_case, PascalCase) consistently.

### Error Handling
Make error handling explicit and consistent throughout the codebase.

### Magic Numbers
Replace magic numbers with named constants or enums.

### Nested Conditionals
Avoid deep nesting through early returns and guard clauses:

```typescript
// Avoid
function process(data) {
  if (data) {
    if (data.valid) {
      if (data.ready) {
        return doWork(data);
      }
    }
  }
  return null;
}

// Prefer
function process(data) {
  if (!data) return null;
  if (!data.valid) return null;
  if (!data.ready) return null;
  return doWork(data);
}
```

### Function Parameters
Limit function parameters (typically 3 or fewer). Use objects for complex configurations:

```typescript
// Avoid
function createUser(name, email, age, role, department, startDate) { }

// Prefer
function createUser(config: UserConfig) { }
```

---

## Application Checklist

When reviewing or writing code, verify:

- [ ] Each module/class has a single, clear responsibility
- [ ] Names clearly convey intent
- [ ] Functions are small and focused
- [ ] No code duplication (or duplication is justified)
- [ ] Error handling is consistent
- [ ] No magic numbers or strings
- [ ] Nesting depth is manageable (3 levels max)
- [ ] Dependencies flow in one direction
