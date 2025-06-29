#!/bin/bash

# Build script for ATHENA project
# Usage: ./scripts/build.sh [--release] [--clean] [--workspace] [--verbose]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default values
BUILD_TYPE="dev"
CLEAN=false
WORKSPACE=false
VERBOSE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --release)
            BUILD_TYPE="release"
            shift
            ;;
        --clean)
            CLEAN=true
            shift
            ;;
        --workspace)
            WORKSPACE=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --release    Build in release mode"
            echo "  --clean      Clean before building"
            echo "  --workspace  Build entire workspace"
            echo "  --verbose    Enable verbose output"
            echo "  --help       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

cd "$PROJECT_ROOT"

echo "🔨 Building ATHENA project..."
echo "📁 Project root: $PROJECT_ROOT"
echo "🎯 Build type: $BUILD_TYPE"

# Clean if requested
if [ "$CLEAN" = true ]; then
    echo "🧹 Cleaning previous builds..."
    cargo clean
fi

# Construct cargo command
CARGO_CMD="cargo build"

if [ "$BUILD_TYPE" = "release" ]; then
    CARGO_CMD="$CARGO_CMD --release"
fi

if [ "$WORKSPACE" = true ]; then
    CARGO_CMD="$CARGO_CMD --workspace"
fi

if [ "$VERBOSE" = true ]; then
    CARGO_CMD="$CARGO_CMD --verbose"
fi

# Build the project
echo "⚙️  Running: $CARGO_CMD"
eval $CARGO_CMD

echo "✅ Build completed successfully!"

# Show build artifacts
if [ "$BUILD_TYPE" = "release" ]; then
    BUILD_DIR="target/release"
else
    BUILD_DIR="target/debug"
fi

if [ -d "$BUILD_DIR" ]; then
    echo ""
    echo "📦 Build artifacts in $BUILD_DIR:"
    find "$BUILD_DIR" -maxdepth 1 -type f -executable 2>/dev/null | head -10 | while read -r file; do
        echo "  $(basename "$file")"
    done
fi

echo ""
echo "🎉 Build process completed!"