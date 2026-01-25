#!/bin/bash
# Quality Gate Hook (Advisory)
# Runs after Write/Edit/MultiEdit operations
# Mode: Advisory - shows warnings but does not block
#
# Exit codes:
#   0 = success (continue)
#   2 = blocking error (would stop agent)
#   other = non-blocking error (show warning, continue)
#
# This hook uses advisory mode (exit 0 or 1) to allow iteration
# without blocking. Strict enforcement happens at transitions
# via pre-commit-check.sh

set -o pipefail

# Get project root from environment or current directory
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
cd "$PROJECT_DIR" || exit 0

# Track if any issues found
ISSUES_FOUND=0

# Check if relevant source files were modified
# Skip checks if only non-source files changed
check_relevant_files() {
    local changed_files
    changed_files=$(git diff --name-only 2>/dev/null || echo "")
    
    if [ -z "$changed_files" ]; then
        return 1  # No changes to check
    fi
    
    # Check for TypeScript/JavaScript files
    if echo "$changed_files" | grep -qE '\.(ts|tsx|js|jsx)$'; then
        return 0  # Relevant files found
    fi
    
    return 1  # No relevant files
}

# Run linter if available
run_lint() {
    if [ -f "package.json" ] && grep -q '"lint"' package.json 2>/dev/null; then
        echo "Running lint check..."
        if ! npm run lint --silent 2>&1; then
            echo "Warning: Lint issues detected" >&2
            ISSUES_FOUND=1
        fi
    fi
}

# Run type check if available
run_typecheck() {
    if [ -f "package.json" ] && grep -q '"typecheck"' package.json 2>/dev/null; then
        echo "Running type check..."
        if ! npm run typecheck --silent 2>&1; then
            echo "Warning: Type errors detected" >&2
            ISSUES_FOUND=1
        fi
    elif [ -f "tsconfig.json" ]; then
        echo "Running tsc..."
        if ! npx tsc --noEmit --pretty 2>&1 | head -20; then
            echo "Warning: Type errors detected" >&2
            ISSUES_FOUND=1
        fi
    fi
}

# Main execution
main() {
    # Skip if no relevant files changed
    if ! check_relevant_files; then
        exit 0
    fi
    
    run_lint
    run_typecheck
    
    if [ $ISSUES_FOUND -eq 1 ]; then
        echo ""
        echo "Quality issues detected (advisory - not blocking)"
        echo "These will be enforced at commit time"
        # Exit 1 = non-blocking warning
        exit 1
    fi
    
    exit 0
}

main
