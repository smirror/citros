# =============================================================================
# CitrOS Makefile - Educational Operating System Build System
# =============================================================================
# This Makefile builds and runs CitrOS, a bare-metal UEFI application written
# in Rust. It handles cross-compilation for UEFI, disk image creation, and
# QEMU emulation setup.
#
# Requirements:
#   - Rust toolchain with x86_64-unknown-uefi target
#   - QEMU (qemu-system-x86_64)
#   - dosfstools (for mkfs.fat)
#   - OVMF UEFI firmware files
#   - sudo privileges (for loop device operations)
# =============================================================================

# =============================================================================
# Configuration Variables
# =============================================================================

# Project metadata
PROJECT_NAME := CitrOS
VERSION := 0.1.0

# Build configuration
TARGET := x86_64-unknown-uefi
CARGO_TARGET_DIR := target
BUILD_MODE := release
FEATURES := 

# File paths and directories
DISK_IMG := disk.img
DISK_SIZE := 200M
MOUNT_POINT := /mnt/citros
EFI_FILE := $(CARGO_TARGET_DIR)/$(TARGET)/$(BUILD_MODE)/citros.efi
OVMF_DIR := ./mikanos-build/devenv
OVMF_CODE := $(OVMF_DIR)/OVMF_CODE.fd
OVMF_VARS := $(OVMF_DIR)/OVMF_VARS.fd

# FAT32 filesystem parameters
FS_LABEL := CitrOS
FS_SECTOR_SIZE := 2
FS_FAT_COUNT := 2
FS_RESERVED_SECTORS := 32
FS_TYPE := 32

# QEMU configuration
QEMU_BINARY := qemu-system-x86_64
QEMU_MEMORY := 256M
QEMU_CPU := qemu64
QEMU_EXTRA_ARGS := -serial stdio -display gtk

# Development tools
CARGO := cargo
RUSTUP := rustup

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
PURPLE := \033[0;35m
CYAN := \033[0;36m
WHITE := \033[0;37m
RESET := \033[0m

# =============================================================================
# Phony Targets Declaration
# =============================================================================
.PHONY: all build build-debug run run-debug clean clean-all install-deps install-target
.PHONY: check check-all format format-check lint lint-fix test test-verbose
.PHONY: disk-create disk-mount disk-umount disk-clean
.PHONY: qemu-run qemu-debug qemu-monitor
.PHONY: deps-check ovmf-check system-check
.PHONY: info status help version

# =============================================================================
# Default Target
# =============================================================================
all: run

# =============================================================================
# Build Targets
# =============================================================================

# Install UEFI target if not present
install-target:
	@echo "$(CYAN)[SETUP]$(RESET) Installing Rust UEFI target..."
	@if ! $(RUSTUP) target list --installed | grep -q "$(TARGET)"; then \
		$(RUSTUP) target add $(TARGET); \
		echo "$(GREEN)[SUCCESS]$(RESET) UEFI target installed"; \
	else \
		echo "$(GREEN)[INFO]$(RESET) UEFI target already installed"; \
	fi

# Build the kernel (release mode)
build: install-target deps-check
	@echo "$(BLUE)[BUILD]$(RESET) Building $(PROJECT_NAME) kernel ($(BUILD_MODE))..."
	@echo "$(BLUE)[BUILD]$(RESET) Target: $(TARGET)"
	@echo "$(BLUE)[BUILD]$(RESET) Features: $(if $(FEATURES),$(FEATURES),none)"
	$(CARGO) build --target $(TARGET) --$(BUILD_MODE) $(if $(FEATURES),--features $(FEATURES))
	@echo "$(GREEN)[SUCCESS]$(RESET) Kernel build completed"
	@ls -la $(EFI_FILE)

# Build the kernel (debug mode)
build-debug: BUILD_MODE := debug
build-debug: EFI_FILE := $(CARGO_TARGET_DIR)/$(TARGET)/debug/citros.efi
build-debug: install-target deps-check
	@echo "$(BLUE)[BUILD]$(RESET) Building $(PROJECT_NAME) kernel (debug)..."
	@echo "$(BLUE)[BUILD]$(RESET) Target: $(TARGET)"
	$(CARGO) build --target $(TARGET) $(if $(FEATURES),--features $(FEATURES))
	@echo "$(GREEN)[SUCCESS]$(RESET) Debug kernel build completed"
	@ls -la $(EFI_FILE)

# =============================================================================
# Disk Image Management
# =============================================================================

# Create disk image
$(DISK_IMG): build ovmf-check
	@echo "$(PURPLE)[DISK]$(RESET) Creating disk image ($(DISK_SIZE))..."
	@echo "$(PURPLE)[DISK]$(RESET) Image: $(DISK_IMG)"
	qemu-img create -f raw $(DISK_IMG) $(DISK_SIZE)
	@echo "$(PURPLE)[DISK]$(RESET) Formatting as FAT32..."
	@echo "$(PURPLE)[DISK]$(RESET) Label: $(FS_LABEL), Sectors: $(FS_SECTOR_SIZE), FATs: $(FS_FAT_COUNT)"
	mkfs.fat -n '$(FS_LABEL)' -s $(FS_SECTOR_SIZE) -f $(FS_FAT_COUNT) -R $(FS_RESERVED_SECTORS) -F $(FS_TYPE) $(DISK_IMG)
	@echo "$(GREEN)[SUCCESS]$(RESET) Disk image created"

# Alternative disk creation target
disk-create: $(DISK_IMG)

# Mount disk and copy EFI file
setup-disk: $(DISK_IMG)
	@echo "$(PURPLE)[DISK]$(RESET) Setting up EFI system partition..."
	@echo "$(PURPLE)[DISK]$(RESET) Source EFI: $(EFI_FILE)"
	@echo "$(PURPLE)[DISK]$(RESET) Mount point: $(MOUNT_POINT)"
	
	@# Ensure clean state
	@if mountpoint -q $(MOUNT_POINT) 2>/dev/null; then \
		echo "$(YELLOW)[WARNING]$(RESET) $(MOUNT_POINT) already mounted, unmounting..."; \
		sudo umount $(MOUNT_POINT); \
	fi
	
	@# Setup loop device
	@echo "$(PURPLE)[DISK]$(RESET) Attaching loop device..."
	$(eval LOOP_DEV := $(shell sudo losetup -f --show $(DISK_IMG)))
	@if [ ! -b "$(LOOP_DEV)" ]; then \
		echo "$(RED)[ERROR]$(RESET) Failed to set up loop device"; \
		exit 1; \
	fi
	@echo "$(PURPLE)[DISK]$(RESET) Loop device: $(LOOP_DEV)"
	
	@# Mount and copy files
	sudo mkdir -p $(MOUNT_POINT)
	sudo mount $(LOOP_DEV) $(MOUNT_POINT)
	@echo "$(PURPLE)[DISK]$(RESET) Creating EFI directory structure..."
	sudo mkdir -p $(MOUNT_POINT)/EFI/BOOT
	@echo "$(PURPLE)[DISK]$(RESET) Copying EFI bootloader..."
	sudo cp $(EFI_FILE) $(MOUNT_POINT)/EFI/BOOT/BOOTX64.EFI
	@echo "$(PURPLE)[DISK]$(RESET) EFI file size: $$(stat -c%s $(EFI_FILE)) bytes"
	
	@# Cleanup
	@echo "$(PURPLE)[DISK]$(RESET) Unmounting and cleaning up..."
	sudo umount $(MOUNT_POINT)
	sudo losetup -d $(LOOP_DEV)
	@echo "$(GREEN)[SUCCESS]$(RESET) Disk setup complete"

# Clean disk operations
disk-clean:
	@echo "$(YELLOW)[CLEANUP]$(RESET) Cleaning disk operations..."
	@if mountpoint -q $(MOUNT_POINT) 2>/dev/null; then \
		echo "$(YELLOW)[CLEANUP]$(RESET) Unmounting $(MOUNT_POINT)..."; \
		sudo umount $(MOUNT_POINT); \
	fi
	@for loop in $$(losetup -a | grep $(DISK_IMG) | cut -d: -f1); do \
		echo "$(YELLOW)[CLEANUP]$(RESET) Detaching loop device $$loop..."; \
		sudo losetup -d $$loop; \
	done
	@if [ -d "$(MOUNT_POINT)" ]; then \
		sudo rmdir $(MOUNT_POINT) 2>/dev/null || true; \
	fi

# =============================================================================
# QEMU Execution Targets
# =============================================================================

# Run in QEMU (release mode)
run: setup-disk
	@echo "$(GREEN)[QEMU]$(RESET) Starting $(PROJECT_NAME) in QEMU..."
	@echo "$(GREEN)[QEMU]$(RESET) OVMF Code: $(OVMF_CODE)"
	@echo "$(GREEN)[QEMU]$(RESET) OVMF Vars: $(OVMF_VARS)"
	@echo "$(GREEN)[QEMU]$(RESET) Disk Image: $(DISK_IMG)"
	@echo "$(GREEN)[QEMU]$(RESET) Memory: $(QEMU_MEMORY)"
	@echo "$(GREEN)[QEMU]$(RESET) Press Ctrl+A, X to exit QEMU"
	@echo "$(GREEN)[QEMU]$(RESET) =========================================="
	$(QEMU_BINARY) \
		-m $(QEMU_MEMORY) \
		-cpu $(QEMU_CPU) \
		-drive if=pflash,format=raw,readonly=on,file=$(OVMF_CODE) \
		-drive if=pflash,format=raw,file=$(OVMF_VARS) \
		-drive format=raw,file=$(DISK_IMG) \
		$(QEMU_EXTRA_ARGS)

# Run in QEMU (debug mode)
run-debug: BUILD_MODE := debug
run-debug: EFI_FILE := $(CARGO_TARGET_DIR)/$(TARGET)/debug/citros.efi
run-debug: QEMU_EXTRA_ARGS += -s -S
run-debug: setup-disk
	@echo "$(GREEN)[QEMU]$(RESET) Starting $(PROJECT_NAME) in QEMU (debug mode)..."
	@echo "$(GREEN)[QEMU]$(RESET) GDB server enabled on port 1234"
	@echo "$(GREEN)[QEMU]$(RESET) Use 'target remote :1234' in GDB to connect"
	@echo "$(GREEN)[QEMU]$(RESET) =========================================="
	$(QEMU_BINARY) \
		-m $(QEMU_MEMORY) \
		-cpu $(QEMU_CPU) \
		-drive if=pflash,format=raw,readonly=on,file=$(OVMF_CODE) \
		-drive if=pflash,format=raw,file=$(OVMF_VARS) \
		-drive format=raw,file=$(DISK_IMG) \
		$(QEMU_EXTRA_ARGS)

# QEMU with monitor
qemu-monitor: QEMU_EXTRA_ARGS += -monitor stdio
qemu-monitor: run

# =============================================================================
# Development and Testing Targets
# =============================================================================

# Check code without building
check:
	@echo "$(BLUE)[CHECK]$(RESET) Checking code syntax and semantics..."
	$(CARGO) check --target $(TARGET) $(if $(FEATURES),--features $(FEATURES))

# Check all targets and features
check-all:
	@echo "$(BLUE)[CHECK]$(RESET) Checking all targets and features..."
	$(CARGO) check --workspace --all-targets --all-features

# Format code
format:
	@echo "$(BLUE)[FORMAT]$(RESET) Formatting code..."
	$(CARGO) fmt --all

# Check if code is formatted
format-check:
	@echo "$(BLUE)[FORMAT]$(RESET) Checking code formatting..."
	$(CARGO) fmt --all -- --check

# Run clippy linting
lint:
	@echo "$(BLUE)[LINT]$(RESET) Running clippy linter..."
	$(CARGO) clippy --target $(TARGET) --all-features -- -D warnings

# Run clippy with fixes
lint-fix:
	@echo "$(BLUE)[LINT]$(RESET) Running clippy with automatic fixes..."
	$(CARGO) clippy --target $(TARGET) --all-features --fix --allow-dirty -- -D warnings

# Run tests
test:
	@echo "$(BLUE)[TEST]$(RESET) Running tests..."
	$(CARGO) test

# Run tests with verbose output
test-verbose:
	@echo "$(BLUE)[TEST]$(RESET) Running tests (verbose)..."
	$(CARGO) test --verbose

# =============================================================================
# System and Dependency Checks
# =============================================================================

# Check system dependencies
deps-check:
	@echo "$(CYAN)[DEPS]$(RESET) Checking system dependencies..."
	@command -v $(CARGO) >/dev/null 2>&1 || { echo "$(RED)[ERROR]$(RESET) Rust/Cargo not found"; exit 1; }
	@command -v $(QEMU_BINARY) >/dev/null 2>&1 || { echo "$(RED)[ERROR]$(RESET) QEMU not found"; exit 1; }
	@command -v mkfs.fat >/dev/null 2>&1 || { echo "$(RED)[ERROR]$(RESET) mkfs.fat not found (install dosfstools)"; exit 1; }
	@command -v qemu-img >/dev/null 2>&1 || { echo "$(RED)[ERROR]$(RESET) qemu-img not found"; exit 1; }
	@echo "$(GREEN)[SUCCESS]$(RESET) All dependencies found"

# Check OVMF firmware files
ovmf-check:
	@echo "$(CYAN)[OVMF]$(RESET) Checking OVMF firmware files..."
	@if [ ! -f "$(OVMF_CODE)" ]; then \
		echo "$(RED)[ERROR]$(RESET) OVMF_CODE.fd not found at $(OVMF_CODE)"; \
		echo "$(YELLOW)[INFO]$(RESET) Install OVMF package or update OVMF_DIR path"; \
		exit 1; \
	fi
	@if [ ! -f "$(OVMF_VARS)" ]; then \
		echo "$(RED)[ERROR]$(RESET) OVMF_VARS.fd not found at $(OVMF_VARS)"; \
		echo "$(YELLOW)[INFO]$(RESET) Install OVMF package or update OVMF_DIR path"; \
		exit 1; \
	fi
	@echo "$(GREEN)[SUCCESS]$(RESET) OVMF firmware files found"

# Install system dependencies (Ubuntu/Debian)
install-deps:
	@echo "$(CYAN)[INSTALL]$(RESET) Installing system dependencies..."
	@if command -v apt >/dev/null 2>&1; then \
		echo "$(CYAN)[INSTALL]$(RESET) Using apt package manager..."; \
		sudo apt update; \
		sudo apt install -y qemu-system-x86 dosfstools ovmf; \
	elif command -v yum >/dev/null 2>&1; then \
		echo "$(CYAN)[INSTALL]$(RESET) Using yum package manager..."; \
		sudo yum install -y qemu-system-x86 dosfstools edk2-ovmf; \
	else \
		echo "$(YELLOW)[WARNING]$(RESET) Unknown package manager, install manually:"; \
		echo "  - qemu-system-x86"; \
		echo "  - dosfstools"; \
		echo "  - ovmf/edk2-ovmf"; \
	fi

# =============================================================================
# Cleanup Targets
# =============================================================================

# Clean build artifacts
clean:
	@echo "$(YELLOW)[CLEANUP]$(RESET) Cleaning build artifacts..."
	$(CARGO) clean
	@echo "$(GREEN)[SUCCESS]$(RESET) Build artifacts cleaned"

# Clean everything including disk image
clean-all: clean disk-clean
	@echo "$(YELLOW)[CLEANUP]$(RESET) Removing disk image..."
	@rm -f $(DISK_IMG)
	@echo "$(GREEN)[SUCCESS]$(RESET) Complete cleanup finished"

# =============================================================================
# Information and Help Targets
# =============================================================================

# Display project information
info:
	@echo "$(CYAN)$(PROJECT_NAME) Build Information$(RESET)"
	@echo "=================================="
	@echo "Project:      $(PROJECT_NAME) v$(VERSION)"
	@echo "Target:       $(TARGET)"
	@echo "Build Mode:   $(BUILD_MODE)"
	@echo "EFI File:     $(EFI_FILE)"
	@echo "Disk Image:   $(DISK_IMG) ($(DISK_SIZE))"
	@echo "OVMF Path:    $(OVMF_DIR)"
	@echo "Mount Point:  $(MOUNT_POINT)"
	@echo "QEMU Binary:  $(QEMU_BINARY)"
	@echo "QEMU Memory:  $(QEMU_MEMORY)"

# Display current status
status: info
	@echo ""
	@echo "$(CYAN)Current Status$(RESET)"
	@echo "=============="
	@if [ -f "$(EFI_FILE)" ]; then \
		echo "EFI File:     $(GREEN)✓ Built$(RESET) ($$(stat -c%s $(EFI_FILE)) bytes)"; \
	else \
		echo "EFI File:     $(RED)✗ Not built$(RESET)"; \
	fi
	@if [ -f "$(DISK_IMG)" ]; then \
		echo "Disk Image:   $(GREEN)✓ Created$(RESET) ($$(stat -c%s $(DISK_IMG)) bytes)"; \
	else \
		echo "Disk Image:   $(RED)✗ Not created$(RESET)"; \
	fi
	@if [ -f "$(OVMF_CODE)" ]; then \
		echo "OVMF Code:    $(GREEN)✓ Available$(RESET)"; \
	else \
		echo "OVMF Code:    $(RED)✗ Missing$(RESET)"; \
	fi
	@if [ -f "$(OVMF_VARS)" ]; then \
		echo "OVMF Vars:    $(GREEN)✓ Available$(RESET)"; \
	else \
		echo "OVMF Vars:    $(RED)✗ Missing$(RESET)"; \
	fi

# Display version information
version:
	@echo "$(CYAN)Version Information$(RESET)"
	@echo "==================="
	@echo "$(PROJECT_NAME):    v$(VERSION)"
	@rustc --version 2>/dev/null || echo "Rust:         Not installed"
	@cargo --version 2>/dev/null || echo "Cargo:        Not installed"
	@$(QEMU_BINARY) --version 2>/dev/null | head -1 || echo "QEMU:         Not installed"

# Display help information
help:
	@echo "$(CYAN)$(PROJECT_NAME) Makefile - Help$(RESET)"
	@echo "=============================="
	@echo ""
	@echo "$(YELLOW)Build Targets:$(RESET)"
	@echo "  all            - Build and run (default target)"
	@echo "  build          - Build kernel in release mode"
	@echo "  build-debug    - Build kernel in debug mode"
	@echo "  install-target - Install Rust UEFI target"
	@echo ""
	@echo "$(YELLOW)Execution Targets:$(RESET)"
	@echo "  run            - Build, setup disk, and run in QEMU"
	@echo "  run-debug      - Run with GDB debugging support"
	@echo "  qemu-monitor   - Run with QEMU monitor console"
	@echo ""
	@echo "$(YELLOW)Disk Management:$(RESET)"
	@echo "  disk-create    - Create disk image only"
	@echo "  setup-disk     - Create and setup EFI system partition"
	@echo "  disk-clean     - Clean disk operations (unmount, detach)"
	@echo ""
	@echo "$(YELLOW)Development:$(RESET)"
	@echo "  check          - Check code without building"
	@echo "  check-all      - Check all targets and features"
	@echo "  format         - Format code"
	@echo "  format-check   - Check code formatting"
	@echo "  lint           - Run clippy linting"
	@echo "  lint-fix       - Run clippy with automatic fixes"
	@echo "  test           - Run tests"
	@echo "  test-verbose   - Run tests with verbose output"
	@echo ""
	@echo "$(YELLOW)System:$(RESET)"
	@echo "  deps-check     - Check system dependencies"
	@echo "  ovmf-check     - Check OVMF firmware files"
	@echo "  install-deps   - Install system dependencies"
	@echo ""
	@echo "$(YELLOW)Cleanup:$(RESET)"
	@echo "  clean          - Clean build artifacts"
	@echo "  clean-all      - Clean everything including disk image"
	@echo ""
	@echo "$(YELLOW)Information:$(RESET)"
	@echo "  info           - Display project configuration"
	@echo "  status         - Display current build status"
	@echo "  version        - Display version information"
	@echo "  help           - Show this help message"
	@echo ""
	@echo "$(YELLOW)Examples:$(RESET)"
	@echo "  make                    # Build and run"
	@echo "  make build             # Just build"
	@echo "  make run-debug         # Run with debugging"
	@echo "  make clean-all         # Complete cleanup"
	@echo ""
	@echo "$(YELLOW)Environment Variables:$(RESET)"
	@echo "  FEATURES       - Cargo features to enable"
	@echo "  QEMU_EXTRA_ARGS - Additional QEMU arguments"
	@echo "  OVMF_DIR       - Path to OVMF firmware directory"