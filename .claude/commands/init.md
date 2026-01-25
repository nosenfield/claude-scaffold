# Initialize Project

Initialize project environment and memory bank for development.

## Steps

1. Verify core documentation exists:
   - `/_docs/prd.md`
   - `/_docs/architecture.md`
   - `/_docs/task-list.json`
   - `/_docs/best-practices.md`

2. Read and validate each document:
   - PRD contains project overview and features
   - Architecture contains tech stack and structure
   - Task list is valid JSON with required fields
   - Best practices contains project conventions

3. Run environment setup:
   ```bash
   npm install
   ```

4. Initialize memory bank:
   - Create `progress.md` if not exists
   - Create `decisions.md` if not exists
   - Add initialization entry to progress.md

5. Verify "hello world" state:
   ```bash
   npm run build
   npm run test
   ```

6. Report initialization status:
   - Environment: [ready/issues found]
   - Documentation: [complete/missing files]
   - Build: [success/failure]
   - Tests: [passing/failing]

## Success Criteria
- All core documentation present and valid
- Dependencies installed
- Project builds without errors
- Base tests pass
