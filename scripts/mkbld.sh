#!/bin/bash

# Build and optionally deploy te app to GitHub Pages

set -euo pipefail # Exit on error, undefined variables

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =====================================
# CONFIGURATION
# =====================================

declare GITHUB_USER="johan162"
declare SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare PROGRAMNAME="optimize-seating"
declare PROGRAMNAME_PRETTY="Optimize Seating"

# Function to print colored output
log_info() {
    echo -e "${GREEN}    [INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}✅ [SUCCESS!] == $1 ==${NC}"
}

log_warn() {
    echo -e "${YELLOW}⚠️ [WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}❌ [ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}🔄 [STEP $1]${NC} $2"
}

show_help() {
    cat <<EOF
🚀 ${PROGRAMNAME_PRETTY} ReleaBuild Script

DESCRIPTION:
    Build script for ${PROGRAMNAME_PRETTY} PWA.

USAGE:
    $0 [options]

OPTIONS:
    --deploy, -d    Deploy the built files to gh-pages branch
    --help, -h      Show this help message and exit
    --push, -p      Push changes in gh-pages branch to remote repository after build

EXAMPLES:
    # Show help
    $0 --help

REQUIREMENTS:
    • Must be run from project root directory
    • Must be on 'develop' branch with clean working directory

EOF
}

declare DEPLOY_AFTER_BUILD=false
declare PUSH_AFTER_BUILD=false

for arg in "$@"; do
    case $arg in
    --help | -h)
        show_help
        exit 0
        ;;
    --push | -p)
        PUSH_AFTER_BUILD=true
        shift
        ;;
    --deploy | -d)
        DEPLOY_AFTER_BUILD=true
        shift
        ;;
    -*)
        log_error "Unknown option: $arg"
        echo "Usage: $0 <version> [major|minor|patch] [--help]"
        echo "Run '$0 --help' for detailed information"
        exit 1
        ;;
    esac
done

echo -e "${BLUE}==== Commute Tracker Build Script ====${NC}"

# =====================================
# Step 1: Pre-build Checks
# =====================================

log_step 1 "Pre-build checks"

# Check if we're in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    log_error "Not a git repository. Please run this script from the root of a git repository."
    exit 1
fi

# Check that npm & npx are installed
if ! command -v npm >/dev/null 2>&1; then
    log_error "npm is not installed. Please install Node.js and npm."
    exit 1
fi

if ! command -v npx >/dev/null 2>&1; then
    log_error "npx is not installed. Please install Node.js and npm."
    exit 1
fi

# Check that make is installed
if ! command -v make >/dev/null 2>&1; then
    log_error "make is not installed. Please install make."
    exit 1
fi

# Warn if we are not on "feature/" , develop or main branch
ORIGINAL_BRANCH=$(git branch --show-current)
log_info "Current branch: $ORIGINAL_BRANCH"
if [[ "$ORIGINAL_BRANCH" != "develop" ]] && [[ "$ORIGINAL_BRANCH" != "main" ]] && [[ "$ORIGINAL_BRANCH" != feature/* ]]; then
    log_warn "You are on branch '$ORIGINAL_BRANCH'. It is recommended to run this script from the 'develop' or 'main' branch."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_error "Aborted by user"
        exit 1
    fi      
fi

if ! git diff-index --quiet HEAD -- || [[ -n $(git status --porcelain) ]]; then
    log_warn "You have uncommitted changes or untracked files in your working directory."
    git status --short
    # read -p "Continue anyway? (y/n) " -n 1 -r
    # echo
    # if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    #     log_error "Aborted by user"
    #     exit 1
    # fi
fi

# Check if gh-pages branch exists if a deploy have been requested
if [ "${DEPLOY_AFTER_BUILD}" = true ]; then
    log_info "Deployment requested, checking for gh-pages branch..."

    if ! git show-ref --verify --quiet refs/heads/gh-pages; then
        log_error "gh-pages branch does not exist"
        read -p "Fetch from origin and continue? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_error "Aborted by user"
            exit 1
        fi
        if git fetch origin gh-pages; then
            log_info "Fetched gh-pages branch from origin"
        else
            log_error "Failed to fetch gh-pages branch from origin"
            exit 1
        fi
        if git checkout -b gh-pages origin/gh-pages; then
            log_info "Checked out new branch 'gh-pages' from origin"
        else
            log_error "Failed to create 'gh-pages' branch"
            exit 1
        fi
        git branch -vv
        # Switch back to original branch
        git checkout "$ORIGINAL_BRANCH"
    fi
else
    log_info "No deployment requested, skipping gh-pages branch check."
fi

# =====================================
# Step 2: Build Project, check types, run tests
# =====================================

# --------------------------------------
# Step 2.1: Type Check
# --------------------------------------
log_step 2.1 "Typescript type check..."
if ! npx tsc --noEmit --strict >/dev/null 2>&1; then
    log_error "Type check failed. Run 'npm run type-check' manually to see errors."
    exit 1
fi
log_info "Type check passed!"

# --------------------------------------
# Step 2.2: Check test coverage meets minimum threshold
# --------------------------------------
# log_step 2.2 "Checking test coverage..."

# COVERAGE_THRESHOLD=75
# log_info "Required coverage threshold: ${COVERAGE_THRESHOLD}%"

# # Run tests with coverage and capture output
# COVERAGE_OUTPUT=$(npm run test:coverage 2>&1)

# # Extract coverage percentages from the output
# # Looking for the "All files" line which contains overall coverage
# COVERAGE_LINE=$(echo "$COVERAGE_OUTPUT" | grep "All files" | head -1)

# if [ -z "$COVERAGE_LINE" ]; then
#     log_error "Could not extract coverage information from test output"
#     log_error "Please ensure 'npm run test:coverage' produces coverage report"
#     exit 1
# fi

# # Extract the percentage values (Statements, Branch, Functions, Lines)
# # Format: "All files     |   92.7 |    84.05 |     100 |   93.72 |"
# STMT_COV=$(echo "$COVERAGE_LINE" | awk '{print $4}' | cut -d'|' -f1 | xargs)
# BRANCH_COV=$(echo "$COVERAGE_LINE" | awk '{print $6}' | cut -d'|' -f1 | xargs)
# FUNC_COV=$(echo "$COVERAGE_LINE" | awk '{print $8}' | cut -d'|' -f1 | xargs)
# LINE_COV=$(echo "$COVERAGE_LINE" | awk '{print $10}' | cut -d'|' -f1 | xargs)

# log_info "Coverage Report:"
# log_info "  Statements: ${STMT_COV}%"
# log_info "  Branches:   ${BRANCH_COV}%"
# log_info "  Functions:  ${FUNC_COV}%"
# log_info "  Lines:      ${LINE_COV}%"

# # Check if any metric is below threshold
# COVERAGE_FAILED=0

# if (($(echo "$STMT_COV < $COVERAGE_THRESHOLD" | bc -l))); then
#     log_error "Statement coverage (${STMT_COV}%) is below threshold (${COVERAGE_THRESHOLD}%)"
#     COVERAGE_FAILED=1
# fi

# if (($(echo "$BRANCH_COV < $COVERAGE_THRESHOLD" | bc -l))); then
#     log_error "Branch coverage (${BRANCH_COV}%) is below threshold (${COVERAGE_THRESHOLD}%)"
#     COVERAGE_FAILED=1
# fi

# if (($(echo "$FUNC_COV < $COVERAGE_THRESHOLD" | bc -l))); then
#     log_error "Function coverage (${FUNC_COV}%) is below threshold (${COVERAGE_THRESHOLD}%)"
#     COVERAGE_FAILED=1
# fi

# if (($(echo "$LINE_COV < $COVERAGE_THRESHOLD" | bc -l))); then
#     log_error "Line coverage (${LINE_COV}%) is below threshold (${COVERAGE_THRESHOLD}%)"
#     COVERAGE_FAILED=1
# fi

# if [ $COVERAGE_FAILED -eq 1 ]; then
#     log_error "Test coverage is below minimum threshold of ${COVERAGE_THRESHOLD}%"
#     log_error "Please add more tests to increase coverage before creating a release"
#     exit 1
# fi

# log_info "✓ Test coverage meets minimum threshold (${COVERAGE_THRESHOLD}%)"

# --------------------------------------
# Step 2.3: Build Project
# --------------------------------------
log_step 2.3 "Building project..."

# Clean previous build
log_info "Cleaning previous build..."
rm -rf dist/

# Build the project
log_info "Building project..."
if ! npm run build >/dev/null 2>&1; then
    log_error "Build failed. Run 'npm run build' manually to see errors."
    exit 1
fi

# Check if dist directory exists and has content
if [ ! -d "dist" ]; then
    log_error "dist directory not found"
    exit 1
fi

if [ -z "$(ls -A dist)" ]; then
    log_error "dist directory is empty"
    exit 1
fi

log_info "Build successful!"

# =====================================
# Step 3: Deploy to gh-pages
# =====================================
log_step 3 "Checking if we should deploy to gh-pages branch."

if [ "${DEPLOY_AFTER_BUILD}" != true ]; then
    log_info "Skipping deployment to gh-pages branch (not requested)"
else
    log_info "Deploying to gh-pages branch..."

    # Switch to gh-pages branch
    log_info "Switching to gh-pages branch..."
    if ! git checkout gh-pages; then
        log_error "Failed to checkout gh-pages branch"
        exit 1
    fi

    # Remove old files (keep .git & .gitignore in directory)
    log_info "Removing old deployment files from gh-pages..."
    git rm -rf assets *.svg *.html *.json manifest.* *.js *.log >/dev/null 2>&1 || true

    # Copy new build files
    log_info "Copying new build files..."
    cp -r dist/* .

    # Create .nojekyll file (important for GitHub Pages)
    touch .nojekyll

    # Add all files
    log_info "Adding files to git..."
    git add .

    # Check if there are changes to commit
    if git diff --cached --quiet; then
        log_warn "No changes to deploy. Exiting."
        git checkout "$ORIGINAL_BRANCH"
        exit 0
    fi

    # Commit changes
    BUILD_DATE=$(date '+%Y-%m-%d %H:%M:%S')
    log_info "Committing changes..."
    git commit -m "Deploy build - $BUILD_DATE"

    log_info "Deployment committed successfully!"

    # Push to gh-pages branch
    if [ "$PUSH_AFTER_BUILD" = true ]; then
        log_info "Pushing to remote gh-pages branch..."
        if git push origin gh-pages; then
            log_info "Pushed to remote gh-pages branch successfully!"
        else
            log_error "Failed to push to remote gh-pages branch. You may need to push manually: git push origin gh-pages"
            exit 1
        fi
    else
        log_info "Skipping push to remote gh-pages branch (not requested)"
    fi
fi

# =====================================
# Step 4: Cleanup and Return
# =====================================

log_step 4 "Cleaning up..."

if [ "$(git branch --show-current)" != "$ORIGINAL_BRANCH" ]; then
    # Switch back to original branch
    log_info "Switching back to $ORIGINAL_BRANCH..."
    git checkout "$ORIGINAL_BRANCH"
fi

log_success "Build completed successfully."

# End of script
