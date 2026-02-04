#!/bin/bash
# Initialize new project from claude-project-template scaffold
#
# Usage: ./setup-project.sh <project-name> [target-directory]
#
# Arguments:
#   project-name      Name of the new project (used in file placeholders)
#   target-directory  Optional. Where to create the project (default: ../<project-name>)

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PROJECT_NAME=$1
TARGET_DIR=${2:-"../$PROJECT_NAME"}

# Determine script and scaffold location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCAFFOLD_DIR="$(dirname "$SCRIPT_DIR")"

if [ -z "$PROJECT_NAME" ]; then
  echo -e "${RED}Error: Project name required${NC}"
  echo ""
  echo "Usage: ./setup-project.sh <project-name> [target-directory]"
  echo ""
  echo "Examples:"
  echo "  ./setup-project.sh my-app              # Creates ../my-app"
  echo "  ./setup-project.sh my-app ~/projects   # Creates ~/projects/my-app"
  exit 1
fi

# Validate project name (alphanumeric, hyphens, underscores)
if ! [[ "$PROJECT_NAME" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
  echo -e "${RED}Error: Invalid project name${NC}"
  echo "Project name must start with a letter and contain only letters, numbers, hyphens, and underscores."
  exit 1
fi

# Resolve target directory
if [ -n "$2" ]; then
  # User provided explicit target directory - project goes inside it
  if [[ "$TARGET_DIR" == /* ]]; then
    # Absolute path
    TARGET_DIR="$TARGET_DIR/$PROJECT_NAME"
  else
    # Relative path - resolve from current working directory
    TARGET_DIR="$(pwd)/$TARGET_DIR/$PROJECT_NAME"
  fi
else
  # Default: sibling to scaffold directory
  TARGET_DIR="$(dirname "$SCAFFOLD_DIR")/$PROJECT_NAME"
fi

# Check if target already exists
if [ -d "$TARGET_DIR" ]; then
  echo -e "${RED}Error: Directory already exists: $TARGET_DIR${NC}"
  exit 1
fi

echo ""
echo "Setting up new project: $PROJECT_NAME"
echo "Location: $TARGET_DIR"
echo "========================================"
echo ""

# Create project directory
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

echo "Copying scaffold infrastructure..."

# Copy .claude directory (agents, commands, hooks, rules, skills, settings)
cp -r "$SCAFFOLD_DIR/.claude" .

# Remove scaffold-specific files from .claude
rm -f .claude/settings.local.json  # User-specific settings
rm -f .claude/subagent.log         # Session log

# Copy configuration files
cp "$SCAFFOLD_DIR/.gitignore" .
cp "$SCAFFOLD_DIR/.mcp.json" .

# Copy CLAUDE.template.md as CLAUDE.md
cp "$SCAFFOLD_DIR/CLAUDE.template.md" CLAUDE.md

# Create _docs structure
mkdir -p _docs/context-summaries
mkdir -p _docs/maps

# Create .gitkeep files for empty directories
touch _docs/context-summaries/.gitkeep
touch _docs/maps/.gitkeep

# Copy template documentation files
cp "$SCAFFOLD_DIR/_docs/prd.md" _docs/prd.md
cp "$SCAFFOLD_DIR/_docs/architecture.md" _docs/architecture.md
cp "$SCAFFOLD_DIR/_docs/best-practices.md" _docs/best-practices.md
cp "$SCAFFOLD_DIR/_docs/task-list.json" _docs/task-list.json
cp "$SCAFFOLD_DIR/_docs/backlog.json" _docs/backlog.json

echo "Customizing placeholders..."

# Get current timestamp in ISO format
ISO_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Function to do in-place sed that works on both macOS and Linux
sed_inplace() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# Replace [PROJECT_NAME] placeholder in all md and json files
for file in $(find . -type f \( -name "*.md" -o -name "*.json" \)); do
  sed_inplace "s/\[PROJECT_NAME\]/$PROJECT_NAME/g" "$file"
done

# Replace [ISO_TIMESTAMP] placeholder in json files
for file in $(find . -type f -name "*.json"); do
  sed_inplace "s/\[ISO_TIMESTAMP\]/$ISO_TIMESTAMP/g" "$file"
done

echo "Initializing git repository..."

git init --quiet

echo "Installing git hooks..."

# Copy .githooks directory (version-controlled hooks)
cp -r "$SCAFFOLD_DIR/.githooks" .
chmod +x .githooks/*

# Configure git to use .githooks directory
git config core.hooksPath .githooks

# Create _logs directory for hook output
mkdir -p _logs

# Create initial commit
git add .
git commit --quiet -n -m "Initialize project from claude-project-template scaffold"

echo ""
echo -e "${GREEN}Project setup complete!${NC}"
echo ""
echo "========================================"
echo "NEXT STEPS"
echo "========================================"
echo ""
echo "1. Navigate to your project:"
echo -e "   ${YELLOW}cd $TARGET_DIR${NC}"
echo ""
echo "2. Customize your project documentation in _docs/:"
echo "   - prd.md           - Product requirements (REQUIRED)"
echo "   - architecture.md  - System design (REQUIRED)"
echo "   - task-list.json   - Development tasks (REQUIRED)"
echo "   - best-practices.md - Coding standards (REQUIRED)"
echo ""
echo "3. Update CLAUDE.md with project-specific commands and architecture"
echo ""
echo "4. Initialize the scaffold with Claude Code:"
echo -e "   ${YELLOW}/init-repo${NC}"
echo ""
echo "5. Start development:"
echo -e "   ${YELLOW}/dev${NC}"
echo ""
echo "========================================"
echo "GIT HOOKS"
echo "========================================"
echo "Location: .githooks/ (version-controlled)"
echo "Config:   git config core.hooksPath .githooks"
echo ""
echo "- pre-commit: Quality gates (tests, lint, typecheck)"
echo "- post-commit: Commit logging, bypass detection"
echo ""
echo "Edit .githooks/* to customize hooks."
echo "Hook logs written to: _logs/"
echo ""
echo "To bypass hooks temporarily (not recommended):"
echo "  git commit --no-verify -m \"message\""
echo ""
