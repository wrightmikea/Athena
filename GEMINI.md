# Gemini-CLI Interaction Guide for ATHENA

This document provides a guide for using Gemini-CLI to interact with the ATHENA project.

## Project Overview

ATHENA is a distributed debugging and monitoring system that provides comprehensive observability across distributed applications with LLM integration via Model Context Protocol.

### Key Features:

*   **Unified Timeline**: Synchronized logs, metrics, and events from all components.
*   **Screen Capture**: Visual debugging with automated screen capture.
*   **Browser Integration**: JavaScript console logs and WASM application monitoring.
*   **Hot Reloading**: Dynamic component updates without system restart.
*   **LLM Integration**: Model Context Protocol server for AI-assisted debugging.

## Development Workflow

The project follows a feature-branch workflow. When working on a new feature or bug fix, please create a new branch from the `dev` branch.

### Getting Started

1.  **Install Dependencies**: The project is built with Rust. Make sure you have the latest version of Rust and Cargo installed.
2.  **Build the Project**: Use the provided build script to build the entire project.

    ```bash
    ./scripts/build.sh
    ```
3.  **Run Tests**: Use the provided test script to run all tests.

    ```bash
    ./scripts/test.sh
    ```

### Common Tasks

*   **Adding a new feature**:
    1.  Create a new feature branch from `dev`.
    2.  Implement the feature.
    3.  Add unit and integration tests.
    4.  Update the documentation.
    5.  Create a pull request to merge the feature branch into `dev`.
*   **Fixing a bug**:
    1.  Create a new bugfix branch from `dev`.
    2.  Implement the bug fix.
    3.  Add tests to prevent regressions.
    4.  Create a pull request to merge the bugfix branch into `dev`.

## Interacting with the Codebase

When I'm asked to work with the codebase, I will adhere to the following principles:

*   **Understand the context**: Before making any changes, I will analyze the surrounding code, tests, and documentation to understand the existing patterns and conventions.
*   **Follow existing style**: I will mimic the style and structure of the existing code to ensure consistency.
*   **Write tests**: I will write tests for any new code I add to ensure correctness and prevent regressions.
*   **Update documentation**: I will update the documentation to reflect any changes I make to the codebase.