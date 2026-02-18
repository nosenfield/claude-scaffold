# Architecture Document

## Document Metadata

| Field | Value |
|-------|-------|
| Scope | [MVP / Full / Module name] |
| Status | [Draft / Active / Deprecated] |

## System Purpose

[1-3 sentences: What the system does and what problem it solves.]

## Tech Stack

| Layer | Technology | Rationale |
|-------|------------|-----------|
| Runtime | [e.g., Node.js 20] | [Why chosen] |
| Language | [e.g., TypeScript 5.x] | [Why chosen] |
| Framework | [e.g., Express 4.x] | [Why chosen] |
| Database | [e.g., PostgreSQL 16] | [Why chosen] |
| Testing | [e.g., Vitest] | [Why chosen] |

## Architecture Principles

1. **[Principle]**: [Description]
2. **[Principle]**: [Description]
3. **[Principle]**: [Description]

## Conventions

Cross-cutting conventions that all modules must follow. These prevent inconsistency when multiple agents implement in parallel.

| Convention | Standard | Example |
|------------|----------|---------|
| Time units | [ms / seconds] | `update(delta)` uses [unit] |
| Event payloads | [raw values / full state objects] | `emit('points-changed', [example])` |
| Enum encoding | [string / numeric] | `enum Status { Active = 'active' }` |
| Service access | [registry / DI / direct import] | `this.registry.get('serviceName')` |
| Interface declarations | Explicit `implements IFoo` on all classes that fulfill an interface | `class UserService implements IUserService { ... }` |
| Config location | All tunable parameters in `src/config/` modules; no magic numbers in source | `import { APP_CONFIG } from '../config/app.config'` |

Add project-specific conventions as needed. Agents read this section during Phase 0 context loading.

## Project Structure

```
project-root/
├── src/
│   ├── index.ts              # Entry point
│   ├── config/               # Constants, env validation
│   ├── routes/               # HTTP handlers
│   ├── services/             # Business logic
│   ├── repositories/         # Data access
│   └── types/                # Type definitions
├── tests/
│   ├── unit/
│   └── integration/
└── _docs/
```

## Core Components

### [Component Name]

| Aspect | Value |
|--------|-------|
| Purpose | [One sentence] |
| Location | `src/[path]/[file].ts` |
| Dependencies | [What it requires] |

**Responsibilities**:
- [Responsibility 1]
- [Responsibility 2]

**Interface**:
```typescript
interface [Name] {
  [method](input: Type): Promise<Type>;
}
```

## Data Flow

```
[Input] → [Route] → [Service] → [Repository] → [Database]
              ↓
         [Response]
```

1. Request arrives at route handler
2. Middleware validates/transforms
3. Service executes business logic
4. Repository persists/retrieves
5. Response returned

## Configuration

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DATABASE_URL` | Yes | — | Connection string |
| `PORT` | No | `3000` | Server port |

### Constants

Location: `src/config/constants.ts`

| Constant | Value | Purpose |
|----------|-------|---------|
| `MAX_PAGE_SIZE` | 100 | Pagination limit |
| `REQUEST_TIMEOUT` | 30000 | Request timeout (ms) |

**Config Centralization Rule**: All tunable parameters must live in dedicated `src/config/` modules. Source files import from config; they do not define magic numbers or inline constants that could be config. This is critical for parallel development -- multiple agents modifying the same parameter in different files creates inconsistency.

## Error Handling

| Category | Status | Pattern |
|----------|--------|---------|
| Validation | 400 | Return field-level errors |
| Auth | 401/403 | Log attempt, generic response |
| Not Found | 404 | Return resource identifier |
| Internal | 500 | Log full error, generic response |

**Principles**: Fail fast at boundaries. Log with context. No silent failures.

## Constraints

### Technical Limits

| Constraint | Limit | Rationale |
|------------|-------|-----------|
| Request body | 1 MB | Memory safety |
| Query results | 1000 | DB performance |

### Scope Boundaries

**In Scope**: [List features included]

**Out of Scope**: [List features explicitly excluded]

## Testing

| Layer | Target | Focus |
|-------|--------|-------|
| Unit | 80% | Services, utilities |
| Integration | 70% | Route → Service → Repository |
| E2E | Critical paths | Core user flows |

**Commands**: `npm run test`, `npm run test:cov`

## Related Documents

| Document | Purpose |
|----------|---------|
| `_docs/prd.md` | Requirements, acceptance criteria |
| `_docs/best-practices.md` | Coding conventions |
| `_docs/task-list.json` | Implementation tasks |

Add project-specific docs as needed (e.g., `api-schema.md`, `database-schema.md`).

## Agent Implementation Guide

### Priority Order

1. `src/types/` - Define interfaces first
2. `src/config/` - Constants, environment
3. `src/repositories/` - Data access
4. `src/services/` - Business logic
5. `src/routes/` - HTTP handlers
6. Tests with each layer

### Context Loading

When implementing, read in order:
1. This document (architecture overview)
2. `src/types/` (relevant interfaces)
3. Existing similar components (patterns)
4. Related documents as needed

### Verification

Before completing:
- [ ] Types match documented interfaces
- [ ] Error handling follows patterns
- [ ] Tests cover happy path + errors
