# Project: [PROJECT_NAME]

[Brief one-line project description]

## Commands

```bash
npm install          # Install dependencies
npm run dev          # Start development server
npm run build        # Build for production
npm run test         # Run test suite
npm run test:watch   # Run tests in watch mode
npm run lint         # Run linter
npm run typecheck    # Run TypeScript type checking
```

## Architecture

- `src/` - Application source code
- `src/routes/` - API route handlers
- `src/services/` - Business logic layer
- `src/repositories/` - Data access layer
- `tests/` - Test files
- `_docs/` - Project documentation

## Development Workflow

1. `/init` - Initialize environment (first time)
2. `/dev` - Start session
3. `/next` - Select task
4. `/plan` - Plan implementation
5. `/test` - Write tests
6. `/implement` - Write code
7. `/review` - Code review
8. `/commit` - Commit and update memory

## Critical Constraints

- Follow TDD: write tests before implementation
- Never modify test assertions to make tests pass
- Never modify task definitions in task-list.json
- Append only to progress.md and decisions.md
- Core docs (_docs/*.md) are read-only for agents

## Key Files

- `/_docs/prd.md` - Product requirements
- `/_docs/architecture.md` - System design
- `/_docs/task-list.json` - Development tasks
- `/_docs/best-practices.md` - Coding standards
- `/progress.md` - Session history
- `/decisions.md` - Architecture decisions
