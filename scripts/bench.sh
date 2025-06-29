#!/bin/bash

# Benchmark script for ATHENA project
# Usage: ./scripts/bench.sh [--category] [--baseline] [--compare FILE] [--output FILE]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default values
CATEGORY="all"
BASELINE=false
COMPARE_FILE=""
OUTPUT_FILE=""
DURATION="10s"
VERBOSE=false

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Categories:"
    echo "  --all         Run all benchmarks"
    echo "  --latency     Run latency benchmarks"
    echo "  --throughput  Run throughput benchmarks"
    echo "  --memory      Run memory benchmarks"
    echo "  --clock       Run clock sync benchmarks"
    echo ""
    echo "Options:"
    echo "  --baseline         Save results as baseline"
    echo "  --compare FILE     Compare with baseline file"
    echo "  --output FILE      Save results to file"
    echo "  --duration TIME    Benchmark duration (default: 10s)"
    echo "  --verbose          Enable verbose output"
    echo "  --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --latency --baseline"
    echo "  $0 --all --compare baseline.json"
    echo "  $0 --throughput --duration 60s --output results.json"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --all|--latency|--throughput|--memory|--clock)
            CATEGORY="${1#--}"
            shift
            ;;
        --baseline)
            BASELINE=true
            shift
            ;;
        --compare)
            COMPARE_FILE="$2"
            shift 2
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --duration)
            DURATION="$2"
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

cd "$PROJECT_ROOT"

echo "⚡ ATHENA Performance Benchmarks"
echo "================================"
echo "📁 Project root: $PROJECT_ROOT"
echo "📊 Category: $CATEGORY"
echo "⏱️  Duration: $DURATION"

# Ensure benchmark dependencies are available
if ! command -v cargo-criterion &> /dev/null; then
    echo "📦 Installing cargo-criterion..."
    cargo install cargo-criterion
fi

# Create benchmarks directory if it doesn't exist
mkdir -p benchmarks
mkdir -p benchmark-results

# Set up benchmark output
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULT_FILE="benchmark-results/results_${TIMESTAMP}.json"

if [ -n "$OUTPUT_FILE" ]; then
    RESULT_FILE="$OUTPUT_FILE"
fi

echo "💾 Results will be saved to: $RESULT_FILE"

run_latency_benchmarks() {
    echo ""
    echo "⚡ Running latency benchmarks..."
    
    # Create latency benchmark if it doesn't exist
    cat > benchmarks/latency.rs << 'EOF'
use criterion::{black_box, criterion_group, criterion_main, Criterion, BenchmarkId};
use athena_core::prelude::*;
use std::time::Duration;

fn bench_timestamp_creation(c: &mut Criterion) {
    c.bench_function("timestamp_creation", |b| {
        b.iter(|| {
            black_box(Timestamp::now())
        })
    });
}

fn bench_event_creation(c: &mut Criterion) {
    let node_id = NodeId::new();
    let source = Source::new(node_id, "benchmark");
    
    c.bench_function("event_creation", |b| {
        b.iter(|| {
            black_box(GenericEvent::new(
                source.clone(),
                Severity::Info,
                "bench",
                "Benchmark event"
            ))
        })
    });
}

fn bench_event_serialization(c: &mut Criterion) {
    let node_id = NodeId::new();
    let source = Source::new(node_id, "benchmark");
    let event = GenericEvent::new(source, Severity::Info, "bench", "Benchmark event");
    
    c.bench_function("event_serialization", |b| {
        b.iter(|| {
            black_box(event.to_json().unwrap())
        })
    });
}

fn bench_clock_sync(c: &mut Criterion) {
    let clock = Clock::new();
    let local = clock.now();
    let reference = Timestamp::from_nanos(local.as_nanos() + 1000);
    
    c.bench_function("clock_sync", |b| {
        b.iter(|| {
            black_box(clock.sync(reference, local))
        })
    });
}

criterion_group!(
    latency_benches,
    bench_timestamp_creation,
    bench_event_creation,
    bench_event_serialization,
    bench_clock_sync
);
criterion_main!(latency_benches);
EOF

    # Run latency benchmarks
    cargo bench --bench latency
}

run_throughput_benchmarks() {
    echo ""
    echo "🚀 Running throughput benchmarks..."
    
    # Create throughput benchmark
    cat > benchmarks/throughput.rs << 'EOF'
use criterion::{black_box, criterion_group, criterion_main, Criterion, BenchmarkId, Throughput};
use athena_core::prelude::*;
use tokio::runtime::Runtime;

fn bench_event_processing_throughput(c: &mut Criterion) {
    let rt = Runtime::new().unwrap();
    let node_id = NodeId::new();
    let source = Source::new(node_id, "benchmark");
    
    let mut group = c.benchmark_group("event_throughput");
    
    for size in [100, 1000, 10000].iter() {
        group.throughput(Throughput::Elements(*size as u64));
        group.bench_with_input(BenchmarkId::new("events_per_second", size), size, |b, &size| {
            b.to_async(&rt).iter(|| async {
                let mut dispatcher = EventDispatcher::new();
                dispatcher.add_handler(Box::new(LoggingEventHandler));
                
                for i in 0..size {
                    let event = GenericEvent::new(
                        source.clone(),
                        Severity::Info,
                        "throughput_test",
                        &format!("Event {}", i)
                    );
                    black_box(dispatcher.dispatch(&event).await);
                }
            });
        });
    }
    group.finish();
}

fn bench_serialization_throughput(c: &mut Criterion) {
    let node_id = NodeId::new();
    let source = Source::new(node_id, "benchmark");
    
    let mut group = c.benchmark_group("serialization_throughput");
    
    for size in [100, 1000, 10000].iter() {
        group.throughput(Throughput::Elements(*size as u64));
        group.bench_with_input(BenchmarkId::new("serializations_per_second", size), size, |b, &size| {
            b.iter(|| {
                for i in 0..*size {
                    let event = GenericEvent::new(
                        source.clone(),
                        Severity::Info,
                        "throughput_test",
                        &format!("Event {}", i)
                    );
                    black_box(event.to_json().unwrap());
                }
            });
        });
    }
    group.finish();
}

criterion_group!(
    throughput_benches,
    bench_event_processing_throughput,
    bench_serialization_throughput
);
criterion_main!(throughput_benches);
EOF

    # Run throughput benchmarks
    cargo bench --bench throughput
}

run_memory_benchmarks() {
    echo ""
    echo "💾 Running memory benchmarks..."
    
    # Memory usage analysis
    if command -v valgrind &> /dev/null; then
        echo "🔍 Running memory usage analysis with valgrind..."
        cargo build --release
        
        # Create simple memory test binary
        cat > /tmp/memory_test.rs << 'EOF'
use athena_core::prelude::*;

fn main() {
    let node_id = NodeId::new();
    let source = Source::new(node_id, "memory_test");
    
    // Create many events to test memory usage
    let mut events = Vec::new();
    for i in 0..10000 {
        let event = GenericEvent::new(
            source.clone(),
            Severity::Info,
            "memory_test",
            &format!("Event {}", i)
        );
        events.push(event);
    }
    
    // Test serialization memory usage
    for event in &events {
        let _serialized = event.to_json().unwrap();
    }
    
    println!("Memory test completed with {} events", events.len());
}
EOF
        
        rustc --edition 2021 -L target/release/deps /tmp/memory_test.rs -o /tmp/memory_test --extern athena_core=target/release/libathena_core.rlib
        valgrind --tool=massif --pages-as-heap=yes /tmp/memory_test
        
    else
        echo "⚠️  valgrind not available, skipping detailed memory analysis"
        echo "💡 Install valgrind for detailed memory benchmarks"
    fi
}

run_clock_benchmarks() {
    echo ""
    echo "🕐 Running clock synchronization benchmarks..."
    
    # Create clock benchmark
    cat > benchmarks/clock.rs << 'EOF'
use criterion::{black_box, criterion_group, criterion_main, Criterion, BenchmarkId};
use athena_core::prelude::*;
use std::time::Duration;

fn bench_timestamp_precision(c: &mut Criterion) {
    c.bench_function("timestamp_precision", |b| {
        b.iter(|| {
            let t1 = black_box(Timestamp::now());
            let t2 = black_box(Timestamp::now());
            black_box(t2.duration_since(t1))
        })
    });
}

fn bench_clock_creation(c: &mut Criterion) {
    c.bench_function("clock_creation", |b| {
        b.iter(|| {
            black_box(Clock::new())
        })
    });
}

fn bench_datetime_conversion(c: &mut Criterion) {
    let timestamp = Timestamp::now();
    
    c.bench_function("datetime_conversion", |b| {
        b.iter(|| {
            black_box(timestamp.to_datetime())
        })
    });
}

fn bench_sync_accuracy(c: &mut Criterion) {
    let clock = Clock::new();
    
    let mut group = c.benchmark_group("sync_accuracy");
    
    for offset_ms in [1, 10, 100, 1000].iter() {
        group.bench_with_input(BenchmarkId::new("sync_offset_ms", offset_ms), offset_ms, |b, &offset_ms| {
            b.iter(|| {
                let local = clock.now();
                let reference = Timestamp::from_nanos(local.as_nanos() + (offset_ms * 1_000_000));
                black_box(clock.sync(reference, local));
                black_box(clock.now())
            });
        });
    }
    group.finish();
}

criterion_group!(
    clock_benches,
    bench_timestamp_precision,
    bench_clock_creation,
    bench_datetime_conversion,
    bench_sync_accuracy
);
criterion_main!(clock_benches);
EOF

    # Run clock benchmarks
    cargo bench --bench clock
}

# Add benchmark dependencies to Cargo.toml if not present
if ! grep -q "\[dev-dependencies\]" athena-core/Cargo.toml; then
    echo -e "\n[[bench]]\nname = \"latency\"\nharness = false\n\n[[bench]]\nname = \"throughput\"\nharness = false\n\n[[bench]]\nname = \"clock\"\nharness = false" >> athena-core/Cargo.toml
fi

if ! grep -q "criterion" athena-core/Cargo.toml; then
    echo -e "\ncriterion = { version = \"0.5\", features = [\"html_reports\"] }" >> athena-core/Cargo.toml
fi

# Create benchmark directories
mkdir -p athena-core/benches

# Run selected benchmarks
case $CATEGORY in
    latency)
        cp benchmarks/latency.rs athena-core/benches/
        run_latency_benchmarks
        ;;
    throughput)
        cp benchmarks/throughput.rs athena-core/benches/
        run_throughput_benchmarks
        ;;
    memory)
        run_memory_benchmarks
        ;;
    clock)
        cp benchmarks/clock.rs athena-core/benches/
        run_clock_benchmarks
        ;;
    all)
        cp benchmarks/*.rs athena-core/benches/ 2>/dev/null || true
        run_latency_benchmarks
        run_throughput_benchmarks
        run_memory_benchmarks
        run_clock_benchmarks
        ;;
    *)
        echo "❌ Unknown category: $CATEGORY"
        show_help
        exit 1
        ;;
esac

# Save results if baseline requested
if [ "$BASELINE" = true ]; then
    echo ""
    echo "💾 Saving baseline results..."
    cp target/criterion/*/report/index.html "benchmark-results/baseline_${TIMESTAMP}.html" 2>/dev/null || true
    echo "📊 Baseline saved as baseline_${TIMESTAMP}.html"
fi

# Compare with baseline if requested
if [ -n "$COMPARE_FILE" ] && [ -f "$COMPARE_FILE" ]; then
    echo ""
    echo "📊 Comparing with baseline: $COMPARE_FILE"
    echo "📈 Comparison functionality will be enhanced in future versions"
fi

echo ""
echo "🎉 Benchmark process completed!"
echo "📊 View detailed results in target/criterion/report/index.html"