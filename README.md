# CitrOS

CitrOS is an educational operating system written in Rust, inspired by [MikanOS](https://github.com/uchan-nos/mikanos). It's designed as a learning project for understanding bare-metal programming and UEFI application development.

## Features

- **Bare-metal Rust**: Uses `#![no_std]` and `#![no_main]` for system-level programming  
- **UEFI Application**: Runs as a UEFI application on x86_64 systems
- **Minimal Dependencies**: Only uses the `uefi` crate for UEFI API access
- **Educational Focus**: Simple, readable code for learning OS development concepts

## Current Status

CitrOS is in early development (v0.1.0). The current implementation:

- Initializes UEFI services
- Displays "Hello, World from UEFI!" to console
- Provides a foundation for future OS kernel development

## Prerequisites

- Rust toolchain (2024 edition)
- UEFI target support: `rustup target add x86_64-unknown-uefi`
- QEMU with OVMF firmware for testing (optional)

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/smirror/citros.git
cd citros
```

### 2. Build the Project

```bash
# Add UEFI target if not already installed
rustup target add x86_64-unknown-uefi

# Build for UEFI
cargo build --target x86_64-unknown-uefi --release
```

### 3. Run in QEMU (Optional)

If you have QEMU and OVMF firmware installed:

```bash
# Run the QEMU test script
./qemu_run.sh
```

## Development

### Building

```bash
# Standard build
cargo build

# UEFI target build
cargo build --target x86_64-unknown-uefi --release

# Check code without building
cargo check
```

### Code Quality

```bash
# Format code
cargo fmt

# Run linter
cargo clippy

# Run tests
cargo test
```

## Project Structure

```
citros/
├── src/
│   └── main.rs          # Main UEFI application entry point
├── Cargo.toml           # Project configuration
├── README.md            # This file
├── CLAUDE.md            # AI assistant guidance
├── qemu_run.sh          # QEMU testing script
└── .github/workflows/   # CI/CD workflows
```

## Architecture

CitrOS is structured as a UEFI application that:

1. Uses the `#[entry]` attribute for the UEFI entry point
2. Initializes UEFI services with `uefi::helpers::init()`
3. Outputs text using UEFI Simple Text Output Protocol
4. Currently runs in an infinite loop (placeholder for future kernel)

## Dependencies

- **uefi** (v0.35.0) - Provides UEFI API bindings and helper functions

## Future Development

Planned features and improvements:

- Memory management and paging
- Hardware abstraction layers
- Device drivers
- Process and thread management
- File system support
- Graphics and user interface

## Contributing

This is an educational project. Contributions, suggestions, and learning discussions are welcome!

## License

See [LICENSE](LICENSE) for details.

## Inspiration

This project is inspired by:
- [MikanOS](https://github.com/uchan-nos/mikanos) - Educational OS development
- Various Rust bare-metal programming resources
- UEFI specification and development guides