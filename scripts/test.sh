#!/bin/bash

# Test script for ATHENA project
# Usage: ./scripts/test.sh [--unit] [--integration] [--doc] [--coverage] [--verbose]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default values
RUN_UNIT=false
RUN_INTEGRATION=false
RUN_DOC=false
RUN_COVERAGE=false
VERBOSE=false
TEST_FILTER=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --unit)
            RUN_UNIT=true
            shift
            ;;
        --integration)
            RUN_INTEGRATION=true
            shift
            ;;
        --doc)
            RUN_DOC=true
            shift
            ;;
        --coverage)
            RUN_COVERAGE=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --filter)
            TEST_FILTER="$2"
            shift 2
            ;;
        --all)
            RUN_UNIT=true
            RUN_INTEGRATION=true
            RUN_DOC=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --unit         Run unit tests only"
            echo "  --integration  Run integration tests only"
            echo "  --doc          Run documentation tests"
            echo "  --coverage     Generate coverage report"
            echo "  --all          Run all tests"
            echo "  --filter TERM  Filter tests by name"
            echo "  --verbose      Enable verbose output"
            echo "  --help         Show this help message"
            echo ""
            echo "If no test type is specified, runs all tests."
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# If no specific test type is chosen, run all
if [ "$RUN_UNIT" = false ] && [ "$RUN_INTEGRATION" = false ] && [ "$RUN_DOC" = false ]; then
    RUN_UNIT=true
    RUN_INTEGRATION=true
    RUN_DOC=true
fi

cd "$PROJECT_ROOT"

echo "🧪 Testing ATHENA project..."
echo "📁 Project root: $PROJECT_ROOT"

# Construct base cargo command
CARGO_BASE="cargo test"
if [ "$VERBOSE" = true ]; then
    CARGO_BASE="$CARGO_BASE --verbose"
fi

if [ -n "$TEST_FILTER" ]; then
    CARGO_BASE="$CARGO_BASE $TEST_FILTER"
fi

# Run unit tests
if [ "$RUN_UNIT" = true ]; then
    echo ""
    echo "🔬 Running unit tests..."
    eval "$CARGO_BASE --lib --workspace"
fi

# Run integration tests
if [ "$RUN_INTEGRATION" = true ]; then
    echo ""
    echo "🔗 Running integration tests..."
    eval "$CARGO_BASE --test '*' --workspace"
fi

# Run documentation tests
if [ "$RUN_DOC" = true ]; then
    echo ""
    echo "📚 Running documentation tests..."
    eval "$CARGO_BASE --doc --workspace"
fi

# Generate coverage report
if [ "$RUN_COVERAGE" = true ]; then
    echo ""
    echo "📊 Generating coverage report..."
    
    # Check if cargo-tarpaulin is installed
    if ! command -v cargo-tarpaulin &> /dev/null; then
        echo "⚠️  cargo-tarpaulin not found. Installing..."
        cargo install cargo-tarpaulin
    fi
    
    cargo tarpaulin --workspace --out Html --output-dir coverage/
    echo "📈 Coverage report generated in coverage/tarpaulin-report.html"
fi

echo ""
echo "✅ All tests completed successfully!"

# Run clippy for additional checks
echo ""
echo "📎 Running clippy for additional checks..."
cargo clippy --all-targets --all-features --workspace -- -D warnings

echo ""
echo "🎉 Test process completed!"