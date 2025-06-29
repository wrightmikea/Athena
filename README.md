# ATHENA - Automated Test Harness for Extensible Network Applications

A distributed debugging and monitoring system that provides comprehensive observability across distributed applications with LLM integration via Model Context Protocol.

## Overview

ATHENA enables developers and LLMs to understand what's happening across entire distributed systems through:

- **Unified Timeline**: Synchronized logs, metrics, and events from all components
- **Screen Capture**: Visual debugging with automated screen capture
- **Browser Integration**: JavaScript console logs and WASM application monitoring  
- **Hot Reloading**: Dynamic component updates without system restart
- **LLM Integration**: Model Context Protocol server for AI-assisted debugging

## Key Features

### 🔍 Comprehensive Monitoring
- Server logs with microsecond precision
- Browser console and network capture
- Screen recording with event correlation
- Custom application metrics

### 🤖 LLM-Powered Analysis
- MCP server for Claude, GPT-4, and other LLMs
- Natural language queries across distributed logs
- Intelligent anomaly detection
- Automated root cause analysis

### 🔄 Hot Reloading
- Update components without downtime
- WASM module replacement
- State preservation during updates
- Coordinated rollouts

### 🦀 Rust/WASM First
- High-performance native agents
- Browser integration via WASM
- Type-safe configuration
- Zero-copy event processing

## Architecture

ATHENA consists of multiple Rust crates:

- `athena-core` - Core types and protocols
- `athena-agent` - Server-side monitoring agent
- `athena-wasm` - Browser WASM library
- `athena-mcp` - Model Context Protocol server
- `athena-capture` - Screen capture service
- [See full architecture](docs/plan.md)

## Quick Start

```bash
# Install ATHENA CLI
cargo install athena-cli

# Initialize monitoring for your application
athena init

# Start the MCP server
athena mcp serve

# In your Rust application
use athena::prelude::*;

#[athena::trace]
fn my_function() {
    // Your code is automatically instrumented
}
```

## Browser Integration

```rust
// In your WASM application
use athena_wasm::prelude::*;

#[wasm_bindgen]
pub fn init() {
    athena::init(Config::default());
    
    // Automatic console capture
    // Network request monitoring  
    // Performance metrics
}
```

## MCP Integration

Connect ATHENA to your LLM for intelligent debugging:

```bash
# Configure your LLM to use ATHENA MCP server
athena mcp config --llm claude

# Query your distributed system
athena query "Show me all errors in the last hour across all services"
```

## Development Status

This project is in active development. See [docs/plan.md](docs/plan.md) for the implementation roadmap.

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

Copyright (c) 2011-2024 Michael A. Wright. All Rights Reserved.

Licensed under the Apache License, Version 2.0. See [LICENSE.txt](LICENSE.txt) for details.