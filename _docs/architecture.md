# Architecture Document

## Tech Stack

| Layer | Technology | Version |
|-------|------------|---------|
| Runtime | Node.js | 20.x |
| Language | TypeScript | 5.x |
| Framework | [Framework] | [Version] |
| Database | [Database] | [Version] |
| Testing | Jest | 29.x |

## Project Structure

```
project-root/
├── src/
│   ├── index.ts           # Application entry point
│   ├── config/            # Configuration management
│   ├── routes/            # API route handlers
│   ├── services/          # Business logic layer
│   ├── repositories/      # Data access layer
│   ├── models/            # Type definitions
│   └── utils/             # Shared utilities
├── tests/
│   ├── unit/              # Unit tests
│   ├── integration/       # Integration tests
│   └── e2e/               # End-to-end tests
├── _docs/                 # Project documentation
└── .claude/               # Claude Code configuration
```

## Architecture Principles

1. **[Principle Name]**: [Description]

## Component Overview

### [Component Name]
- **Purpose**: [What it does]
- **Location**: [File path]
- **Dependencies**: [What it depends on]
- **Dependents**: [What depends on it]

## Data Flow

<!--
Describe how data flows through the system.
Include diagrams if helpful.
-->

## API Design

<!--
API patterns, authentication, error handling conventions.
-->

## Environment Setup

```bash
# Install dependencies
npm install

# Set up environment variables
cp .env.example .env

# Run database migrations (if applicable)
npm run db:migrate

# Start development server
npm run dev
```

## Build and Deploy

```bash
# Build for production
npm run build

# Run production build
npm start
```

## Critical Constraints

<!--
Non-negotiable architectural rules.
Things that must NOT be done.
-->

- NEVER [constraint]
