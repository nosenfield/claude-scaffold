# Architecture Document

## System Overview

[High-level description of the system architecture]

## Tech Stack

| Layer | Technology | Rationale |
|-------|------------|-----------|
| Runtime | Node.js 20 | [Why chosen] |
| Language | TypeScript 5.x | [Why chosen] |
| Framework | [Framework] | [Why chosen] |
| Database | [Database] | [Why chosen] |
| Testing | Jest | [Why chosen] |

## Project Structure

```
project-root/
├── src/
│   ├── routes/          # API route handlers
│   ├── services/        # Business logic
│   ├── repositories/    # Data access layer
│   ├── models/          # Data models/types
│   ├── middleware/      # Express middleware
│   ├── utils/           # Shared utilities
│   └── index.ts         # Application entry point
├── tests/
│   ├── unit/            # Unit tests
│   ├── integration/     # Integration tests
│   └── e2e/             # End-to-end tests
├── _docs/               # Project documentation
├── .claude/             # Claude Code configuration
└── package.json
```

## Architecture Principles

1. **[Principle 1]**: [Description and rationale]
2. **[Principle 2]**: [Description and rationale]
3. **[Principle 3]**: [Description and rationale]

## Component Design

### [Component 1 Name]
**Responsibility**: [What this component does]
**Dependencies**: [What it depends on]
**Interface**:
```typescript
interface [ComponentInterface] {
  [method signature]
}
```

### [Component 2 Name]
**Responsibility**: [What this component does]
**Dependencies**: [What it depends on]

## Data Flow

```
[Request] → [Route] → [Service] → [Repository] → [Database]
                ↓
           [Response]
```

## API Design

### Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | /api/[resource] | [Description] |
| POST | /api/[resource] | [Description] |
| PUT | /api/[resource]/:id | [Description] |
| DELETE | /api/[resource]/:id | [Description] |

### Authentication

[Describe authentication approach]

### Error Handling

[Describe error handling patterns]

## Database Schema

### [Table/Collection 1]
| Field | Type | Constraints |
|-------|------|-------------|
| id | UUID | Primary key |
| [field] | [type] | [constraints] |

## Environment Setup

### Prerequisites
- Node.js 20+
- npm 10+
- [Other prerequisites]

### Installation
```bash
git clone [repository]
cd [project]
npm install
```

### Configuration
```bash
cp .env.example .env
# Edit .env with your values
```

### Running Locally
```bash
npm run dev
```

### Running Tests
```bash
npm run test
```

## Deployment

[Describe deployment process and environments]

## Security Considerations

- [Security consideration 1]
- [Security consideration 2]

## Performance Considerations

- [Performance consideration 1]
- [Performance consideration 2]
