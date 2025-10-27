# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build System

This is a Texas Instruments Platform Development Kit (PDK) using GNU Make build system.

### Primary Build Commands

Navigate to `packages/ti/build/` directory for all build operations:

```bash
cd packages/ti/build
```

- **Build everything**: `gmake -s all` - Clean all and build all PDK drivers and examples
- **Build incrementally**: `gmake -s examples` - Build PDK drivers and all examples incrementally
- **Clean everything**: `gmake -s clean` - Clean all drivers and examples
- **Build specific example**: `gmake -s <examplename>` - Build PDK drivers and specific example only

### Build Configuration

Main configuration is in `packages/ti/build/Rules.make`:

- **BOARD**: Supported boards include j721e_evm, j7200_evm, j721s2_evm, j784s4_evm, j742s2_evm
- **BUILD_PROFILE**: debug (no optimizations) or release (full optimizations)
- **SOC**: Automatically determined from BOARD selection
- **CORE**: Automatically determined based on BOARD (e.g., mcu1_0 for J7 family)

### Advanced Build Options

- **Limit builds**: Use `LIMIT_SOCS`, `LIMIT_BOARDS`, `LIMIT_CORES` to restrict builds
- **Component inclusion**: Control via `PDK_*_INCLUDE` variables in Rules.make
- **Package selection**: Use `PACKAGE_SELECT` for VPS component builds

### Build Artifacts

- **Executables**: `$(DEST_ROOT)/<APP_NAME>/bin/$(BOARD)/<APP_NAME>_$(CORE)_$(BUILD_PROFILE).xe$(ISA)`
- **Libraries**: `$(DEST_ROOT)/<MODULE_RELPATH>/lib/$(BOARD)/$(ISA)/$(BUILD_PROFILE)/*.ae$(ISA)`
- **Objects**: `$(DEST_ROOT)/<MODULE_RELPATH>/obj/$(BOARD)/$(ISA)/$(BUILD_PROFILE)/*.oe$(ISA)`

## Architecture Overview

### Directory Structure

- **`packages/ti/build/`**: Main build system with makefiles and rules
- **`packages/ti/drv/`**: Device drivers (40+ drivers: EMAC, UART, SPI, GPIO, etc.)
- **`packages/ti/board/`**: Board-specific code and diagnostics
- **`packages/ti/boot/`**: Boot loaders (SBL - Secondary Boot Loader)
- **`packages/ti/diag/`**: Diagnostic and test utilities
- **`packages/ti/utils/`**: Utility libraries and profiling tools
- **`packages/ti/transport/`**: IPC and transport layer components (NDK, LwIP, TSN)
- **`packages/ti/osal/`**: OS abstraction layer (FreeRTOS/SafeRTOS/bare-metal)
- **`packages/ti/kernel/`**: RTOS integration (FreeRTOS, SafeRTOS)
- **`packages/ti/fs/`**: File systems (FATFS)

### Build Infrastructure

The codebase uses two build methodologies:
1. **Build Infrastructure**: Modern components using `ti/build/component.mk` with standardized targets
2. **Non-Build Infrastructure**: Legacy components with custom makefiles (mostly K1/K2 targets)

### Target Platforms

Primary focus on J7 family SoCs:
- J721E, J7200, J721S2, J784S4, J742S2
- Also supports: AM64x, AWR294x (automotive/industrial)
- Supports multiple cores: ARM Cortex-A72, ARM Cortex-R5F, C66x DSP, C7x DSP, PRU-ICSS
- RTOS support: FreeRTOS (primary), SafeRTOS (safety-certified), bare-metal

### Testing

Tests are scattered throughout driver directories in `test/` subdirectories. Many include unit tests and example applications. Test binaries follow naming convention `*UnitTest*` or `*Test*`.

### Key Components

- **EMAC**: Ethernet MAC driver with CPSW support
- **SBL**: Secondary Boot Loader for device initialization
- **Board Library**: Hardware abstraction for different EVMs
- **SCICLIENT**: System Controller Interface for power/clock management
- **IPC**: Inter-processor communication between cores
- **UDMA**: Unified DMA driver for data movement

### Key Build Variables

- **LIMIT_SOCS**: Restrict to specific SoC (j721e, am64x, etc.)
- **LIMIT_BOARDS**: Restrict to specific board (j721e_evm, etc.)
- **LIMIT_CORES**: Restrict to specific core (mcu1_0, c66xdsp_1, etc.)
- **BUILD_PROFILE**: release|debug
- **BUILD_OS_TYPE**: freertos|baremetal|safertos
- **PACKAGE_SELECT**: For VPS component builds

### Common Driver Pattern

Most PDK drivers follow a consistent API pattern:

```c
// 1. Include driver header
#include <ti/drv/uart/UART.h>

// 2. Initialize driver
UART_init();

// 3. Create/open instance
UART_Handle handle = UART_open(instance, &params);

// 4. Use driver APIs
UART_write(handle, buffer, size);

// 5. Close when done
UART_close(handle);
```

### Finding Things Fast

```bash
# Find driver APIs
find packages/ti/drv -name "*.h" | head -10

# Find examples for a driver
find packages/ti/drv/uart -name "*example*" -o -name "*test*"

# Find build configs
find packages/ti -name "*component.mk" | head -5

# Find board initialization
find packages/ti/board -name "board_init.c"

# Search for specific functionality
grep -r "UART_open" packages/ti/drv/uart/
```

### Safety & Automotive Features

- **Functional Safety**: SafeRTOS, Safety Diagnostic Reference (SDR)
- **Security**: Secure boot, crypto engines, secure communication
- **Real-time**: Deterministic I/O via PRU-ICSS
- **Multi-core**: Heterogeneous ARM+DSP coordination

### Important Files

1. `packages/makefile` - Top-level build orchestration
2. `packages/ti/build/Rules.make` - Core build configuration
3. `packages/ti/osal/osal.h` - OS abstraction APIs
4. `packages/ti/board/board.h` - Board initialization APIs

Always use the `-s` flag with gmake for user-friendly build output.