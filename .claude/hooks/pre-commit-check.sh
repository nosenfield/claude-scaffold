#!/bin/bash
# Pre-Commit Check Hook (Strict)
# Runs at Stop event (session end/transition)
# Mode: Strict - blocks on failure
#
# Exit codes:
#   0 = success (continue)
#   2 = blocking error (stops agent, feeds stderr to Claude)
#   other = non-blocking error (show warning, continue)
#
# This hook enforces quality standards at transition points.
# Issues that were advisory during editing become blocking here.

set -o pipefail

# Get project root from environment or current directory
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
cd "$PROJECT_DIR" || exit 0

# Track blocking issues
BLOCKING_ISSUES=""

# Add a blocking issue
add_blocking_issue() {
    if [ -z "$BLOCKING_ISSUES" ]; then
        BLOCKING_ISSUES="$1"
    else
        BLOCKING_ISSUES="$BLOCKING_ISSUES\n$1"
    fi
}

# Run test suite
run_tests() {
    if [ -f "package.json" ] && grep -q '"test"' package.json 2>/dev/null; then
        echo "Running tests..."
        if ! npm run test --silent 2>&1; then
            add_blocking_issue "Tests failed - all tests must pass before proceeding"
            return 1
        fi
        echo "Tests passed"
    fi
    return 0
}

# Run linter (strict)
run_lint_strict() {
    if [ -f "package.json" ] && grep -q '"lint"' package.json 2>/dev/null; then
        echo "Running lint check (strict)..."
        local lint_output
        lint_output=$(npm run lint --silent 2>&1)
        if [ $? -ne 0 ]; then
            add_blocking_issue "Lint errors must be fixed:\n$lint_output"
            return 1
        fi
        echo "Lint passed"
    fi
    return 0
}

# Run type check (strict)
run_typecheck_strict() {
    if [ -f "package.json" ] && grep -q '"typecheck"' package.json 2>/dev/null; then
        echo "Running type check (strict)..."
        local type_output
        type_output=$(npm run typecheck --silent 2>&1)
        if [ $? -ne 0 ]; then
            add_blocking_issue "Type errors must be fixed:\n$type_output"
            return 1
        fi
        echo "Type check passed"
    elif [ -f "tsconfig.json" ]; then
        echo "Running tsc (strict)..."
        local type_output
        type_output=$(npx tsc --noEmit 2>&1)
        if [ $? -ne 0 ]; then
            add_blocking_issue "Type errors must be fixed:\n$(echo "$type_output" | head -20)"
            return 1
        fi
        echo "Type check passed"
    fi
    return 0
}

# Check for uncommitted changes
check_uncommitted() {
    if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
        local changed_files
        changed_files=$(git status --short 2>/dev/null | head -10)
        echo "Note: Uncommitted changes present" >&2
        echo "$changed_files" >&2
        # This is informational, not blocking
        # The /commit command handles the actual commit
    fi
}

# Main execution
main() {
    echo "=== Pre-Commit Quality Check ==="
    echo ""
    
    # Run all checks
    run_tests
    run_lint_strict
    run_typecheck_strict
    check_uncommitted
    
    # Report results
    if [ -n "$BLOCKING_ISSUES" ]; then
        echo "" >&2
        echo "=== BLOCKING ISSUES ===" >&2
        echo -e "$BLOCKING_ISSUES" >&2
        echo "" >&2
        echo "Fix these issues before proceeding." >&2
        # Exit 2 = blocking error
        exit 2
    fi
    
    echo ""
    echo "All quality checks passed"
    exit 0
}

main
