#!/bin/bash

# Distributed testing script for ATHENA project
# Usage: ./scripts/test-distributed.sh --nodes HOST1,HOST2,HOST3 [OPTIONS]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default values
NODES=""
SCENARIO="basic"
DURATION="60s"
LOAD_TEST=false
VERBOSE=false
SSH_KEY=""
USERNAME="$(whoami)"
COORDINATION_NODE=""

show_help() {
    echo "Usage: $0 --nodes HOST1,HOST2,HOST3 [OPTIONS]"
    echo ""
    echo "Required:"
    echo "  --nodes HOSTS     Comma-separated list of hosts"
    echo ""
    echo "Scenarios:"
    echo "  --scenario basic            Basic connectivity and sync test"
    echo "  --scenario clock-sync       Clock synchronization test"
    echo "  --scenario event-flow       Event flow across nodes"
    echo "  --scenario load-test        Load testing scenario"
    echo "  --scenario failure-recovery Network partition and recovery"
    echo ""
    echo "Options:"
    echo "  --duration TIME    Test duration (default: 60s)"
    echo "  --load-test        Enable load testing mode"
    echo "  --username USER    SSH username (default: current user)"
    echo "  --ssh-key PATH     SSH private key path"
    echo "  --coordinator HOST Coordination node (default: first node)"
    echo "  --verbose          Enable verbose output"
    echo "  --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --nodes hive.local,big72.local,mighty --scenario basic"
    echo "  $0 --nodes hive.local,big72.local --scenario clock-sync --duration 300s"
    echo "  $0 --nodes hive.local,big72.local,mighty --load-test --duration 600s"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --nodes)
            NODES="$2"
            shift 2
            ;;
        --scenario)
            SCENARIO="$2"
            shift 2
            ;;
        --duration)
            DURATION="$2"
            shift 2
            ;;
        --load-test)
            LOAD_TEST=true
            shift
            ;;
        --username)
            USERNAME="$2"
            shift 2
            ;;
        --ssh-key)
            SSH_KEY="$2"
            shift 2
            ;;
        --coordinator)
            COORDINATION_NODE="$2"
            shift 2
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
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

if [ -z "$NODES" ]; then
    echo "❌ No nodes specified."
    show_help
    exit 1
fi

# Parse nodes into array
IFS=',' read -ra NODE_ARRAY <<< "$NODES"
NODE_COUNT=${#NODE_ARRAY[@]}

if [ -z "$COORDINATION_NODE" ]; then
    COORDINATION_NODE="${NODE_ARRAY[0]}"
fi

echo "🌐 ATHENA Distributed Testing"
echo "============================"
echo "📁 Project root: $PROJECT_ROOT"
echo "🖥️  Nodes: ${NODE_ARRAY[*]}"
echo "👑 Coordinator: $COORDINATION_NODE"
echo "🎯 Scenario: $SCENARIO"
echo "⏱️  Duration: $DURATION"

# SSH command setup
SSH_CMD="ssh"
if [ -n "$SSH_KEY" ]; then
    SSH_CMD="ssh -i $SSH_KEY"
fi

# Function to execute command on remote node
execute_on_node() {
    local node="$1"
    local command="$2"
    local description="$3"
    
    if [ "$VERBOSE" = true ]; then
        echo "🔧 [$node] $description"
        echo "   Command: $command"
    fi
    
    if [ "$node" = "$(hostname)" ] || [ "$node" = "localhost" ]; then
        eval "$command"
    else
        $SSH_CMD "$USERNAME@$node" "$command"
    fi
}

# Function to check node connectivity
check_connectivity() {
    echo ""
    echo "🌐 Checking node connectivity..."
    
    local failed_nodes=()
    
    for node in "${NODE_ARRAY[@]}"; do
        if [ "$node" = "$(hostname)" ] || [ "$node" = "localhost" ]; then
            echo "   ✅ $node (local)"
            continue
        fi
        
        if ping -c 1 -W 1000 "$node" &>/dev/null; then
            if $SSH_CMD -o ConnectTimeout=5 "$USERNAME@$node" "echo 'SSH OK'" &>/dev/null; then
                echo "   ✅ $node (ping + SSH)"
            else
                echo "   ⚠️  $node (ping OK, SSH failed)"
                failed_nodes+=("$node")
            fi
        else
            echo "   ❌ $node (unreachable)"
            failed_nodes+=("$node")
        fi
    done
    
    if [ ${#failed_nodes[@]} -gt 0 ]; then
        echo "⚠️  Warning: ${#failed_nodes[@]} nodes failed connectivity check"
        echo "   Failed nodes: ${failed_nodes[*]}"
        echo "   Continuing with available nodes..."
    fi
}

# Function to deploy test binaries
deploy_test_binaries() {
    echo ""
    echo "📦 Deploying test binaries to nodes..."
    
    # Build project
    echo "🔨 Building project..."
    cargo build --release
    
    for node in "${NODE_ARRAY[@]}"; do
        if [ "$node" = "$(hostname)" ] || [ "$node" = "localhost" ]; then
            echo "   📍 $node (local, skipping deploy)"
            continue
        fi
        
        echo "   📤 Deploying to $node..."
        
        # Create remote directory
        execute_on_node "$node" "mkdir -p ~/athena-test" "Creating test directory"
        
        # Copy test binary and configs
        if [ -f "target/release/athena-test" ]; then
            scp target/release/athena-test "$USERNAME@$node:~/athena-test/"
        fi
        
        # Copy test scripts
        scp -r scripts "$USERNAME@$node:~/athena-test/" 2>/dev/null || true
        
        echo "   ✅ $node deployment complete"
    done
}

# Basic connectivity and sync test
run_basic_test() {
    echo ""
    echo "🔍 Running basic distributed test..."
    
    local test_id="basic_$(date +%s)"
    local results=()
    
    # Start test on all nodes
    for node in "${NODE_ARRAY[@]}"; do
        echo "   🚀 Starting basic test on $node..."
        
        local test_cmd="echo 'Test ID: $test_id' && echo 'Node: $node' && echo 'Time: \$(date)' && echo 'Rust version: \$(rustc --version 2>/dev/null || echo \"Not available\")'"
        
        local result
        result=$(execute_on_node "$node" "$test_cmd" "Basic test execution" 2>&1)
        results+=("$node: $result")
    done
    
    # Display results
    echo ""
    echo "📊 Basic test results:"
    for result in "${results[@]}"; do
        echo "   $result"
    done
}

# Clock synchronization test
run_clock_sync_test() {
    echo ""
    echo "🕐 Running clock synchronization test..."
    
    local sync_times=()
    
    # Collect timestamps from all nodes
    for node in "${NODE_ARRAY[@]}"; do
        echo "   ⏰ Getting timestamp from $node..."
        
        local timestamp
        timestamp=$(execute_on_node "$node" "date +%s.%N" "Getting timestamp")
        sync_times+=("$node:$timestamp")
        
        if [ "$VERBOSE" = true ]; then
            echo "     $node timestamp: $timestamp"
        fi
    done
    
    # Analyze synchronization
    echo ""
    echo "📊 Clock synchronization analysis:"
    local max_diff=0
    local reference_time=""
    
    for sync_time in "${sync_times[@]}"; do
        local node_name="${sync_time%%:*}"
        local node_time="${sync_time##*:}"
        
        if [ -z "$reference_time" ]; then
            reference_time="$node_time"
            echo "   📍 Reference time ($node_name): $node_time"
            continue
        fi
        
        local diff
        diff=$(echo "$node_time - $reference_time" | bc -l 2>/dev/null || echo "0")
        local abs_diff
        abs_diff=$(echo "${diff#-}" | bc -l 2>/dev/null || echo "0")
        
        echo "   🔍 $node_name offset: ${diff}s"
        
        if (( $(echo "$abs_diff > $max_diff" | bc -l 2>/dev/null || echo "0") )); then
            max_diff="$abs_diff"
        fi
    done
    
    echo "   📈 Maximum time difference: ${max_diff}s"
    
    if (( $(echo "$max_diff < 0.1" | bc -l 2>/dev/null || echo "0") )); then
        echo "   ✅ Clock synchronization: GOOD (< 100ms)"
    elif (( $(echo "$max_diff < 1.0" | bc -l 2>/dev/null || echo "0") )); then
        echo "   ⚠️  Clock synchronization: FAIR (< 1s)"
    else
        echo "   ❌ Clock synchronization: POOR (> 1s)"
    fi
}

# Event flow test
run_event_flow_test() {
    echo ""
    echo "📨 Running event flow test..."
    echo "⚠️  Event flow testing requires agent implementation (Phase 2)"
    echo ""
    echo "🔮 Future event flow test will:"
    echo "   📤 Generate events on $COORDINATION_NODE"
    echo "   📨 Distribute events to all nodes"
    echo "   📥 Collect and correlate events"
    echo "   📊 Measure end-to-end latency"
    echo "   🔗 Verify correlation ID propagation"
}

# Load testing
run_load_test() {
    echo ""
    echo "⚡ Running load test..."
    echo "⚠️  Load testing requires full system implementation"
    echo ""
    echo "🔮 Future load test will:"
    echo "   📊 Generate $((NODE_COUNT * 1000)) events/sec per node"
    echo "   ⏱️  Run for $DURATION"
    echo "   📈 Monitor resource usage"
    echo "   🔍 Check for dropped events"
    echo "   📊 Generate performance report"
}

# Failure and recovery test
run_failure_recovery_test() {
    echo ""
    echo "💥 Running failure and recovery test..."
    echo "⚠️  Failure testing requires network simulation tools"
    echo ""
    echo "🔮 Future failure test will:"
    echo "   🔌 Simulate network partitions"
    echo "   💻 Simulate node failures"
    echo "   🔄 Test automatic recovery"
    echo "   📊 Measure recovery time"
    echo "   🔍 Verify data consistency"
}

# Main test execution
main() {
    check_connectivity
    
    case $SCENARIO in
        basic)
            run_basic_test
            ;;
        clock-sync)
            run_clock_sync_test
            ;;
        event-flow)
            run_event_flow_test
            ;;
        load-test)
            run_load_test
            ;;
        failure-recovery)
            run_failure_recovery_test
            ;;
        *)
            echo "❌ Unknown scenario: $SCENARIO"
            show_help
            exit 1
            ;;
    esac
    
    echo ""
    echo "🎉 Distributed test completed!"
    echo "📊 Test summary:"
    echo "   🖥️  Nodes tested: $NODE_COUNT"
    echo "   🎯 Scenario: $SCENARIO"
    echo "   ⏱️  Duration: $DURATION"
    echo "   📅 Completed: $(date)"
}

# Run main function
main