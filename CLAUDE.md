# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ATHENA (Automated Test Harness for Extensible Network Applications) is a distributed debugging and monitoring system written in Rust. It provides comprehensive observability across distributed applications and integrates with LLMs via Model Context Protocol (MCP).

## Development Environment

### Prerequisites
- Rust (latest stable)
- cargo-watch for development
- wasm-pack for WASM builds
- protoc for Protocol Buffers

### Build Commands
```bash
# Build all crates
cargo build --workspace

# Run tests
cargo test --workspace

# Run with watching
cargo watch -x "test --workspace" -x "clippy --workspace"

# Build WASM
cd athena-wasm && wasm-pack build --target web

# Run MCP server
cargo run --bin athena-mcp

# Format code
cargo fmt --all

# Lint
cargo clippy --all-targets --all-features -- -D warnings
```

## Architecture

### Workspace Structure
```
athena/
├── Cargo.toml              # Workspace root
├── athena-core/           # Shared types, traits, protocols
├── athena-agent/          # Server monitoring agent
├── athena-transport/      # Network communication (gRPC/WebSocket)
├── athena-collector/      # Log/metric collection
├── athena-wasm/          # Browser WASM library
├── athena-capture/       # Screen capture service
├── athena-processor/     # Event correlation engine
├── athena-store/         # Storage abstraction
├── athena-query/         # Query DSL
├── athena-mcp/           # MCP server
├── athena-registry/      # Component registry
├── athena-reload/        # Hot reload system
├── athena-viz/           # Visualization
├── athena-alert/         # Alerting
├── athena-test/          # Testing utilities
└── athena-cli/           # CLI tools
```

### Key Design Patterns

1. **Event-Driven Architecture**: All components communicate via events
2. **Plugin System**: Collectors, processors, and stores are pluggable
3. **Zero-Copy**: Use bytes::Bytes for efficient data handling
4. **Async-First**: Tokio for async runtime
5. **Type Safety**: Leverage Rust's type system extensively

### Core Dependencies
- `tokio` - Async runtime
- `serde` - Serialization
- `prost` - Protocol Buffers
- `tonic` - gRPC
- `tower` - Service middleware
- `tracing` - Structured logging
- `sqlx` - Database access

## Development Guidelines

### Code Style
- Follow Rust standard naming conventions
- Use `clippy` with all warnings as errors
- Document all public APIs
- Examples in doc comments where appropriate

### Error Handling
- Use `thiserror` for error types
- Implement `From` conversions for error propagation
- Avoid `unwrap()` except in tests
- Use `anyhow` only in binary crates

### Testing
- Unit tests in same file as code
- Integration tests in `tests/` directory
- Use `proptest` for property-based testing
- Mock external dependencies

### Performance
- Profile before optimizing
- Use `criterion` for benchmarks
- Minimize allocations in hot paths
- Consider `SmallVec` for small collections

## Common Tasks

### Adding a New Crate
```bash
cargo new athena-newcrate --lib
# Add to workspace Cargo.toml
# Update dependencies in athena-newcrate/Cargo.toml
```

### Updating Protocol Buffers
```bash
cd athena-core
# Edit proto files in src/proto/
cargo build # Regenerates Rust code
```

### Running Integration Tests
```bash
# Start test environment
docker-compose -f tests/docker-compose.yml up -d

# Run integration tests
cargo test --workspace --features integration

# Cleanup
docker-compose -f tests/docker-compose.yml down
```

### Debugging MCP Server
```bash
# Enable debug logging
RUST_LOG=debug cargo run --bin athena-mcp

# Test with MCP client
athena-cli mcp test
```

## Project-Specific Patterns

### Event Types
All events inherit from `athena_core::Event` trait:
```rust
pub trait Event: Send + Sync + 'static {
    fn timestamp(&self) -> Timestamp;
    fn source(&self) -> &Source;
    fn correlation_id(&self) -> Option<&CorrelationId>;
}
```

### Time Synchronization
Use `athena_core::clock::Clock` for consistent timestamps:
```rust
let clock = Clock::new();
let timestamp = clock.now();
```

### Hot Reload Protocol
Components implement `Reloadable` trait:
```rust
#[async_trait]
pub trait Reloadable {
    async fn prepare_reload(&self) -> Result<ReloadState>;
    async fn perform_reload(&self, state: ReloadState) -> Result<()>;
}
```

## Troubleshooting

### Common Issues
1. **Time sync issues**: Check NTP configuration
2. **High memory usage**: Enable sampling in collectors
3. **WASM build fails**: Ensure wasm-pack is latest version
4. **gRPC errors**: Verify protoc is installed

### Debug Commands
```bash
# Check agent status
athena-cli agent status

# View live events
athena-cli events tail

# Test time synchronization
athena-cli clock sync
```

## License

All code contributions must comply with the Apache License 2.0. See LICENSE.txt for full details.