# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CitrOS is an educational operating system written in Rust, influenced by MikanOS. This is a minimal OS development project currently in early stages.

## Development Commands

### Building and Running

#### Standard Build
```bash
# Build the project
cargo build

# Build in release mode
cargo build --release

# Check code without building
cargo check
```

#### UEFI Build
```bash
# Install UEFI target
rustup target add x86_64-unknown-uefi

# Build for UEFI
cargo build --target x86_64-unknown-uefi --release

# Build and create ESP using the build script
./build.sh

# Run in QEMU (requires OVMF UEFI firmware)
qemu-system-x86_64 -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.fd -drive if=pflash,format=raw,file=/tmp/OVMF_VARS.fd -drive format=raw,file=fat:rw:esp
```

### Testing and Linting
```bash
# Run tests
cargo test

# Run tests with verbose output
cargo test --verbose

# Format code
cargo fmt

# Format all code in workspace
cargo fmt --all

# Run clippy for linting
cargo clippy

# Run clippy with all features
cargo clippy --all-features

# Check formatting without making changes
cargo fmt -- --check
```

## Project Structure

- `src/main.rs` - Main entry point with basic "Hello, world!" implementation
- `Cargo.toml` - Standard Rust project configuration with no external dependencies yet
- The project follows standard Rust project structure

## Architecture Notes

This is currently a minimal Rust project in the initial stages of OS development. The codebase structure will evolve as the operating system features are implemented. As an educational OS project inspired by MikanOS, expect future development to focus on:

- Kernel development fundamentals
- Low-level system programming
- Hardware abstraction layers
- Memory management
- Process management

## Dependencies

- `uefi` (0.26): Core UEFI API bindings for Rust
- `uefi-services` (0.20): Higher-level UEFI services and utilities

## UEFI Application Structure

CitrOS is now a UEFI application that:

1. **Entry Point**: Uses `#[entry]` attribute for UEFI entry point
2. **No Standard Library**: Uses `#![no_std]` and `#![no_main]` attributes
3. **Console Output**: Uses UEFI Simple Text Output Protocol
4. **Input Handling**: Waits for keyboard input using Simple Text Input Protocol
5. **Memory Management**: Uses UEFI Boot Services

### UEFI Boot Process

1. UEFI firmware loads the application from ESP (EFI System Partition)
2. Application initializes UEFI services
3. Displays welcome messages and waits for user input
4. Cleanly exits returning to UEFI shell

## CI/CD

The project uses GitHub Actions for continuous integration:

- **rust.yml**: Runs on push/PR to main branch when Rust files change
  - Auto-formats code with `cargo fmt --all`
  - Runs clippy linting
  - Executes tests with `cargo test --verbose`
  
- **rust-clippy.yml**: Security-focused clippy analysis
  - Runs on schedule and for main branch changes
  - Generates SARIF reports for GitHub Security tab
  - Uses `cargo clippy --all-features`

## Code Style

The project enforces consistent formatting through EditorConfig:
- 4-space indentation for most files
- LF line endings
- UTF-8 encoding
- Trailing whitespace trimming
- Final newline insertion