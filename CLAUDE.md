# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CitrOS is an educational operating system written in Rust, inspired by MikanOS. It's a bare-metal UEFI application project currently in early development stages (v0.1.0).

**Key Features:**
- **Language**: Rust with `#![no_std]` and `#![no_main]` attributes for bare-metal programming
- **Target Platform**: x86_64 UEFI environment
- **Target**: x86_64-unknown-uefi platform for UEFI compatibility
- **Build Configuration**: Uses uefi crate for UEFI API access

**Current Implementation:**
- UEFI entry point (`efi_main`) with basic initialization
- Simple "Hello, World from UEFI!" output using UEFI text output protocol
- Custom panic handler for no_std environment
- Infinite loop placeholder for future OS kernel development
- Uses the `uefi` crate for UEFI API access

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

- `src/main.rs` - Main UEFI application entry point with basic "Hello World" implementation
- `Cargo.toml` - Rust project configuration (v0.1.0, uses uefi crate v0.35.0)
- `qemu_run.sh` - QEMU testing script for UEFI environment
- `mikanos-build/` - MikanOS reference build tools and resources
- `README.md` - Basic project description and setup instructions
- `.github/workflows/` - CI/CD workflows for Rust builds and security analysis

## Architecture Notes

CitrOS is a bare-metal UEFI application built with Rust's no_std environment. The current implementation is in its initial stages, providing a foundation for future OS development.

**Current Features:**
- Bare-metal Rust environment (`#![no_std]`, `#![no_main]`)
- UEFI entry point with basic console output
- Uses the `uefi` crate for UEFI API access and helper functions
- Simple panic handler for no_std environment

**Future Development Areas:**
- Kernel development fundamentals and boot process
- Hardware abstraction layers and device drivers
- Advanced memory management and paging
- Process and thread management
- File system and storage management

## Dependencies

CitrOS uses minimal dependencies for UEFI development:

- **uefi** (v0.35.0) - Provides UEFI API bindings and helper functions
- Target configured for `x86_64-unknown-uefi` platform
- No other external dependencies, keeping the codebase minimal for educational purposes

## UEFI Application Structure

CitrOS is a UEFI application that:

1. **Entry Point**: Uses `#[entry]` attribute for UEFI entry point
2. **No Standard Library**: Uses `#![no_std]` and `#![no_main]` attributes
3. **Console Output**: Uses UEFI Simple Text Output Protocol via `uefi` crate helpers
4. **Initialization**: Calls `uefi::helpers::init()` to set up UEFI environment
5. **Current Behavior**: Displays "Hello, World from UEFI!" and enters an infinite loop

### UEFI Boot Process

1. UEFI firmware loads the application from ESP (EFI System Partition)
2. Application initializes UEFI services with `uefi::helpers::init()`
3. Displays welcome message to console
4. Currently enters infinite loop (placeholder for future OS kernel)

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