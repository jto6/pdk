# CLAUDE.md - TI PDK Quick Reference

## /init - Quick Codebase Understanding

This is the **Texas Instruments Platform Development Kit (PDK)** - a comprehensive hardware abstraction layer for TI embedded processors.

### Essential Commands
```bash
# Build everything
make all

# Build specific target
make all LIMIT_SOCS=j721e LIMIT_BOARDS=j721e_evm LIMIT_CORES=mcu1_0

# Build only libraries
make all_libs

# Debug build
make all BUILD_PROFILE=debug

# Clean
make clean

# Get help
make help
```

### Key Directories
```
packages/ti/
├── drv/          # 40+ device drivers (UART, SPI, Ethernet, etc.)
├── board/        # Board support packages and hardware init
├── osal/         # OS abstraction layer (FreeRTOS/SafeRTOS/bare-metal)
├── kernel/       # RTOS integration (FreeRTOS, SafeRTOS)
├── boot/         # Secondary bootloader (SBL)
├── build/        # Build infrastructure and toolchain configs
├── transport/    # Network stacks (NDK, LwIP, TSN)
└── fs/           # File systems (FATFS)
```

### Architecture Overview
- **Target SoCs**: J721E, J7200, AM64x, AWR294x (automotive/industrial)
- **Processors**: ARM R5F, ARM A72, C66x DSP, C7x DSP, PRU-ICSS
- **RTOS**: FreeRTOS (primary), SafeRTOS (safety), bare-metal
- **Languages**: C (99%), Assembly, Makefiles

### Quick Navigation
- **Entry points**: `packages/makefile` (top-level), `ti/build/Rules.make` (config)
- **Driver examples**: Look in `ti/drv/*/test/` or `ti/drv/*/example/`
- **Board configs**: `ti/board/src/*/board_init.c`
- **Build rules**: `ti/build/makerules/`

### Common Driver Pattern
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
find ti/drv -name "*.h" | head -10

# Find examples for a driver
find ti/drv/uart -name "*example*" -o -name "*test*"

# Find build configs
find . -name "*component.mk" | head -5

# Find board initialization
find ti/board -name "board_init.c"

# Search for specific functionality
grep -r "UART_open" ti/drv/uart/
```

### Key Build Variables
- `LIMIT_SOCS`: Restrict to specific SoC (j721e, am64x, etc.)
- `LIMIT_BOARDS`: Restrict to specific board (j721e_evm, etc.)
- `LIMIT_CORES`: Restrict to specific core (mcu1_0, c66xdsp_1, etc.)
- `BUILD_PROFILE`: release|debug
- `BUILD_OS_TYPE`: freertos|baremetal|safertos

### Most Important Files
1. `packages/makefile` - Top-level build orchestration
2. `ti/build/Rules.make` - Core build configuration  
3. `ti/osal/osal.h` - OS abstraction APIs
4. `ti/board/board.h` - Board initialization APIs
5. `code_analysis.md` - Comprehensive codebase analysis

### Understanding the Build System
- **Component-based**: Each module has `*_component.mk` defining its interface
- **Multi-target**: Single codebase supports many SoCs/boards/cores
- **Hierarchical**: Top-level makefile delegates to `ti/build/makefile`
- **Profile-based**: Debug/release with different optimizations

### Safety & Automotive Features
- **Functional Safety**: SafeRTOS, Safety Diagnostic Reference (SDR)
- **Security**: Secure boot, crypto engines, secure communication
- **Real-time**: Deterministic I/O via PRU-ICSS
- **Multi-core**: Heterogeneous ARM+DSP coordination

### When You Need Help
- Check `code_analysis.md` for detailed architecture analysis
- Look for `*_test.c` or `*_example.c` files in driver directories
- Build system help: `make help`
- Driver documentation: Doxygen comments in header files

---
*Use this file to quickly orient yourself in the TI PDK codebase. For deeper analysis, see `code_analysis.md`.*