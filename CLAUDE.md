# Project Memory

## Documentation
- `/_docs/prd.md`: Product requirements
- `/_docs/architecture.md`: System architecture and tech stack
- `/_docs/task-list.json`: Development tasks with status
- `/_docs/best-practices.md`: Project-specific conventions

## Commands
- `npm run dev`: Start development server
- `npm run build`: Build for production
- `npm run test`: Run test suite
- `npm run test:watch`: Run tests in watch mode
- `npm run lint`: Run ESLint
- `npm run typecheck`: Run TypeScript compiler

## Workflow Commands
- `/init`: Initialize project environment
- `/dev`: Start or resume development session
- `/next`: Select next task to implement
- `/plan`: Plan task implementation
- `/test`: Write tests for planned task
- `/implement`: Implement code to pass tests
- `/review`: Code review implementation
- `/commit`: Commit and update memory bank
- `/catchup`: Summarize current project state

## Critical Constraints
- Follow TDD: write tests before implementation
- Never modify test assertions to make tests pass
- Only modify status fields in task-list.json
- Append to memory bank files; do not overwrite

## Memory Bank
- `progress.md`: Session history and outcomes
- `decisions.md`: Architectural and implementation decisions
