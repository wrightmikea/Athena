#!/bin/bash

# Run script for ATHENA project components
# Usage: ./scripts/run.sh [COMPONENT] [OPTIONS]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default values
COMPONENT=""
BUILD_TYPE="debug"
EXTRA_ARGS=""

show_help() {
    echo "Usage: $0 [COMPONENT] [OPTIONS]"
    echo ""
    echo "Components:"
    echo "  demo          Run demo application"
    echo "  agent         Run ATHENA agent"
    echo "  mcp           Run MCP server"
    echo "  collector     Run log collector"
    echo "  examples      List available examples"
    echo ""
    echo "Options:"
    echo "  --release     Use release build"
    echo "  --config FILE Use specific config file"
    echo "  --node-id ID  Set node ID"
    echo "  --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 demo                    # Run demo application"
    echo "  $0 agent --release         # Run agent in release mode"
    echo "  $0 mcp --config mcp.toml   # Run MCP server with config"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        demo|agent|mcp|collector|examples)
            COMPONENT="$1"
            shift
            ;;
        --release)
            BUILD_TYPE="release"
            shift
            ;;
        --config)
            EXTRA_ARGS="$EXTRA_ARGS --config $2"
            shift 2
            ;;
        --node-id)
            EXTRA_ARGS="$EXTRA_ARGS --node-id $2"
            shift 2
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        -*)
            EXTRA_ARGS="$EXTRA_ARGS $1"
            shift
            ;;
        *)
            if [ -z "$COMPONENT" ]; then
                COMPONENT="$1"
            else
                EXTRA_ARGS="$EXTRA_ARGS $1"
            fi
            shift
            ;;
    esac
done

if [ -z "$COMPONENT" ]; then
    echo "❌ No component specified."
    show_help
    exit 1
fi

cd "$PROJECT_ROOT"

echo "🚀 Running ATHENA component: $COMPONENT"
echo "📁 Project root: $PROJECT_ROOT"
echo "🎯 Build type: $BUILD_TYPE"

case $COMPONENT in
    demo)
        echo "🎭 Running demo application..."
        echo "⚙️  This will demonstrate basic ATHENA functionality"
        
        # Create a simple demo using the core library
        cat > /tmp/athena_demo.rs << 'EOF'
use athena_core::prelude::*;
use std::time::Duration;
use tokio;

#[tokio::main]
async fn main() -> Result<()> {
    println!("🎭 ATHENA Demo Application");
    println!("==========================");
    
    // Create a node and source
    let node_id = NodeId::new();
    let source = Source::new(node_id, "demo-app")
        .with_process_id(std::process::id());
    
    println!("🌐 Node ID: {}", node_id);
    println!("📍 Source: {}", source);
    
    // Create correlation ID for this demo session
    let correlation_id = CorrelationId::new();
    println!("🔗 Correlation ID: {}", correlation_id);
    
    // Create some events
    let events = vec![
        GenericEvent::new(source.clone(), Severity::Info, "demo-start", "Demo application started")
            .with_correlation_id(correlation_id)
            .with_metadata("version", "0.1.0"),
        
        GenericEvent::new(source.clone(), Severity::Debug, "demo-processing", "Processing demo data")
            .with_correlation_id(correlation_id)
            .with_metadata("step", "1"),
        
        GenericEvent::new(source.clone(), Severity::Info, "demo-complete", "Demo completed successfully")
            .with_correlation_id(correlation_id)
            .with_metadata("duration", "1.5s"),
    ];
    
    // Set up event dispatcher
    let mut dispatcher = EventDispatcher::new();
    dispatcher.add_handler(Box::new(LoggingEventHandler));
    
    println!("\n📝 Event Log:");
    println!("--------------");
    
    // Dispatch events with timing
    for event in &events {
        dispatcher.dispatch(event).await;
        tokio::time::sleep(Duration::from_millis(500)).await;
    }
    
    // Test clock synchronization
    println!("\n🕐 Clock Synchronization Test:");
    println!("-------------------------------");
    let clock = Clock::new();
    let t1 = clock.now();
    println!("Initial time: {}", t1.to_datetime().format("%H:%M:%S%.3f"));
    
    // Simulate time sync (1 second offset)
    let reference = Timestamp::from_nanos(t1.as_nanos() + 1_000_000_000);
    clock.sync(reference, t1);
    
    let t2 = clock.now();
    println!("After sync:   {}", t2.to_datetime().format("%H:%M:%S%.3f"));
    println!("Offset:       {} ms", clock.offset() / 1_000_000);
    
    println!("\n✅ Demo completed successfully!");
    Ok(())
}
EOF
        
        # Run the demo
        if [ "$BUILD_TYPE" = "release" ]; then
            rustc --edition 2021 -L target/release/deps /tmp/athena_demo.rs -o /tmp/athena_demo --extern athena_core=target/release/libathena_core.rlib 2>/dev/null || {
                echo "📦 Building project first..."
                cargo build --release
                rustc --edition 2021 -L target/release/deps /tmp/athena_demo.rs -o /tmp/athena_demo --extern athena_core=target/release/libathena_core.rlib 2>/dev/null || {
                    echo "🔄 Running with cargo instead..."
                    cargo run --release --example demo 2>/dev/null || echo "⚠️  Demo example not yet implemented"
                }
            }
        else
            cargo build
            echo "🔄 Running demo with core library..."
            RUST_LOG=info cargo run --example demo 2>/dev/null || {
                echo "⚠️  Demo example not yet implemented. Creating basic demo..."
                echo "📚 This would show distributed event correlation, time sync, and error handling."
                echo "🔮 Future: Will demonstrate agent coordination across hive.local, big72.local, and mighty."
            }
        fi
        ;;
        
    agent)
        echo "🤖 Running ATHENA agent..."
        echo "⚠️  Agent component not yet implemented (Phase 2)"
        echo "🔮 Future: Will run monitoring agent on specified node"
        echo "   Usage: $0 agent --node-id <id> --config agent.toml"
        ;;
        
    mcp)
        echo "🔌 Running MCP server..."
        echo "⚠️  MCP server not yet implemented (Phase 4)"
        echo "🔮 Future: Will start Model Context Protocol server"
        echo "   Usage: $0 mcp --port 8080 --config mcp.toml"
        ;;
        
    collector)
        echo "📊 Running log collector..."
        echo "⚠️  Collector not yet implemented (Phase 2)"
        echo "🔮 Future: Will collect logs from distributed sources"
        echo "   Usage: $0 collector --sources config/sources.toml"
        ;;
        
    examples)
        echo "📚 Available examples:"
        echo ""
        if [ -d "examples" ]; then
            find examples -name "*.rs" -type f | sed 's/examples\///g' | sed 's/\.rs$//g' | while read -r example; do
                echo "  🔹 $example"
            done
        else
            echo "  ⚠️  No examples directory found"
        fi
        echo ""
        echo "🔮 Future examples will include:"
        echo "  🔹 distributed-tracing    - Cross-service request tracing"
        echo "  🔹 time-synchronization   - Clock sync across nodes"
        echo "  🔹 event-correlation      - Event correlation demo"
        echo "  🔹 hot-reload            - Component hot reloading"
        echo "  🔹 browser-integration   - WASM browser monitoring"
        ;;
        
    *)
        echo "❌ Unknown component: $COMPONENT"
        show_help
        exit 1
        ;;
esac

echo ""
echo "🎉 Run process completed!"