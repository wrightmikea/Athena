#!/bin/bash

# Debug script for ATHENA project
# Usage: ./scripts/debug.sh [COMPONENT] [OPTIONS]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default values
COMPONENT=""
DEBUG_TOOL="gdb"
ATTACH_PID=""
CORE_FILE=""
VERBOSE=false
LOG_LEVEL="debug"

show_help() {
    echo "Usage: $0 [COMPONENT] [OPTIONS]"
    echo ""
    echo "Components:"
    echo "  test          Debug failing tests"
    echo "  core          Debug core library"
    echo "  agent         Debug agent process"
    echo "  mcp           Debug MCP server"
    echo "  distributed   Debug distributed system"
    echo ""
    echo "Options:"
    echo "  --tool TOOL   Debug tool (gdb, lldb, valgrind)"
    echo "  --attach PID  Attach to running process"
    echo "  --core FILE   Analyze core dump"
    echo "  --verbose     Enable verbose debugging"
    echo "  --log-level   Set log level (trace, debug, info, warn, error)"
    echo "  --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 test --verbose              # Debug failing tests"
    echo "  $0 core --tool lldb            # Debug core with lldb"
    echo "  $0 agent --attach 1234         # Attach to running agent"
    echo "  $0 distributed --log-level trace  # Distributed system debug"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        test|core|agent|mcp|distributed)
            COMPONENT="$1"
            shift
            ;;
        --tool)
            DEBUG_TOOL="$2"
            shift 2
            ;;
        --attach)
            ATTACH_PID="$2"
            shift 2
            ;;
        --core)
            CORE_FILE="$2"
            shift 2
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --log-level)
            LOG_LEVEL="$2"
            shift 2
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$COMPONENT" ]; then
    echo "❌ No component specified."
    show_help
    exit 1
fi

cd "$PROJECT_ROOT"

echo "🐛 Debugging ATHENA component: $COMPONENT"
echo "📁 Project root: $PROJECT_ROOT"
echo "🔧 Debug tool: $DEBUG_TOOL"
echo "📊 Log level: $LOG_LEVEL"

# Set up environment
export RUST_LOG="$LOG_LEVEL"
export RUST_BACKTRACE=1

if [ "$VERBOSE" = true ]; then
    export RUST_LOG="trace"
    export RUST_BACKTRACE="full"
fi

case $COMPONENT in
    test)
        echo "🧪 Debugging tests..."
        echo ""
        
        # Run tests with debugging
        echo "🔍 Running tests with full backtrace..."
        RUST_BACKTRACE=full cargo test --workspace -- --nocapture
        
        # Check for common issues
        echo ""
        echo "🔍 Checking for common issues..."
        
        # Check for memory leaks (if valgrind is available)
        if command -v valgrind &> /dev/null && [ "$DEBUG_TOOL" = "valgrind" ]; then
            echo "🔍 Running memory leak detection..."
            cargo build --tests
            find target/debug/deps -name "*athena*" -type f -executable | head -1 | xargs valgrind --leak-check=full --show-leak-kinds=all
        fi
        
        # Check for undefined behavior (if miri is available)
        if command -v cargo-miri &> /dev/null; then
            echo "🔍 Running undefined behavior detection..."
            cargo miri test
        else
            echo "💡 Install cargo-miri for UB detection: cargo install miri"
        fi
        ;;
        
    core)
        echo "🔧 Debugging core library..."
        
        if [ -n "$CORE_FILE" ]; then
            echo "🔍 Analyzing core dump: $CORE_FILE"
            $DEBUG_TOOL -c "$CORE_FILE"
        elif [ -n "$ATTACH_PID" ]; then
            echo "🔍 Attaching to process: $ATTACH_PID"
            $DEBUG_TOOL -p "$ATTACH_PID"
        else
            echo "🔍 Building debug version and starting interactive session..."
            cargo build
            
            # Create a debug binary
            cat > /tmp/debug_core.rs << 'EOF'
use athena_core::prelude::*;

fn main() -> Result<()> {
    println!("🐛 ATHENA Core Debug Session");
    println!("============================");
    
    // Set up debugging
    let node_id = NodeId::new();
    let source = Source::new(node_id, "debug-session");
    
    println!("Debug breakpoint - examine state");
    // Debugger will stop here
    
    Ok(())
}
EOF
            
            rustc --edition 2021 -g -L target/debug/deps /tmp/debug_core.rs -o /tmp/debug_core --extern athena_core=target/debug/libathena_core.rlib
            
            echo "🎯 Starting debugger..."
            $DEBUG_TOOL /tmp/debug_core
        fi
        ;;
        
    agent)
        echo "🤖 Debugging agent..."
        echo "⚠️  Agent not yet implemented (Phase 2)"
        echo ""
        echo "🔮 Future debugging capabilities:"
        echo "  📊 Agent performance profiling"
        echo "  🔍 Event processing pipeline debugging"
        echo "  🌐 Network communication debugging"
        echo "  ⏱️  Time synchronization debugging"
        ;;
        
    mcp)
        echo "🔌 Debugging MCP server..."
        echo "⚠️  MCP server not yet implemented (Phase 4)"
        echo ""
        echo "🔮 Future debugging capabilities:"
        echo "  🔗 Protocol message debugging"
        echo "  🤖 LLM integration debugging"
        echo "  📡 Server connection debugging"
        ;;
        
    distributed)
        echo "🌐 Debugging distributed system..."
        echo ""
        echo "📊 System Information:"
        echo "---------------------"
        echo "🖥️  Available hosts:"
        echo "   - hive.local (server)"
        echo "   - big72.local (workstation)"
        echo "   - mighty (laptop)"
        echo ""
        
        # Check network connectivity
        echo "🌐 Network connectivity check:"
        for host in hive.local big72.local mighty; do
            if ping -c 1 -W 1000 "$host" &>/dev/null; then
                echo "   ✅ $host - reachable"
            else
                echo "   ❌ $host - unreachable"
            fi
        done
        
        echo ""
        echo "🔍 Distributed debugging tools:"
        echo "   📈 Use 'scripts/monitor.sh' for system monitoring"
        echo "   📊 Use 'scripts/trace.sh' for distributed tracing"
        echo "   ⏱️  Use 'scripts/sync.sh' for time synchronization"
        echo ""
        echo "⚠️  Full distributed debugging will be available in Phase 2+"
        
        # Show current system state
        echo ""
        echo "💻 Current system state:"
        echo "   🖥️  Hostname: $(hostname)"
        echo "   🔢 PID: $$"
        echo "   👤 User: $(whoami)"
        echo "   📁 PWD: $(pwd)"
        echo "   🕐 Time: $(date)"
        ;;
        
    *)
        echo "❌ Unknown component: $COMPONENT"
        show_help
        exit 1
        ;;
esac

echo ""
echo "🎉 Debug session completed!"