# ATHENA Scripts

This directory contains automation scripts for building, testing, running, and debugging the ATHENA project.

## Quick Start

```bash
# Build the project
./scripts/build.sh

# Run all tests
./scripts/test.sh --all

# Run demo application
./scripts/run.sh demo

# Debug failing tests
./scripts/debug.sh test
```

## Scripts Overview

### 🔨 build.sh
Builds the ATHENA project with various options.

```bash
./scripts/build.sh [OPTIONS]

Options:
  --release    Build in release mode
  --clean      Clean before building  
  --workspace  Build entire workspace
  --verbose    Enable verbose output
```

**Examples:**
```bash
./scripts/build.sh                    # Development build
./scripts/build.sh --release          # Release build
./scripts/build.sh --clean --workspace # Clean workspace build
```

### 🧪 test.sh
Runs various types of tests with coverage options.

```bash
./scripts/test.sh [OPTIONS]

Options:
  --unit         Run unit tests only
  --integration  Run integration tests only
  --doc          Run documentation tests
  --coverage     Generate coverage report
  --all          Run all tests
  --filter TERM  Filter tests by name
```

**Examples:**
```bash
./scripts/test.sh --unit              # Unit tests only
./scripts/test.sh --all --coverage    # All tests with coverage
./scripts/test.sh --filter "clock"    # Filter for clock tests
```

### 🚀 run.sh
Runs various ATHENA components and examples.

```bash
./scripts/run.sh [COMPONENT] [OPTIONS]

Components:
  demo          Run demo application
  agent         Run ATHENA agent (Phase 2+)
  mcp           Run MCP server (Phase 4+)
  collector     Run log collector (Phase 2+)
  examples      List available examples
```

**Examples:**
```bash
./scripts/run.sh demo                 # Run demo
./scripts/run.sh demo --release       # Run demo in release mode
./scripts/run.sh examples             # List examples
```

### 🐛 debug.sh
Debugging tools and utilities.

```bash
./scripts/debug.sh [COMPONENT] [OPTIONS]

Components:
  test          Debug failing tests
  core          Debug core library
  agent         Debug agent process
  distributed   Debug distributed system
```

**Examples:**
```bash
./scripts/debug.sh test --verbose     # Debug tests with full output
./scripts/debug.sh core --tool lldb   # Debug core with LLDB
./scripts/debug.sh distributed        # Distributed system debug info
```

### ⚡ bench.sh
Performance benchmarking and profiling.

```bash
./scripts/bench.sh [OPTIONS]

Categories:
  --all         Run all benchmarks
  --latency     Run latency benchmarks
  --throughput  Run throughput benchmarks
  --memory      Run memory benchmarks
  --clock       Run clock sync benchmarks
```

**Examples:**
```bash
./scripts/bench.sh --latency --baseline       # Latency benchmarks as baseline
./scripts/bench.sh --all --compare baseline.json # Compare with baseline
./scripts/bench.sh --throughput --duration 60s   # 60-second throughput test
```

### 🌐 test-distributed.sh
Distributed system testing across multiple nodes.

```bash
./scripts/test-distributed.sh --nodes HOST1,HOST2,HOST3 [OPTIONS]

Scenarios:
  --scenario basic            Basic connectivity test
  --scenario clock-sync       Clock synchronization test
  --scenario event-flow       Event flow test (Phase 2+)
  --scenario load-test        Load testing (Phase 2+)
  --scenario failure-recovery Failure recovery test (Phase 2+)
```

**Examples:**
```bash
# Test basic connectivity
./scripts/test-distributed.sh --nodes hive.local,big72.local,mighty --scenario basic

# Clock synchronization test
./scripts/test-distributed.sh --nodes hive.local,big72.local --scenario clock-sync

# Load testing (future)
./scripts/test-distributed.sh --nodes hive.local,big72.local,mighty --load-test --duration 300s
```

## Infrastructure Setup

### Target Hosts
- **hive.local**: Server node for coordination and data storage
- **big72.local**: High-performance workstation for compute-intensive tasks
- **mighty**: Laptop for client simulation and browser testing

### Prerequisites

#### Local Development
- Rust toolchain (latest stable)
- cargo-watch (optional, for development)
- wasm-pack (for WASM builds, Phase 2+)

#### Distributed Testing
- SSH access to target hosts
- Rust toolchain on all nodes
- Network connectivity between nodes
- Optional: valgrind for memory analysis

### SSH Setup
For distributed testing, ensure SSH key-based authentication:

```bash
# Generate SSH key if needed
ssh-keygen -t rsa -b 4096

# Copy to target hosts
ssh-copy-id user@hive.local
ssh-copy-id user@big72.local
ssh-copy-id user@mighty
```

## Test Categories

### Unit Tests (23 tests)
- Clock module: timestamp creation, synchronization, drift correction
- Event module: event creation, serialization, dispatch
- Types module: ID generation, source formatting
- Error module: error classification, conversions

### Integration Tests (5 tests)
- Complete event flow across components
- Clock synchronization across processes
- Error handling workflows
- Distributed system simulation

### Performance Tests
- **Latency**: Event processing, serialization, clock sync
- **Throughput**: Events/sec, serializations/sec
- **Memory**: Usage patterns, leak detection
- **Scalability**: Multi-node performance

## CI/CD Integration

### GitHub Actions
The scripts are designed to work with GitHub Actions:

```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build and Test
        run: |
          ./scripts/build.sh --workspace
          ./scripts/test.sh --all --coverage
```

### Pre-commit Hooks
Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
./scripts/test.sh --unit
./scripts/build.sh --workspace
```

## Troubleshooting

### Common Issues

#### Build Failures
```bash
# Clean and rebuild
./scripts/build.sh --clean --workspace

# Check toolchain
rustc --version
cargo --version
```

#### Test Failures
```bash
# Run with verbose output
./scripts/test.sh --all --verbose

# Debug specific test
./scripts/debug.sh test --verbose
```

#### Distributed Test Issues
```bash
# Check connectivity
./scripts/test-distributed.sh --nodes hive.local,big72.local --scenario basic

# Debug network issues
./scripts/debug.sh distributed
```

#### Performance Issues
```bash
# Run performance benchmarks
./scripts/bench.sh --all

# Memory analysis
./scripts/bench.sh --memory
```

### Getting Help

Each script supports the `--help` flag for detailed usage information:

```bash
./scripts/build.sh --help
./scripts/test.sh --help
./scripts/run.sh --help
./scripts/debug.sh --help
./scripts/bench.sh --help
./scripts/test-distributed.sh --help
```

## Future Enhancements

### Phase 2+ Features
- Agent deployment automation
- Real-time monitoring dashboards
- Chaos engineering integration
- Mobile device testing
- Container-based isolation

### Advanced Testing
- Property-based testing expansion
- Mutation testing
- AI-powered test generation
- Automatic regression detection

### Infrastructure
- Kubernetes deployment scripts
- Cloud provider integration
- Distributed test orchestration
- Performance regression tracking