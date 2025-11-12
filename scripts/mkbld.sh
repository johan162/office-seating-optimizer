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

# Warn for uncommitted changes or untracked files
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
# Step 2.2: Build Project
# --------------------------------------
log_step 2.2 "Building project..."

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

# --------------------------------------
# Build Container Image
# --------------------------------------
log_step 2.3 "Building container image..."
if ! make c-build >/dev/null 2>&1; then
    log_error "Container image build failed. Run 'make c-build' manually to see errors."
    exit 1
fi
log_info "Container image built successfully!"



# =====================================
# Step 3: Cleanup and Return
# =====================================

log_step 3 "Cleaning up..."

if [ "$(git branch --show-current)" != "$ORIGINAL_BRANCH" ]; then
    # Switch back to original branch
    log_info "Switching back to $ORIGINAL_BRANCH..."
    git checkout "$ORIGINAL_BRANCH"
fi

log_success "Build completed successfully."

# End of script
