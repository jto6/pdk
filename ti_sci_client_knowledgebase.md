# Texas Instruments System Control Interface (TI SCI) Client - Comprehensive Knowledgebase

**Version:** 11.01.03 (TISCI)
**Last Updated:** January 2025
**Location:** `packages/ti/drv/sciclient/`

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Introduction and High-Level Overview](#introduction-and-high-level-overview)
3. [DMSC Architecture and System Control](#dmsc-architecture-and-system-control)
4. [TI SCI Protocol Specification](#ti-sci-protocol-specification)
5. [SCICLIENT Architecture and Design](#sciclient-architecture-and-design)
6. [Secure Proxy Communication Mechanism](#secure-proxy-communication-mechanism)
7. [Ring Accelerator Integration](#ring-accelerator-integration)
8. [Message Categories and APIs](#message-categories-and-apis)
9. [Implementation Deep Dive](#implementation-deep-dive)
10. [Usage Examples and Patterns](#usage-examples-and-patterns)
11. [Design Decisions and Rationale](#design-decisions-and-rationale)
12. [Troubleshooting and FAQ](#troubleshooting-and-faq)

---

## Executive Summary

The **TI System Control Interface (TISCI)** is a standardized protocol for communication between processing entities and the **Device Management and Security Controller (DMSC)** on Texas Instruments K3 architecture System-on-Chips (SoCs). The **SCICLIENT** driver provides a high-level abstraction layer that enables RTOS and bare-metal applications to communicate with DMSC for system services including:

- **Power Management (PM)**: Device power states, clock control, voltage management
- **Resource Management (RM)**: Allocation of DMA channels, interrupts, ring accelerators
- **Security Services**: Firewalls, secure boot, key management
- **Processor Boot Control**: Loading and booting secondary cores

**Key Benefits:**
- Centralized system control eliminates complex OS-to-OS interactions
- Consistent power/resource management across heterogeneous cores
- Security isolation via DMSC firmware running in secure domain
- Protocol-based interface allows future DMSC firmware updates without client code changes

**Target SoCs:** J721E, J7200, J721S2, J784S4, J742S2, AM65xx, AM64x

---

## Introduction and High-Level Overview

### What is TI SCI?

Traditional Texas Instruments SoCs implemented system control functions (power management, clock control) within each operating system running on different cores. This approach created significant challenges:

- **Complex inter-OS interactions** for basic system functions
- **Lack of centralized system state knowledge**
- **Inconsistent workarounds** for SoC errata across different cores
- **Difficult power management coordination** in heterogeneous systems

TI SCI solves these problems by defining a **request-response messaging protocol** between application processors (ARM/DSP cores) and a dedicated **System Control Entity** (DMSC).

### What is DMSC?

**Device Management and Security Controller (DMSC)** is a dedicated microcontroller in K3 SoCs that:

1. **Runs System Firmware (SYSFW)** - Provides centralized control services
2. **Manages Power** - Controls clocks, power domains, device states
3. **Manages Resources** - Allocates DMA channels, interrupts, ring accelerators
4. **Enforces Security** - Firewall configuration, secure boot, cryptographic services
5. **Boots the System** - Initializes hardware and releases cores from reset

**DMSC is a "black box"** to other processing entities. Communication occurs exclusively via the TI SCI protocol over hardware message channels.

### What is SCICLIENT?

**SCICLIENT** is the software driver that implements the TI SCI protocol on the client side (application processors). It:

- **Abstracts the communication mechanism** (Secure Proxy or Ring Accelerator)
- **Provides high-level APIs** for PM, RM, and Security services
- **Manages message construction** with proper headers and sequence IDs
- **Handles synchronization** via polling or interrupts
- **Works with RTOS or bare-metal** applications via OSAL abstraction

```
┌─────────────────────────────────────────────────────────┐
│          Application (Higher Level Software)             │
├─────────────────────────────────────────────────────────┤
│        PM Library  │  RM Library  │  Security Library   │
├─────────────────────────────────────────────────────────┤
│                    SCICLIENT API Layer                   │
│  - Sciclient_pmSetModuleState()                         │
│  - Sciclient_rmIrqSet()                                 │
│  - Sciclient_firewallSetRegion()                        │
├─────────────────────────────────────────────────────────┤
│              Sciclient_service() Core API                │
│  (Message construction, TX/RX, timeout handling)        │
├─────────────────────────────────────────────────────────┤
│          Secure Proxy / Ring Accelerator CSL            │
│  (Hardware abstraction for message channels)            │
├─────────────────────────────────────────────────────────┤
│                   Hardware Channels                      │
│  (Secure Proxy Threads / Ring Accelerator Rings)        │
└─────────────────────────────────────────────────────────┘
           ▼  TI SCI Messages  ▼
┌─────────────────────────────────────────────────────────┐
│      DMSC Running System Firmware (SYSFW)               │
│  - Power Management                                      │
│  - Resource Management                                   │
│  - Security Management                                   │
└─────────────────────────────────────────────────────────┘
```

---

## DMSC Architecture and System Control

### DMSC Components

The DMSC firmware (also called SYSFW or TIFS in newer SoCs) provides three major subsystems:

#### 1. Power Management (PM)

**Responsibilities:**
- Control device power states (ON, OFF, RETENTION)
- Configure and gate module clocks
- Set clock frequencies and parents
- Manage voltage rails
- Handle low-power modes (DeepSleep) and wakeup events

**Key Concepts:**
- **Devices**: Hardware modules identified by unique IDs (e.g., `TISCI_DEV_UART0`)
- **Clocks**: Per-device clock inputs identified by clock IDs
- **States**: `MSG_DEVICE_SW_STATE_ON`, `MSG_DEVICE_SW_STATE_AUTO_OFF`, etc.

**Example:**
```c
// Request UART0 to be powered on
Sciclient_pmSetModuleState(
    TISCI_DEV_UART0,               // Module ID
    TISCI_MSG_VALUE_DEVICE_SW_STATE_ON,  // Power state
    TISCI_MSG_FLAG_AOP,            // Allow open power domain
    SCICLIENT_SERVICE_WAIT_FOREVER // Timeout
);
```

#### 2. Resource Management (RM)

**Responsibilities:**
- Allocate and free DMA channels (UDMAP)
- Manage interrupt routing (IRQ crossbar)
- Configure Ring Accelerator resources
- Manage PSI-L (Packet Streaming Interface Layer) routing
- Control non-secure proxy threads

**Key Concepts:**
- **Resources**: DMA channels, rings, IRQs are limited shared resources
- **Allocation**: DMSC tracks ownership and prevents conflicts
- **Host-based**: Each core (host) has assigned resource ranges

**Example:**
```c
// Allocate a UDMA TX channel
struct tisci_msg_rm_udmap_tx_ch_cfg_req req;
req.hdr.type = TISCI_MSG_RM_UDMAP_TX_CH_CFG;
req.nav_id = TISCI_DEV_NAVSS0_UDMAP_0;
req.index = 10;  // Channel number
req.tx_chan_type = TISCI_MSG_VALUE_RM_UDMAP_CH_TYPE_PKT_PBRR;

Sciclient_service(&reqPrm, &respPrm);
```

#### 3. Security Management

**Responsibilities:**
- Configure firewalls (memory protection regions)
- Manage SA2UL (Security Accelerator) contexts
- Control secure boot and authentication
- Manage cryptographic keys
- Provide RNG and PKA services
- Control secure JTAG access

**Key Concepts:**
- **Firewalls**: Protect memory regions from unauthorized access
- **Secure/Non-Secure Contexts**: Different privilege levels
- **Key Management**: DKEK (Derived Key Encryption Key), keystore

### System Boot Flow with DMSC

#### Architecture Variations

The K3 architecture has evolved with two major variants for executing RM/PM services:

**Older Devices (AM65x, AM64x):**
- DMSC (Cortex-M3) runs both TIFS (security) and RM/PM services
- Applications use SCICLIENT library to communicate directly with DMSC

**Newer Devices (J721E, J7200, J721S2, J784S4, J742S2):**
- DMSC (Cortex-M3) runs only TIFS (security services)
- **SCISERVER** runs on MCU R5F and provides RM/PM services
- TIFS on DMSC acts as a forwarding agent between hosts and SCISERVER
- This frees a main domain R5F for customer use and enables HSM functionality

#### Boot Flow (Newer J7 Devices with SCISERVER)

```
Power-On Reset
  ↓
[DMSC - Cortex-M3] DMSC ROM Starts (hardware brings DMSC out of reset)
  ↓ Sets up secure proxy threads for communication with R5F
  ↓ Waits for firmware load message from R5F
  ↓
[MCU R5F] ROM Bootloader Starts (in SoC ROM)
  ↓ Loads DMSC firmware binary to memory
  ↓ **Authenticates** DMSC firmware using X509 certificate (HS devices)
  ↓   - Verifies public key hash against eFuse OTP (SMPKH/BMPKH)
  ↓   - Verifies RSA-4096 signature
  ↓ Sends SCICLIENT_ROM_MSG_R5_TO_M3_M3FW to DMSC ROM
  ↓   - Includes firmware buffer address
  ↓
[DMSC ROM] Receives firmware load message
  ↓ Authenticates firmware certificate
  ↓ Loads firmware to DMSC execution memory
  ↓ Sends ACK (CERT_AUTH_PASS) back to R5F ROM
  ↓ Transfers control to DMSC firmware
  ↓
[DMSC - Cortex-M3] DMSC Firmware (TIFS) Starts
  ↓ Initializes security subsystem (firewalls, crypto accelerators)
  ↓ Sends TISCI_MSG_BOOT_NOTIFICATION to R5F ROM
  ↓
[MCU R5F] ROM Receives BOOT_NOTIFICATION
  ↓ Knows DMSC firmware is ready
  ↓ Loads SBL (Secondary Boot Loader) to MCU SRAM
  ↓ **Authenticates** SBL using X509 certificate (HS devices)
  ↓ ROM transfers control to SBL
  ↓
[MCU R5F] SBL Executes
  ↓
[MCU R5F] Sciclient_init()
  ↓ Initialize secure proxy threads for DMSC communication
  ↓ Register interrupts
  ↓
[MCU R5F] Sciserver_init() **← SCISERVER STARTS HERE**
  ↓ Initialize secure proxy threads for other core communication
  ↓ Start SCISERVER tasks to handle RM/PM requests from other cores
  ↓
[MCU R5F] Sciclient_boardCfg()
  ↓ Send board configuration to DMSC via secure proxy
  ↓ (Security policies, firewall configs)
  ↓ DMSC forwards RM/PM portions to SCISERVER on MCU R5F
  ↓
[DMSC] DMSC Processes Security Board Config
  ↓ Applies security configuration
  ↓
[MCU R5F - SCISERVER] Processes RM/PM Board Config
  ↓ Applies clock settings, resource assignments
  ↓ Returns ACK via DMSC to MCU R5F
  ↓
[MCU R5F] SBL Loads Application Images
  ↓ Uses Sciclient APIs for power/resource management
  ↓
[MCU R5F] Sciclient_pmSetModuleState() - Power on modules
  ↓ Sends TISCI message to DMSC
  ↓ DMSC forwards to SCISERVER on MCU R5F
  ↓ SCISERVER processes and responds
  ↓
[MCU R5F] Sciclient_procBootRequestProcessor() - Release cores from reset
  ↓
[A72/R5F/DSP/etc.] Application Cores Start Executing
  ↓ Each core uses Sciclient library
  ↓ TISCI messages → DMSC → SCISERVER (on MCU R5F) → DMSC → Requesting core
```

**Key Points:**

**Boot Sequence:**
- **DMSC ROM** starts first (brought out of reset by hardware at POR)
- **DMSC ROM** sets up secure proxy communication and waits for R5F
- **MCU R5F ROM** starts and loads DMSC firmware to memory
- **R5F ROM → DMSC ROM**: Sends firmware load message with buffer address
- **DMSC ROM**: Authenticates, loads firmware, sends ACK to R5F
- **DMSC firmware**: Starts, initializes, sends BOOT_NOTIFICATION to R5F
- **R5F ROM**: Receives notification, then loads and runs SBL

**Authentication:**
- Both **DMSC ROM** (on behalf of R5F) and **R5F ROM** authenticate binaries on HS devices
- Public key hash verified against eFuse OTP (SMPKH/BMPKH on HS-SE, TI MPK on HS-FS)
- RSA-4096 signature verification ensures binary integrity
- Prevents loading tampered DMSC firmware or SBL

**Architecture:**
- **DMSC** has its own Cortex-M3 processor running TIFS (security services only)
- **SCISERVER** runs on **MCU R5F** in J7 devices (provides RM/PM services)
  - DMSC TIFS acts as a secure forwarding agent for RM/PM messages
  - Frees up a main domain R5F for customer applications
- **MCU R5F** has three roles:
  1. Boot master (runs ROM and SBL)
  2. SCISERVER host (runs RM/PM services)
  3. First SCICLIENT user
- **Other cores** (A72, additional R5F, DSP) communicate via:
  - SCICLIENT → DMSC (TIFS) → SCISERVER (MCU R5F) → DMSC → requesting core

#### ROM Authentication (HS Devices)

On High Security (HS) devices, the ROM bootloader performs authentication of all loaded binaries to prevent execution of tampered code. This establishes the **root of trust** for the entire system.

**Authentication Process:**

1. **Binary Format**: All authenticated binaries use X509 certificate format
   ```
   ┌────────────────────────────────┐
   │  X509 Certificate              │
   │  - Public Key                  │
   │  - RSA-4K Digital Signature    │
   │  - Extensions (metadata)       │
   │    - Image Integrity (SHA-512) │
   │    - Load Address              │
   │    - Software Revision         │
   │    - (Optional) Encryption     │
   │    - (Optional) Boot Config    │
   └────────────────────────────────┘
   ┌────────────────────────────────┐
   │  Binary Payload                │
   │  (DMSC firmware, SBL, etc.)    │
   └────────────────────────────────┘
   ```

2. **ROM Verification Steps** (for DMSC firmware and SBL):
   ```
   Step 1: Public Key Verification
     ↓ Calculate SHA-512 hash of public key in certificate
     ↓ Compare against active MPK hash in eFuse OTP (SMPKH/BMPKH/TI MPK)
     ↓ If mismatch → Authentication FAILS

   Step 2: Signature Verification
     ↓ Verify RSA-4K signature using public key
     ↓ Ensures certificate was signed by private key holder
     ↓ If invalid → Authentication FAILS

   Step 3: Image Integrity
     ↓ Load binary to memory at address specified in Load Extension
     ↓ Calculate SHA-512 hash of binary payload
     ↓ Compare against hash in Image Integrity Extension
     ↓ If mismatch → Authentication FAILS

   Step 4: (Optional) Decryption Verification
     ↓ If binary is encrypted (AES-256-CBC)
     ↓ Decrypt and verify magic number
     ↓ If invalid → Authentication FAILS

   All checks pass → Binary is authentic and can execute
   ```

3. **eFuse OTP (One-Time Programmable) Storage**:

   The device has multiple eFuse OTPs for different keys:

   **TI MPK (Master Public Key) Hash**:
   - Pre-programmed by TI at factory
   - Used on HS-FS (Field Securable) devices
   - TI's root of trust before customer provisioning

   **SMPKH (Secondary Master Public Key Hash)**:
   - Customer's primary root key hash
   - Programmed by OEM during HS-FS → HS-SE conversion
   - SHA-512 hash of customer's RSA-4096 public key
   - Once programmed, becomes the "active MPK"

   **BMPKH (Backup Master Public Key Hash)**:
   - Customer's backup root key hash (optional)
   - Allows key rotation if primary key is compromised
   - Also SHA-512 hash of RSA-4096 public key
   - Can be selected as "active MPK" via MPK options

   **Active MPK Selection**:
   - **HS-FS devices**: ROM uses TI MPK hash
   - **HS-SE devices**: ROM uses SMPKH (or BMPKH if selected)
   - MPK options bits in eFuse control which key is active

   **Key Properties**:
   - Each is a SHA-512 hash (512 bits / 64 bytes) of the public key in DER format
   - Protected by BCH error correction code
   - Cannot be modified after programming (one-time programmable)
   - ROM compares certificate's public key hash against the active MPK hash

4. **Chain of Trust**:
   ```
   [eFuse OTP - SMPKH/BMPKH (customer) or TI MPK (factory)]
         ↓ ROM verifies DMSC firmware certificate
   [DMSC Firmware X509 Certificate + Binary]
         ↓ DMSC firmware runs on DMSC Cortex-M3
   [DMSC TIFS - Provides Authentication Services]
         ↓ ROM loads and verifies SBL certificate
   [SBL X509 Certificate + Binary]
         ↓ SBL runs on MCU R5F
   [SBL authenticates applications via TISCI_MSG_PROC_AUTH_BOOT]
         ↓ Sends to DMSC TIFS for verification
   [Application Images X509 Certificates + Binaries]
         ↓ Applications run on respective cores (A72, DSP, etc.)
   ```

5. **TISCI_MSG_PROC_AUTH_BOOT**:
   - Once DMSC is running, it provides authentication services to SBL and other cores
   - Same X509 certificate format and verification steps
   - SBL uses this to authenticate application binaries before booting cores

**GP (General Purpose) vs HS (High Security) Devices:**
- **GP Devices**: No authentication, binaries load and execute without signature checks
- **HS-FS Devices**: Field-Securable - authentication can be enabled by programming eFuses
- **HS-SE Devices**: Security Enforced - authentication permanently enabled, encrypted boot required

**Why This Prevents Tampering:**
- Attacker cannot modify DMSC firmware without:
  1. Private key corresponding to the public key whose SHA-512 hash is in SMPKH/BMPKH eFuse
  2. Only OEM has this private key (public key hash was programmed during provisioning)
  3. Ability to generate valid RSA-4096 signature that verifies with that public key
- Even if attacker modifies ROM code, they cannot change eFuse OTP values (one-time programmable)
- Even if attacker has ROM code, they cannot extract private key from public key hash
- Chain of trust extends to all subsequent boot stages via TISCI_MSG_PROC_AUTH_BOOT

### Host IDs and Contexts

Each processing entity in the SoC is assigned a **Host ID** that identifies it in TI SCI messages:

**Example Host IDs (J721E):**
```
TISCI_HOST_ID_DMSC        = 0   // DMSC itself
TISCI_HOST_ID_MCU_0_R5_0  = 3   // MCU R5F core 0
TISCI_HOST_ID_MCU_0_R5_1  = 4   // MCU R5F core 1
TISCI_HOST_ID_A72_0       = 10  // Cortex-A72 core 0
TISCI_HOST_ID_C66_0       = 25  // C66x DSP core 0
TISCI_HOST_ID_C7X_0       = 30  // C7x DSP core 0
```

Additionally, hosts can operate in different **security contexts**:
- **Secure Context**: Can access secure resources, configure firewalls
- **Non-Secure Context**: Limited privileges, cannot access secure regions

The SCICLIENT automatically determines the host ID and context based on the core it's running on.

### SCISERVER - RM/PM Service Proxy (J7 Devices)

**SCISERVER** is a software component that runs on the MCU R5F in newer K3 devices (J721E and later) to provide Resource Management and Power Management services. It acts as a proxy between application cores and the DMSC.

**Important:** SCISERVER handles **only the RM/PM subset** of TI SCI messages. TIFS on DMSC handles the security subset directly. Together, they provide the complete TI SCI interface.

#### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Application Cores (A72, Main R5F, DSP, etc.)               │
│  ┌──────────────────────────────────────────┐               │
│  │       SCICLIENT Library                   │               │
│  │  - Sciclient_pmSetModuleState()          │               │
│  │  - Sciclient_rmIrqSet()                  │               │
│  └──────────────────────────────────────────┘               │
│               ↓  TISCI Messages via Secure Proxy            │
└─────────────────────────────────────────────────────────────┘
                ↓
┌─────────────────────────────────────────────────────────────┐
│  DMSC (Cortex-M3) - TIFS (Security Services Only)           │
│  ┌──────────────────────────────────────────┐               │
│  │  - Firewall Configuration                 │               │
│  │  - Authenticated Boot                     │               │
│  │  - Message Forwarding Agent               │               │
│  └──────────────────────────────────────────┘               │
│               ↓  Forwards RM/PM Messages                     │
└─────────────────────────────────────────────────────────────┘
                ↓
┌─────────────────────────────────────────────────────────────┐
│  MCU R5F (Boot Core)                                        │
│  ┌──────────────────────────────────────────┐               │
│  │  SCISERVER (RM/PM Services)              │               │
│  │  - Processes PM requests (clocks, power) │               │
│  │  - Processes RM requests (DMA, IRQs)     │               │
│  │  - Maintains resource allocation tables  │               │
│  │  - Returns responses via DMSC            │               │
│  └──────────────────────────────────────────┘               │
│  ┌──────────────────────────────────────────┐               │
│  │  SBL + Application Code                  │               │
│  │  - May also use SCICLIENT Direct         │               │
│  └──────────────────────────────────────────┘               │
└─────────────────────────────────────────────────────────────┘
```

#### Key Components

**Sciserver_init(Sciserver_CfgPrms_t *pPrms)**
- Initializes SCISERVER subsystem on MCU R5F
- Sets up secure proxy threads for receiving messages from other cores
- Creates RTOS tasks to process incoming TISCI requests
- Called by SBL after Sciclient_init()

**Message Routing:**

TI SCI messages are routed based on message type:

| Message Category | Message Type Examples | Handler | Location |
|------------------|----------------------|---------|----------|
| **Security** | `TISCI_MSG_PROC_AUTH_BOOT`<br>`TISCI_MSG_SET_FWL_REGION`<br>`TISCI_MSG_KEYRING_IMPORT` | TIFS | DMSC (Cortex-M3) |
| **Power Mgmt** | `TISCI_MSG_SET_DEVICE`<br>`TISCI_MSG_SET_CLOCK`<br>`TISCI_MSG_GET_CLOCK` | SCISERVER | MCU R5F |
| **Resource Mgmt** | `TISCI_MSG_RM_IRQ_SET`<br>`TISCI_MSG_RM_UDMAP_TX_CH_CFG`<br>`TISCI_MSG_RM_RING_CFG` | SCISERVER | MCU R5F |

**Message Flow Example (RM/PM):**
1. Application core (e.g., A72) calls `Sciclient_pmSetModuleState()`
2. SCICLIENT sends TISCI message via secure proxy to DMSC
3. DMSC TIFS receives message, validates sender
4. DMSC recognizes it's an RM/PM message (type 0x0200-0x02FF, 0x1100-0x12FF)
5. DMSC forwards message to SCISERVER on MCU R5F
6. SCISERVER processes request (e.g., enables clock)
7. SCISERVER sends response back to DMSC
8. DMSC forwards response to original requesting core (A72)
9. SCICLIENT receives response and returns to application

**Message Flow Example (Security):**
1. Application core calls `Sciclient_procBootAuthAndStart()`
2. SCICLIENT sends TISCI message via secure proxy to DMSC
3. DMSC TIFS receives message, validates sender
4. DMSC recognizes it's a security message (type 0xC120)
5. DMSC TIFS processes request directly (authenticates binary, boots core)
6. DMSC sends response directly back to requesting core
7. SCICLIENT receives response and returns to application

#### SCISERVER vs SCICLIENT Direct

On the MCU R5F, two modes coexist:

**SCICLIENT Direct:**
- Used by SBL and MCU R5F applications
- Directly communicates with DMSC (for security) and SCISERVER (for RM/PM)
- Synchronous operation

**SCISERVER:**
- Services requests from OTHER cores
- Asynchronous operation via interrupt-driven tasks
- Coordination mechanism (`SCISERVER_CTRL_CMD_HALT`/`RUN`) prevents race conditions

#### Why SCISERVER on MCU R5F?

**Benefits:**
1. **HSM Support**: DMSC can focus exclusively on security services
2. **Free Main Domain R5F**: Older architecture used main R5F for DM, now available for applications
3. **Minimal Overhead**: RM/PM requires <150 KB memory and <10 MHz CPU
4. **Lockstep Safety**: MCU R5F can run in lockstep mode for functional safety

**Resource Requirements:**
- Memory: ~150 KB
- CPU: <10 MHz (minimal impact on MCU R5F applications)

#### Message Authentication

SCISERVER validates that incoming messages are not spoofed:
```c
// From sciserver.c - Verifies message host ID matches hardware-reported sender
ret = Sciserver_MsgVerifyHost(uhd->hw_msg_buffer, (uint8_t)hw_host);
```

The secure proxy hardware reports the true sender's host ID, which is compared against the host ID in the message header. Mismatches result in NAK responses.

---

## TI SCI Protocol Specification

### Message Structure

Every TI SCI message consists of a **header** followed by a **payload**:

```c
struct tisci_header {
    uint16_t type;        // Message type ID
    uint8_t  host;        // Host ID of sender
    uint8_t  seq;         // Sequence ID (for matching request/response)
    uint32_t flags;       // Message flags
} __attribute__((__packed__));

struct tisci_msg_example {
    struct tisci_header hdr;  // Always first
    uint32_t param_a;         // Payload fields
    uint16_t param_b;
    uint16_t param_c;
} __attribute__((__packed__));
```

### Header Fields

#### Message Type (`type`)

Identifies the service being requested. Examples:

| Type Value | Constant Name | Description |
|------------|---------------|-------------|
| 0x0000 | TISCI_MSG_VERSION | Get firmware version |
| 0x0001 | TISCI_MSG_BOARD_CONFIG | Send board configuration |
| 0x0200 | TISCI_MSG_SET_DEVICE | Set device power state |
| 0x0201 | TISCI_MSG_GET_DEVICE | Get device power state |
| 0x0100 | TISCI_MSG_SET_CLOCK | Set clock state |
| 0x1100 | TISCI_MSG_RM_IRQ_SET | Configure interrupt routing |
| 0x1200 | TISCI_MSG_RM_RING_CFG | Configure ring accelerator |

#### Host ID (`host`)

Automatically filled by SCICLIENT based on the processor core. Tells DMSC which core is making the request.

#### Sequence ID (`seq`)

A monotonically increasing counter (0-255, wraps around) used to match responses to requests. Critical for:
- **Concurrent requests**: Multiple requests can be in-flight simultaneously
- **Response correlation**: ISR must match received response to pending request

The SCICLIENT maintains:
```c
uint32_t currSeqId;  // Current sequence number
```

And increments it for each request:
```c
seqId = (pHandle->currSeqId++) % SCICLIENT_MAX_QUEUE_SIZE;
```

#### Flags (`flags`)

Control message behavior:

**Request Flags:**
```c
// Request acknowledgment only after processing completes
#define TISCI_MSG_FLAG_AOP (0x1U << 0)

// Allow DMSC to change power domain state even if in use
#define TISCI_MSG_FLAG_WAKE_ENABLED (0x1U << 1)
```

**Response Flags:**
```c
// Generic ACK (success)
#define TISCI_MSG_FLAG_ACK (0x1U << 0)

// Generic NACK (failure)
#define TISCI_MSG_FLAG_NACK (0x1U << 1)
```

### Secure Messages (HS Devices)

On High-Security (HS) devices, messages include an additional **security header**:

```c
struct tisci_sec_header {
    uint16_t integ_check;   // Integrity check value
    uint8_t  rsvd1;
    uint8_t  rsvd2;
} __attribute__((__packed__));

// Complete secure message structure:
// [tisci_sec_header][tisci_header][payload]
```

The SCICLIENT automatically adds this header when running in secure mode.

### Message Flow

#### Request-Response Pattern

All TI SCI messages follow a synchronous request-response pattern:

```
Client (MCU R5F)                          DMSC Firmware
     |                                          |
     | ---- Write Request to TX Thread ----->  |
     |         [Header + Payload]               |
     |                                          |
     |                                    Process Request
     |                                    Check Permissions
     |                                    Perform Action
     |                                          |
     | <---- Write Response to RX Thread ----  |
     |         [Header + Response Payload]      |
     |                                          |
  Read Response                                 |
  Match seq ID                                  |
  Return to App                                 |
```

#### Acknowledgment Modes

**1. ACK_ON_PROCESSED (Most Common)**
```c
flags = TISCI_MSG_FLAG_AOP;
```
DMSC sends response only after completing the requested operation.

**2. ACK_ON_RECEIPT (Rarely Used)**
```c
flags = 0;  // No AOP flag
```
DMSC sends immediate acknowledgment, operation may still be in progress.

### Message Categories

The TI SCI protocol defines messages in several categories:

#### Core/Generic Messages
- `TISCI_MSG_VERSION`: Get firmware version and ABI info
- `TISCI_MSG_BOARD_CONFIG`: Send board configuration data
- `TISCI_MSG_BOARD_CONFIG_RM`: Send resource management configuration
- `TISCI_MSG_BOARD_CONFIG_PM`: Send power management configuration
- `TISCI_MSG_BOARD_CONFIG_SECURITY`: Send security configuration

#### Power Management Messages
- `TISCI_MSG_SET_DEVICE`: Request device state change
- `TISCI_MSG_GET_DEVICE`: Query device state
- `TISCI_MSG_SET_DEVICE_RESETS`: Control device reset lines
- `TISCI_MSG_SET_CLOCK`: Set clock on/off
- `TISCI_MSG_SET_CLOCK_PARENT`: Configure clock mux
- `TISCI_MSG_SET_FREQ`: Set clock frequency
- `TISCI_MSG_QUERY_FREQ`: Query achievable frequency range

#### Resource Management Messages
- `TISCI_MSG_RM_IRQ_SET`: Route an interrupt
- `TISCI_MSG_RM_IRQ_RELEASE`: Free an interrupt route
- `TISCI_MSG_RM_RING_CFG`: Configure a ring accelerator ring
- `TISCI_MSG_RM_UDMAP_TX_CH_CFG`: Configure UDMA TX channel
- `TISCI_MSG_RM_UDMAP_RX_CH_CFG`: Configure UDMA RX channel
- `TISCI_MSG_RM_PSIL_PAIR`: Pair PSI-L threads

#### Security Messages
- `TISCI_MSG_FWL_SET`: Configure firewall region
- `TISCI_MSG_FWL_GET`: Query firewall configuration
- `TISCI_MSG_PROC_REQUEST`: Request processor control
- `TISCI_MSG_PROC_RELEASE`: Release processor
- `TISCI_MSG_PROC_HANDOVER`: Transfer processor ownership
- `TISCI_MSG_SET_AUTH_BOOT`: Configure secure boot

### Error Handling

DMSC can return errors in the response flags or in payload-specific error codes:

**Common Error Scenarios:**
- **Permission Denied**: Requesting resource not assigned to this host
- **Invalid Parameter**: Out-of-range device ID, clock ID, etc.
- **Resource Busy**: Device in use by another host
- **Not Supported**: Feature not available on this SoC variant

**Response Handling:**
```c
Sciclient_RespPrm_t respPrm;
int32_t status = Sciclient_service(&reqPrm, &respPrm);

if (status != CSL_PASS) {
    // Communication failure (timeout, invalid param)
}

if (respPrm.flags & TISCI_MSG_FLAG_NACK) {
    // DMSC rejected the request
    // Check tisci_msg_*_resp payload for detailed error
}
```

---

## SCICLIENT Architecture and Design

### Software Architecture

The SCICLIENT driver is structured in layers:

```
┌───────────────────────────────────────────────────────┐
│              Application Layer                         │
├───────────────────────────────────────────────────────┤
│          Functional Layer (FL) APIs                    │
│  sciclient_pm.h   - Power Management wrappers         │
│  sciclient_rm.h   - Resource Management wrappers      │
│  sciclient_firewall.h - Security/Firewall wrappers    │
│  sciclient_procboot.h - Processor boot control        │
├───────────────────────────────────────────────────────┤
│          Hardware Abstraction Layer (HAL)              │
│  sciclient.h - Core Sciclient_service() API           │
│  - Message construction                                │
│  - TX/RX via secure proxy                             │
│  - Timeout and synchronization                        │
├───────────────────────────────────────────────────────┤
│          CSL (Chip Support Library)                    │
│  csl_sec_proxy.h - Secure proxy low-level access      │
│  - Register programming                                │
│  - Thread configuration                                │
├───────────────────────────────────────────────────────┤
│          OSAL (OS Abstraction Layer)                   │
│  Semaphores, Interrupts, Cache operations             │
├───────────────────────────────────────────────────────┤
│                  Hardware                              │
│  Secure Proxy / Ring Accelerator                      │
└───────────────────────────────────────────────────────┘
```

### Key Data Structures

#### Configuration Parameters

```c
typedef struct {
    uint32_t opModeFlag;
    /**< Operation mode:
     *   - SCICLIENT_SERVICE_OPERATION_MODE_POLLED (0U)
     *   - SCICLIENT_SERVICE_OPERATION_MODE_INTERRUPT (1U)
     */

    Sciclient_BoardCfgPrms_t *pBoardCfgPrms;
    /**< Board configuration to send to DMSC during init.
     *   NULL = use defaults
     */

    uint32_t isSecureMode;
    /**< 0 = Non-secure context, 1 = Secure context */

    uint32_t c66xRatRegion;
    /**< C66x RAT region for mapping interrupt router (C66x only) */

    uint8_t skipLocalBoardCfgProcess;
    /**< Skip local RM/PM board cfg processing */

    Sciclient_BoardCfgPrms_t inPmPrms;
    /**< PM board config parameters */

    Sciclient_BoardCfgPrms_t inRmPrms;
    /**< RM board config parameters */
} Sciclient_ConfigPrms_t;
```

#### Request Parameters

```c
typedef struct {
    uint16_t messageType;
    /**< TI SCI message type (e.g., TISCI_MSG_SET_DEVICE) */

    uint32_t flags;
    /**< Message flags (e.g., TISCI_MSG_FLAG_AOP) */

    const uint8_t *pReqPayload;
    /**< Pointer to message payload (after header) */

    uint32_t reqPayloadSize;
    /**< Size of payload in bytes */

    uint32_t timeout;
    /**< Timeout for response:
     *   - SCICLIENT_SERVICE_WAIT_FOREVER (0xFFFFFFFF)
     *   - SCICLIENT_SERVICE_NO_WAIT (0x0)
     *   - Specific iteration count
     */

    uint8_t forwardStatus;
    /**< Internal: For sciserver forwarding */
} Sciclient_ReqPrm_t;
```

#### Response Parameters

```c
typedef struct {
    uint32_t flags;
    /**< Response flags from DMSC:
     *   - TISCI_MSG_FLAG_ACK = Success
     *   - TISCI_MSG_FLAG_NACK = Failure
     */

    uint8_t *pRespPayload;
    /**< [IN] Pointer to buffer for response payload
     *   [OUT] Filled with response data by Sciclient
     */

    uint32_t respPayloadSize;
    /**< [IN] Size of pRespPayload buffer in bytes */
} Sciclient_RespPrm_t;
```

#### Service Handle (Internal)

```c
typedef struct {
    SemaphoreP_Handle semHandles[SCICLIENT_MAX_QUEUE_SIZE];
    /**< Semaphores for synchronizing responses (one per seq ID) */

    SemaphoreP_Status semStatus[SCICLIENT_MAX_QUEUE_SIZE];
    /**< Status of each semaphore (timeout, success) */

    uint32_t currSeqId;
    /**< Current sequence ID counter */

    HwiP_Handle notificationIntr;
    /**< Interrupt handler for notifications */

    HwiP_Handle respIntr[2];
    /**< Response interrupt handlers [0]=non-sec, [1]=sec */

    uint32_t opModeFlag;
    /**< 0 = Polling, 1 = Interrupt mode */

    uint8_t initCount;
    /**< Reference count for init/deinit */

    uint32_t isSecureMode;
    /**< Security context (0 = non-secure, 1 = secure) */

    // ... additional fields for thread mappings, buffers, etc.
} Sciclient_ServiceHandle_t;
```

### Initialization Sequence

```c
int32_t Sciclient_init(const Sciclient_ConfigPrms_t *pCfgPrms)
```

**Steps:**

1. **Check Init Count**
   - If already initialized, increment count and return
   - Allows multiple init calls without re-initialization

2. **Set Default Parameters** (if pCfgPrms == NULL)
   ```c
   opModeFlag = SCICLIENT_SERVICE_OPERATION_MODE_INTERRUPT;
   isSecureMode = 0;  // Non-secure by default
   ```

3. **Determine Host ID**
   - Based on processor core (A72, R5F, C66x, C7x)
   - Look up host ID from SoC-specific tables

4. **Configure Secure Proxy Threads**
   - Identify TX and RX thread IDs for this host
   - Map threads based on security context

5. **Create Semaphores**
   ```c
   for (i = 0; i < SCICLIENT_MAX_QUEUE_SIZE; i++) {
       gSciclientHandle.semHandles[i] = SemaphoreP_create(0, &semParams);
   }
   ```

6. **Register Interrupts** (if opModeFlag == INTERRUPT)
   ```c
   HwiP_create(intrNum, Sciclient_ISR, &hwiParams);
   ```

7. **Send Board Configuration** (if pBoardCfgPrms != NULL)
   - Board config defines resource allocations, clock settings
   - Must be sent before other services can be used

8. **Initialize Sequence Counter**
   ```c
   gSciclientHandle.currSeqId = 0;
   ```

**Return:** `CSL_PASS` on success, error code on failure

### Service API Core Flow

```c
int32_t Sciclient_service(const Sciclient_ReqPrm_t *pReqPrm,
                          Sciclient_RespPrm_t *pRespPrm)
```

This is the **core API** that all higher-level functions use. It handles:

#### Step 1: Construct Message

```
┌──────────────────────────────────────┐
│ If Secure Mode:                      │
│   [tisci_sec_header]                 │
├──────────────────────────────────────┤
│ [tisci_header]                       │
│   type     = pReqPrm->messageType    │
│   host     = auto-determined          │
│   seq      = currSeqId               │
│   flags    = pReqPrm->flags          │
├──────────────────────────────────────┤
│ [Payload]                            │
│   memcpy(pReqPrm->pReqPayload)       │
└──────────────────────────────────────┘
```

Message is constructed in **normal memory**, not directly in secure proxy memory.

#### Step 2: Identify Secure Proxy Threads

Based on `gSciclientHandle.map`:
```c
txThreadId = map->reqLowPrioThreadId;  // Or reqHighPrioThreadId
rxThreadId = map->respThreadId;
```

For J721E MCU R5F:
- TX Thread: 11 (low priority) or 13 (high priority)
- RX Thread: 12 (response thread)

#### Step 3: Acquire Proxy Mutex

```c
// Wait for exclusive access to secure proxy
SemaphoreP_pend(gSciclientHandle.proxySem, WAIT_FOREVER);
```

Prevents multiple threads from writing simultaneously.

#### Step 4: Get Sequence ID and Prepare

```c
seqId = (gSciclientHandle.currSeqId++) % SCICLIENT_MAX_QUEUE_SIZE;
gSciclientHandle.semStatus[seqId] = SemaphoreP_OK;
```

#### Step 5: Wait for TX Thread Ready

```c
// Poll until TX thread has space (curr_cnt > 0)
do {
    CSL_secProxyGetThreadStatus(&status);
} while (status.curMsgCnt == 0 && timeout > 0);
```

The secure proxy TX thread must have available slots.

#### Step 6: Read RX Thread Initial Count

```c
initialRxCount = CSL_secProxyGetThreadStatus(rxThreadId).curMsgCnt;
```

Used to detect when a new response arrives.

#### Step 7: Write Message to TX Thread

```c
CSL_secProxyAccessTarget(
    pSecProxyCfg,
    txThreadId,
    pMessage,        // Constructed message buffer
    messageSize,
    fpMemAccess      // Memory access callback function
);
```

This writes the message to the secure proxy buffer and triggers hardware to send it to DMSC.

#### Step 8: Release Proxy Mutex

```c
SemaphoreP_post(gSciclientHandle.proxySem);
```

#### Step 9: Wait for Response

**Polling Mode:**
```c
isMsgReceived = 0;
do {
    currentRxCount = CSL_secProxyGetThreadStatus(rxThreadId).curMsgCnt;

    if (currentRxCount > initialRxCount) {
        // New message available
        // Peek at header to check sequence ID
        CSL_secProxyAccessTarget(..., peek=true);

        if (receivedSeqId == seqId) {
            // This is our response
            CSL_secProxyAccessTarget(...);  // Read full message
            isMsgReceived = 1;
        }
    }
} while (!isMsgReceived && timeout > 0);
```

**Interrupt Mode:**
```c
// Wait on semaphore (posted by ISR)
status = SemaphoreP_pend(gSciclientHandle.semHandles[seqId], timeout);

if (status == SemaphoreP_OK) {
    // ISR already read message into gSciclientHandle.respMsgArr[seqId]
    // Copy to pRespPayload
}
```

**Interrupt Service Routine (ISR):**
```c
static void Sciclient_ISR(uintptr_t arg) {
    // Read message from RX thread
    CSL_secProxyAccessTarget(rxThreadId, tempBuf, ...);

    // Extract sequence ID from header
    seqId = ((struct tisci_header *)tempBuf)->seq;

    // Store message for the waiting thread
    memcpy(gSciclientHandle.respMsgArr[seqId], tempBuf, ...);

    // Wake up the waiting thread
    SemaphoreP_post(gSciclientHandle.semHandles[seqId]);
}
```

#### Step 10: Extract Response

```c
// Parse response header
respHeader = (struct tisci_header *)receivedMessage;
pRespPrm->flags = respHeader->flags;

// Copy response payload
memcpy(pRespPrm->pRespPayload,
       receivedMessage + sizeof(struct tisci_header),
       pRespPrm->respPayloadSize);
```

#### Step 11: Return Status

```c
if (respHeader->flags & TISCI_MSG_FLAG_ACK) {
    return CSL_PASS;
} else {
    return CSL_EFAIL;  // NACK received
}
```

### Operation Modes

#### Polling Mode

**Configuration:**
```c
Sciclient_ConfigPrms_t cfgPrms;
Sciclient_configPrmsInit(&cfgPrms);
cfgPrms.opModeFlag = SCICLIENT_SERVICE_OPERATION_MODE_POLLED;
Sciclient_init(&cfgPrms);
```

**Behavior:**
- No interrupts registered
- `Sciclient_service()` busy-waits for response
- CPU actively polls RX thread status registers
- **Advantage**: Simple, no interrupt overhead
- **Disadvantage**: Wastes CPU cycles during wait

**Use Case:**
- Bare-metal applications
- Early boot (before interrupt infrastructure ready)
- Short-duration requests

#### Interrupt Mode

**Configuration:**
```c
cfgPrms.opModeFlag = SCICLIENT_SERVICE_OPERATION_MODE_INTERRUPT;
Sciclient_init(&cfgPrms);
```

**Behavior:**
- Interrupt registered for RX thread
- `Sciclient_service()` blocks on semaphore
- ISR posted semaphore when response arrives
- **Advantage**: CPU can task-switch during wait
- **Disadvantage**: Interrupt overhead

**Use Case:**
- RTOS applications
- Long-duration requests
- Multiple concurrent requests

---

## Secure Proxy Communication Mechanism

### What is Secure Proxy?

The **Secure Proxy** is a hardware IP block that provides mailbox-style message-passing communication between processing entities (hosts) in the SoC. It acts as a hardware-enforced communication infrastructure for the TI SCI protocol.

#### Hardware Components

- **Configuration Registers (MMR)**: Control registers for thread setup and configuration
- **Target Memory Buffers**: Memory-mapped 4KB regions where messages are written/read
- **Threads**: Independent, unidirectional message queues (each is either TX or RX)
- **Event/Interrupt Generation**: Hardware signals for message availability and errors

#### Key Concept - "Thread"

A **thread** in secure proxy context is **NOT** a software thread. It is a **hardware message queue** with these characteristics:

- **Unidirectional**: Each thread is either TX (outbound) or RX (inbound) - never both
- **Dedicated Memory Buffer**: 4KB memory-mapped region per thread
- **Queue Depth**: Configurable number of messages (e.g., 2, 5, 7, 10, 20, 30, 67 messages)
- **Direction-Specific**:
  - **TX Thread**: Application writes, DMSC/SCISERVER reads
  - **RX Thread**: DMSC/SCISERVER writes, application reads
- **Hardware-Managed**: Hardware tracks message count, generates events, enforces security

#### Thread Assignment - Who, When, and How

Threads are **statically assigned** to hosts based on SoC design:

**1. Who Assigns:**

**TI hardware designers** during SoC architecture design
- Assignment is part of the SoC's fixed hardware configuration
- Documented in SoC-specific TRM (Technical Reference Manual) and SYSFW docs

**2. When Assigned:**

**Before chip fabrication** - it's part of the SoC's hardware design
- The physical secure proxy hardware has a fixed number of threads (e.g., 139 threads on J721E)
- Each thread's target address and characteristics are fixed in silicon

**3. How Hosts Learn Their Assignments:**

- **Compile-time**: Thread IDs are defined in SoC-specific header files
- **Board Configuration**: RM board config specifies resource allocation including proxy threads
- **Runtime Discovery**: Hosts can query DMSC for their assigned thread ranges

**4. Configuration Process:**

```
[SoC Design Time - TI]
  ↓ Thread allocation designed into hardware

[Board Configuration Time - OEM/Developer]
  ↓ SBL sends TISCI_MSG_BOARD_CONFIG_RM to DMSC
  ↓ Specifies which threads each host can use
  ↓ DMSC configures firewalls to enforce access

[Runtime - Application]
  ↓ SCICLIENT library uses pre-configured thread IDs
  ↓ Hardware enforces access permissions
```

#### Example Thread Allocation (J721E)

**NAVSS0_SEC_PROXY_0 Thread Assignments:**

```
Host: A72_0 (Cortex-A72 core 0)
  Thread 0:  RX - notify         (2 messages deep)
  Thread 1:  RX - response       (30 messages deep)
  Thread 2:  TX - high_priority  (10 messages deep)
  Thread 3:  TX - low_priority   (20 messages deep)
  Thread 4:  TX - notify_resp    (2 messages deep)

Host: MAIN_0_R5_0 (Main domain R5F core 0)
  Thread 60: RX - notify         (2 messages deep)
  Thread 61: RX - response       (7 messages deep)
  Thread 62: TX - high_priority  (2 messages deep)
  Thread 63: TX - low_priority   (5 messages deep)
  Thread 64: TX - notify_resp    (2 messages deep)

Host: DM (Device Manager - MCU R5F running SCISERVER)
  Thread 136: RX - nonsec_notify_resp_rx    (22 messages deep)
  Thread 137: RX - nonsec_low_priority_rx   (67 messages deep)
  Thread 138: RX - nonsec_high_priority_rx  (22 messages deep)
  Thread 120-135: TX - responses to various hosts
```

**Key Points:**
- Each host has multiple threads for different purposes (high/low priority, responses, notifications)
- Thread IDs are **not** sequential per host - they're globally numbered across the secure proxy
- The "Number of Messages" (queue depth) varies by usage pattern
- SCISERVER (DM) has many RX threads to receive from all other hosts
- Write direction threads don't generate interrupts (N/A for IRQ column)

### Secure Proxy Architecture

```
┌────────────────────────────────────────────────────────┐
│                    Secure Proxy IP                      │
├────────────────────────────────────────────────────────┤
│  Config MMR (Non-Secure)                               │
│   - PID, CONFIG registers                              │
├────────────────────────────────────────────────────────┤
│  Secure Config MMR (Secure Access Only)                │
│   - Thread configuration (CTL, EVT_MAP, DST)           │
│   - Buffer address configuration                        │
├────────────────────────────────────────────────────────┤
│  Real-Time MMR                                         │
│   - Thread status (curr_cnt, error)                    │
│   - Threshold configuration                             │
├────────────────────────────────────────────────────────┤
│  Target Data Region (Memory-Mapped Buffers)            │
│   Thread 0: [Reserved][Data...]                        │
│   Thread 1: [Reserved][Data...]                        │
│   ...                                                   │
│   Thread N: [Reserved][Data...]                        │
└────────────────────────────────────────────────────────┘
```

### Thread Configuration

Each secure proxy thread is configured with:

```c
typedef struct {
    uint32_t dir;                  // 0=TX (outbound), 1=RX (inbound)
    uint32_t outboundMaxMsgCnt;    // Max messages for TX thread
    uint32_t outboundDstThread;    // Destination thread ID
    uint32_t queueNum;             // Target queue number
    uint32_t threshCnt;            // Threshold for events
    uint32_t errEvtNum;            // Error event number
    uint32_t threshEvtNum;         // Threshold event number
} CSL_SecProxyThreadCfg;
```

#### Thread Direction

- **TX (Outbound)**: Application writes, DMSC reads
- **RX (Inbound)**: DMSC writes, application reads

#### MCU R5F Thread Example (J721E)

```
Host: MCU_0_R5_0 (Host ID = 3)

TX Threads:
  Thread 11: Low-priority requests to DMSC
  Thread 13: High-priority requests to DMSC

RX Threads:
  Thread 12: Responses from DMSC
  Thread 14: Notifications from DMSC
```

### Message Buffer Layout

Each thread has a dedicated buffer in the target data region:

```
Thread Buffer (4KB per thread):

Offset 0x000: [4 bytes Reserved - Used by HW]
Offset 0x004: [Message Data Start]
  ...
Offset 0xFFF: [Message Data End]
```

**Important:** The first 4 bytes (`CSL_SEC_PROXY_RSVD_MSG_BYTES`) are reserved for hardware tracking.

#### Maximum Message Size

- Determined by secure proxy configuration
- Typically 60-64 bytes
- Read from `CONFIG.msg_size` register

### Writing a Message (TX)

```c
void CSL_secProxyAccessTarget(
    CSL_SecProxyCfg *pSecProxyCfg,
    uint32_t threadNum,
    uint8_t *pData,
    uint32_t numBytes,
    CSL_SecProxyMemAccessCbFxnPtr fpMemAccess
)
```

#### TX Steps

**1. Calculate Data Address:**

```c
dataAddr = pSecProxyCfg->proxyTargetAddr
         + (threadNum * 0x1000)  // Thread offset
         + 4;                    // Skip reserved bytes
```

**2. Write Data:**

```c
fpMemAccess(dataAddr, pData, 1, numBytes);
```

Uses callback to handle potential cache/MMU issues.

**3. Trigger Send:**

```c
// Access last byte of buffer to signal completion
lastByteAddr = dataAddr + maxMsgSize - 1;
fpMemAccess(lastByteAddr, &dummy, 1, 1);
```

This HW trigger signals that the message is complete and ready.

**4. Hardware Action:**

- Secure proxy decrements TX thread `curr_cnt`
- Sends message to destination (DMSC)
- DMSC RX thread `curr_cnt` increments

### Reading a Message (RX)

#### RX Steps

**1. Poll or Wait for Interrupt:**

```c
CSL_SecProxyThreadStatus status;
CSL_secProxyGetThreadStatus(pSecProxyCfg, rxThreadId, &status);

if (status.curMsgCnt > 0) {
    // Message available
}
```

**2. Read Data:**

```c
CSL_secProxyAccessTarget(rxThreadId, buffer, msgSize, fpRead);
```

**3. Hardware Action:**

- RX thread `curr_cnt` decrements after read
- Message is acknowledged and buffer is freed

### Thread Status Monitoring

```c
typedef struct {
    uint32_t error;       // 0=no error, 1=error detected
    uint32_t dir;         // 0=outbound, 1=inbound
    uint32_t maxMsgCnt;   // Max messages (TX only)
    uint32_t curMsgCnt;   // Current available messages
} CSL_SecProxyThreadStatus;
```

#### TX Thread Status

- `curMsgCnt` = number of free slots
- Wait until `curMsgCnt > 0` before writing

#### RX Thread Status

- `curMsgCnt` = number of pending messages
- Read when `curMsgCnt > 0`

### Event and Interrupt Generation

Secure proxy can generate interrupts based on:

#### Threshold Events

- **TX**: Triggered when free slots ≥ threshold
- **RX**: Triggered when messages ≥ threshold

#### Error Events

- Buffer overflow
- Invalid access
- Protocol violations

#### Interrupt Routing

```c
threadCfg.threshEvtNum = 100;  // Event number sent to interrupt router
threadCfg.errEvtNum = 101;
```

The event numbers are routed through the SoC's interrupt router to the target core's GIC/VIM.

### Memory Access Callbacks

The secure proxy CSL uses callbacks for memory access to handle various scenarios:

```c
typedef void (*CSL_SecProxyMemAccessCbFxnPtr)(
    uintptr_t addr,
    uint8_t *pData,
    uint32_t elemSizeBytes,
    uint32_t elemCnt
);
```

#### Why Callbacks?

- **Cache Coherency**: May need flush/invalidate
- **MMU Mapping**: Virtual to physical address translation
- **Unaligned Access**: C66x DSP requires special handling

#### SCICLIENT Implementation

```c
static void Sciclient_utilByteCopy(uint8_t *src, uint8_t *dest,
                                    uint32_t num_bytes) {
    // Handle cache coherency
    CacheP_wbInv((void *)src, num_bytes);

    // Byte-wise copy for unaligned access
    for (i = 0; i < num_bytes; i++) {
        dest[i] = src[i];
    }

    CacheP_wbInv((void *)dest, num_bytes);
}
```

---

## Ring Accelerator Integration

### Ring Accelerator Overview

The **Ring Accelerator (RA)** is an alternative communication mechanism to Secure Proxy, used in some SoC variants. It provides:

- **Circular ring buffers** in memory
- **DMA-friendly** message passing
- **Hardware-managed** read/write pointers

**When Used:**
- Typically for communication with DMSC on certain devices
- Higher throughput than Secure Proxy
- Better integration with NAVSS (Network Accelerator SubSystem)

### Ring Structure

A ring is a circular buffer with hardware-managed pointers:

```
Ring Memory Layout:

┌───────────────────────────────────┐
│  Ring Element 0                   │  ← Read Pointer (occ)
├───────────────────────────────────┤
│  Ring Element 1                   │
├───────────────────────────────────┤
│  Ring Element 2                   │  ← Write Pointer (idx)
├───────────────────────────────────┤
│  Ring Element 3                   │
├───────────────────────────────────┤
│  ...                              │
├───────────────────────────────────┤
│  Ring Element N-1                 │
└───────────────────────────────────┘
       ↓ Wraps around to Element 0
```

**Ring Modes:**
- **Ring Mode**: Elements are fixed-size descriptors
- **Message Mode**: Elements are variable-size messages
- **Credentials Mode**: Used for security/firewall tokens

### Ring Accelerator vs Secure Proxy

| Feature | Secure Proxy | Ring Accelerator |
|---------|--------------|------------------|
| Buffer Type | Fixed HW buffers | Flexible memory buffers |
| Message Size | Limited (~64 bytes) | Larger messages possible |
| Throughput | Moderate | High |
| DMA Integration | Limited | Native |
| Configuration | Static threads | Dynamic ring allocation |
| Use Case | Simple messaging | High-bandwidth data transfer |

### SCICLIENT Ring Usage

While SCICLIENT primarily uses Secure Proxy for TI SCI messages, Ring Accelerator is used for:

1. **DMA Descriptor Management**: UDMA uses rings for descriptor queues
2. **DMSC Notification**: Some notification paths use rings
3. **High-Throughput Scenarios**: Bulk configuration data

**Example: UDMA Integration**
```c
// UDMA uses rings for TX/RX descriptor queues
// Sciclient configures rings via RM messages

struct tisci_msg_rm_ring_cfg_req req;
req.addr = ringMemoryAddress;
req.count = ringElementCount;
req.mode = TISCI_MSG_VALUE_RM_RING_MODE_RING;
req.size = TISCI_MSG_VALUE_RM_RING_SIZE_64B;
req.order_id = 0;

Sciclient_rmRingCfg(&req);
```

---

## Message Categories and APIs

### Power Management (PM) APIs

#### Device Power State Control

```c
int32_t Sciclient_pmSetModuleState(
    uint32_t moduleId,      // Device ID (e.g., TISCI_DEV_UART0)
    uint32_t state,         // Desired state
    uint32_t additionalFlag, // Flags for power domain control
    uint32_t timeout        // Response timeout
);
```

**States:**
```c
TISCI_MSG_VALUE_DEVICE_SW_STATE_AUTO_OFF  // Allow auto power-off
TISCI_MSG_VALUE_DEVICE_SW_STATE_RETENTION // Retention mode
TISCI_MSG_VALUE_DEVICE_SW_STATE_ON        // Fully powered on
```

**Flags:**
```c
TISCI_MSG_FLAG_AOP                  // Allow power domain control
TISCI_MSG_FLAG_DEVICE_WAKE_ENABLED  // Keep powered during sleep
TISCI_MSG_FLAG_DEVICE_RESET_ISO     // Reset isolation
TISCI_MSG_FLAG_DEVICE_EXCLUSIVE     // Exclusive access
```

**Example:**
```c
// Power on UART0 with automatic power domain management
status = Sciclient_pmSetModuleState(
    TISCI_DEV_UART0,
    TISCI_MSG_VALUE_DEVICE_SW_STATE_ON,
    TISCI_MSG_FLAG_AOP,
    SCICLIENT_SERVICE_WAIT_FOREVER
);
```

#### Clock Control

```c
int32_t Sciclient_pmModuleClkRequest(
    uint32_t moduleId,      // Device ID
    uint32_t clockId,       // Clock ID within device
    uint32_t state,         // Clock state
    uint32_t additionalFlag, // Additional flags
    uint32_t timeout
);
```

**Clock States:**
```c
TISCI_MSG_VALUE_CLOCK_SW_STATE_UNREQ // No request
TISCI_MSG_VALUE_CLOCK_SW_STATE_AUTO  // Auto-managed
TISCI_MSG_VALUE_CLOCK_SW_STATE_REQ   // Request clock on
```

**Clock IDs Example (UART0):**
```c
TISCI_DEV_UART0_FCLK_CLK   // Functional clock
TISCI_DEV_UART0_ICLK_CLK   // Interface clock
```

**Example:**
```c
// Enable UART0 functional clock
Sciclient_pmModuleClkRequest(
    TISCI_DEV_UART0,
    TISCI_DEV_UART0_FCLK_CLK,
    TISCI_MSG_VALUE_CLOCK_SW_STATE_REQ,
    0,
    SCICLIENT_SERVICE_WAIT_FOREVER
);
```

#### Clock Frequency Setting

```c
int32_t Sciclient_pmSetModuleClkFreq(
    uint32_t moduleId,
    uint32_t clockId,
    uint64_t freqHz,         // Desired frequency in Hz
    uint32_t additionalFlag,
    uint32_t timeout
);
```

**Flags:**
```c
TISCI_MSG_FLAG_CLOCK_ALLOW_FREQ_CHANGE  // Allow freq change while running
TISCI_MSG_FLAG_CLOCK_ALLOW_SSC          // Allow spread spectrum clocking
```

**Example:**
```c
// Set UART0 functional clock to 48 MHz
Sciclient_pmSetModuleClkFreq(
    TISCI_DEV_UART0,
    TISCI_DEV_UART0_FCLK_CLK,
    48000000ULL,  // 48 MHz
    0,
    SCICLIENT_SERVICE_WAIT_FOREVER
);
```

#### Query Achievable Frequency

```c
int32_t Sciclient_pmQueryModuleClkFreq(
    uint32_t moduleId,
    uint32_t clockId,
    uint64_t freqHz,    // Target frequency
    uint32_t timeout
);
```

Response contains closest achievable frequency.

#### Clock Parent Selection

```c
int32_t Sciclient_pmSetModuleClkParent(
    uint32_t moduleId,
    uint32_t clockId,
    uint32_t parent,    // Parent clock ID
    uint32_t timeout
);
```

Selects clock source from available mux options.

---

### General/Core Messages (TISCI Protocol)

Based on `packages/ti/drv/sciclient/soc/sysfw/.../2_tisci_msgs/general/core.rst.txt`

These are foundational TISCI protocol messages that provide version information, boot coordination, and board configuration.

#### TISCI_MSG_VERSION (0x0000)

Get firmware version and ABI information.

```c
struct tisci_msg_version_req {
    struct tisci_header hdr;
} __attribute__((__packed__));

struct tisci_msg_version_resp {
    struct tisci_header hdr;
    char str[32];           // Firmware version string
    uint16_t version;       // Firmware version number (BCD format)
    uint8_t abi_major;      // ABI major version
    uint8_t abi_minor;      // ABI minor version
} __attribute__((__packed__));
```

**Usage:**
- First message sent during initialization to verify compatibility
- ABI version determines message structure compatibility
- Version string provides human-readable firmware identification

**Example Response:**
- `str`: "AM6-DMSC-v2020.09"
- `version`: 0x2020 (2020 in BCD)
- `abi_major`: 3
- `abi_minor`: 1

#### TISCI_MSG_BOOT_NOTIFICATION (0xA000)

DMSC sends this message to ROM/SPL when DMSC firmware initialization is complete.

```c
struct tisci_msg_boot_notification_req {
    struct tisci_header hdr;
} __attribute__((__packed__));

struct tisci_msg_boot_notification_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

**Characteristics:**
- **Direction**: DMSC → Host (unsolicited message)
- **Purpose**: Signal that DMSC is ready to accept TISCI messages
- **Boot Flow**: Sent after DMSC firmware completes internal initialization

**Note**: This is one of the few TISCI messages initiated by DMSC rather than by a host processor.

#### Board Configuration Messages

These messages configure system-wide settings during boot initialization.

##### TISCI_MSG_BOARD_CONFIG (0x000C)

Send base board configuration to DMSC.

```c
struct tisci_msg_board_config_req {
    struct tisci_header hdr;
    uint32_t boardcfg_addr_lo;  // Board config address (low 32 bits)
    uint32_t boardcfg_addr_hi;  // Board config address (high 32 bits)
    uint32_t boardcfg_size;     // Size of board config data
} __attribute__((__packed__));

struct tisci_msg_board_config_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

**Purpose**: Provide base board configuration including:
- Host assignment and privileges
- Security settings
- General SoC configuration

##### TISCI_MSG_BOARD_CONFIG_RM (0x000D)

Send Resource Management board configuration.

```c
struct tisci_msg_board_config_rm_req {
    struct tisci_header hdr;
    uint32_t boardcfg_addr_lo;
    uint32_t boardcfg_addr_hi;
    uint32_t boardcfg_size;
} __attribute__((__packed__));

struct tisci_msg_board_config_rm_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

**Purpose**: Configure resource allocation per host:
- IRQ routing resources
- DMA channel assignments
- Ring Accelerator resources
- Proxy thread assignments

##### TISCI_MSG_BOARD_CONFIG_SECURITY (0x000E)

Send Security board configuration.

```c
struct tisci_msg_board_config_security_req {
    struct tisci_header hdr;
    uint32_t boardcfg_addr_lo;
    uint32_t boardcfg_addr_hi;
    uint32_t boardcfg_size;
} __attribute__((__packed__));

struct tisci_msg_board_config_security_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

**Purpose**: Configure security policies:
- Firewall region definitions
- SA2UL (Security Accelerator) settings
- Access control policies

##### TISCI_MSG_BOARD_CONFIG_PM (0x000F)

Send Power Management board configuration.

```c
struct tisci_msg_board_config_pm_req {
    struct tisci_header hdr;
    uint32_t boardcfg_addr_lo;
    uint32_t boardcfg_addr_hi;
    uint32_t boardcfg_size;
} __attribute__((__packed__));

struct tisci_msg_board_config_pm_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

**Purpose**: Configure power management settings:
- Clock tree configuration
- Power domain defaults
- Voltage rail settings
- Wake-up source configuration

**Board Config Sequence:**

During boot, board configurations must be sent in order:
1. Base Board Config (0x000C)
2. PM Board Config (0x000F)
3. RM Board Config (0x000D)
4. Security Board Config (0x000E)

---

### Power Management (PM) Messages (TISCI Protocol)

Based on `packages/ti/drv/sciclient/soc/sysfw/.../2_tisci_msgs/pm/` documentation.

#### Device Power State Messages (TISCI Protocol)

Based on `packages/ti/drv/sciclient/soc/sysfw/.../2_tisci_msgs/pm/devices.rst.txt`

##### TISCI_MSG_SET_DEVICE (0x0200)

Request a device state to be set.

```c
struct tisci_msg_set_device_req {
    struct tisci_header hdr;
    uint32_t id;            // Device ID (e.g., TISCI_DEV_UART0)
    uint32_t reserved;
    uint8_t state;          // Requested state
    uint32_t flags;         // Control flags
} __attribute__((__packed__));

struct tisci_msg_set_device_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

**Device States:**
| State | Value | Description |
|-------|-------|-------------|
| `TISCI_MSG_VALUE_DEVICE_SW_STATE_AUTO_OFF` | 0 | Allow automatic power-off when not in use |
| `TISCI_MSG_VALUE_DEVICE_SW_STATE_RETENTION` | 1 | Retention mode (minimal power) |
| `TISCI_MSG_VALUE_DEVICE_SW_STATE_ON` | 2 | Fully powered on and operational |

**Flags:**
- `TISCI_MSG_FLAG_DEVICE_WAKE_ENABLED` - Keep powered during system sleep
- `TISCI_MSG_FLAG_DEVICE_RESET_ISO` - Reset isolation control
- `TISCI_MSG_FLAG_DEVICE_EXCLUSIVE` - Exclusive access (no sharing)

**Note (J7 devices)**: For MCU1_0 and MCU1_1 devices, this message is forwarded to TIFS instead of DM/SCISERVER.

##### TISCI_MSG_GET_DEVICE (0x0201)

Retrieve device hardware state information.

```c
struct tisci_msg_get_device_req {
    struct tisci_header hdr;
    uint32_t id;            // Device ID
} __attribute__((__packed__));

struct tisci_msg_get_device_resp {
    struct tisci_header hdr;
    uint32_t context_loss_count;    // Number of context losses
    uint32_t resets;                // Current reset state
    uint8_t programmed_state;       // Programmed SW state
    uint8_t current_state;          // Actual HW state
} __attribute__((__packed__));
```

**Hardware States:**
- `TISCI_MSG_VALUE_DEVICE_HW_STATE_OFF` (0) - Device is off
- `TISCI_MSG_VALUE_DEVICE_HW_STATE_ON` (1) - Device is on
- `TISCI_MSG_VALUE_DEVICE_HW_STATE_TRANS` (2) - In transition

##### TISCI_MSG_SET_DEVICE_RESETS (0x0202)

Control device reset signals.

```c
struct tisci_msg_set_device_resets_req {
    struct tisci_header hdr;
    uint32_t id;            // Device ID
    uint32_t resets;        // Reset bit field (1=assert, 0=deassert)
} __attribute__((__packed__));

struct tisci_msg_set_device_resets_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

**Standard Reset Bits:**
- **Bit 0**: PSC local reset (LRST)
- **Bit 1**: PSC module reset (MRST)

**Usage**: Required for processors (DSP, ICSS, R5F) - assert resets, load firmware, release resets in proper order.

#### Clock Control Messages (TISCI Protocol)

Based on `packages/ti/drv/sciclient/soc/sysfw/.../2_tisci_msgs/pm/clocks.rst.txt`

##### TISCI_MSG_SET_CLOCK (0x0100)

Setup a device clock's state.

```c
struct tisci_msg_set_clock_req {
    struct tisci_header hdr;
    uint32_t device;        // Device ID
    uint8_t clk;            // Clock ID (or 255 for large index)
    uint8_t request_state;  // Requested state
    uint32_t flags;         // Control flags
    uint32_t clk32;         // Actual clock index if clk==255
} __attribute__((__packed__));

struct tisci_msg_set_clock_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

**Clock States:**
- `TISCI_MSG_VALUE_CLOCK_SW_STATE_UNREQ` (0) - No request
- `TISCI_MSG_VALUE_CLOCK_SW_STATE_AUTO` (1) - Auto-managed
- `TISCI_MSG_VALUE_CLOCK_SW_STATE_REQ` (2) - Request clock on

**Flags:**
- `TISCI_MSG_FLAG_CLOCK_ALLOW_SSC` - Allow spread spectrum clocking
- `TISCI_MSG_FLAG_CLOCK_ALLOW_FREQ_CHANGE` - Allow frequency change while enabled
- `TISCI_MSG_FLAG_CLOCK_INPUT_TERM` - Termination for input clocks

**Large Clock Index Support** (ABI 2.6+): If clock index ≥ 255, set `clk=255` and put actual value in `clk32`.

##### TISCI_MSG_GET_CLOCK (0x0101)

Get clock state information.

```c
struct tisci_msg_get_clock_req {
    struct tisci_header hdr;
    uint32_t device;        // Device ID
    uint8_t clk;            // Clock ID (or 255 for large index)
    uint32_t clk32;         // Actual clock index if clk==255
} __attribute__((__packed__));

struct tisci_msg_get_clock_resp {
    struct tisci_header hdr;
    uint8_t programmed_state;   // Programmed SW state
    uint8_t current_state;      // Actual HW state
} __attribute__((__packed__));
```

**Hardware States:**
- `TISCI_MSG_VALUE_CLOCK_HW_STATE_NOT_READY` (0) - Clock not ready
- `TISCI_MSG_VALUE_CLOCK_HW_STATE_READY` (1) - Clock ready

##### TISCI_MSG_SET_CLOCK_PARENT (0x0102)

Select clock source from mux options.

```c
struct tisci_msg_set_clock_parent_req {
    struct tisci_header hdr;
    uint32_t device;        // Device ID
    uint8_t clk;            // Clock ID (or 255 for large index)
    uint8_t parent;         // Parent clock ID (or 255 for large index)
    uint32_t clk32;         // Actual clock index if clk==255
    uint32_t parent32;      // Actual parent index if parent==255
} __attribute__((__packed__));

struct tisci_msg_set_clock_parent_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

**Note**: Parent value refers to the device clock ID of the parent (not TRM mux index).

##### TISCI_MSG_GET_CLOCK_PARENT (0x0103)

Query current clock parent.

```c
struct tisci_msg_get_clock_parent_req {
    struct tisci_header hdr;
    uint32_t device;        // Device ID
    uint8_t clk;            // Clock ID (or 255 for large index)
    uint32_t clk32;         // Actual clock index if clk==255
} __attribute__((__packed__));

struct tisci_msg_get_clock_parent_resp {
    struct tisci_header hdr;
    uint8_t parent;         // Parent clock ID (or 255 for large index)
    uint32_t parent32;      // Actual parent index if parent==255
} __attribute__((__packed__));
```

##### TISCI_MSG_GET_NUM_CLOCK_PARENTS (0x0104)

Query number of available clock parents for a mux.

```c
struct tisci_msg_get_num_clock_parents_req {
    struct tisci_header hdr;
    uint32_t device;        // Device ID
    uint8_t clk;            // Clock ID (or 255 for large index)
    uint32_t clk32;         // Actual clock index if clk==255
} __attribute__((__packed__));

struct tisci_msg_get_num_clock_parents_resp {
    struct tisci_header hdr;
    uint8_t num_parents;    // Number of parents (or 255 if >=255)
    uint32_t num_parents32; // Actual count if num_parents==255
} __attribute__((__packed__));
```

##### TISCI_MSG_SET_FREQ (0x010C)

Set clock frequency.

```c
struct tisci_msg_set_freq_req {
    struct tisci_header hdr;
    uint32_t device;        // Device ID
    uint8_t clk;            // Clock ID (or 255 for large index)
    uint64_t min_freq_hz;   // Minimum acceptable frequency
    uint64_t target_freq_hz;// Target frequency
    uint64_t max_freq_hz;   // Maximum acceptable frequency
    uint32_t clk32;         // Actual clock index if clk==255
} __attribute__((__packed__));

struct tisci_msg_set_freq_resp {
    struct tisci_header hdr;
    uint64_t freq_hz;       // Actual frequency set
} __attribute__((__packed__));
```

**Notes:**
- Automatically done by firmware in most cases
- Fails on enabled clock unless `TISCI_MSG_FLAG_CLOCK_ALLOW_FREQ_CHANGE` is set
- For SoC input clocks: Setting freq informs firmware of external clock frequency
- Setting frequency to 0 indicates clock is disabled

##### TISCI_MSG_QUERY_FREQ (0x010D)

Query best achievable frequency without actually setting it.

```c
struct tisci_msg_query_freq_req {
    struct tisci_header hdr;
    uint32_t device;        // Device ID
    uint8_t clk;            // Clock ID (or 255 for large index)
    uint64_t min_freq_hz;   // Minimum acceptable frequency
    uint64_t target_freq_hz;// Target frequency
    uint64_t max_freq_hz;   // Maximum acceptable frequency
    uint32_t clk32;         // Actual clock index if clk==255
} __attribute__((__packed__));

struct tisci_msg_query_freq_resp {
    struct tisci_header hdr;
    uint64_t freq_hz;       // Best achievable frequency
} __attribute__((__packed__));
```

**Note**: Snapshot view only - another core might change configuration before SET_FREQ is called.

##### TISCI_MSG_GET_FREQ (0x010E)

Get current clock frequency.

```c
struct tisci_msg_get_freq_req {
    struct tisci_header hdr;
    uint32_t device;        // Device ID
    uint8_t clk;            // Clock ID (or 255 for large index)
    uint32_t clk32;         // Actual clock index if clk==255
} __attribute__((__packed__));

struct tisci_msg_get_freq_resp {
    struct tisci_header hdr;
    uint64_t freq_hz;       // Current frequency
} __attribute__((__packed__));
```

#### System Reset Messages (TISCI Protocol)

Based on `packages/ti/drv/sciclient/soc/sysfw/.../2_tisci_msgs/pm/sysreset.rst.txt`

##### TISCI_MSG_SYS_RESET (0x0020)

Request software warm reset of a domain.

```c
struct tisci_msg_sys_reset_req {
    struct tisci_header hdr;
    uint16_t domain;        // Domain to reset (0=compatibility/default)
} __attribute__((__packed__));

struct tisci_msg_sys_reset_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

**Usage:**
- Warm reset brings device/domain to known state
- Domain definition varies by SoC
- Some domains may trigger system-wide reset
- After reset, must resend board configuration (PM, RM, Security)

**Notes:**
- **AM62x, AM64x, AM62Ax, AM62Px, J722S, AM275x**: Domain parameter unused; results in system-wide warm reset (or MAIN domain reset if MCU isolation enabled)
- **Empty domain parameter**: Uses `DOMGRP_COMPATIBILITY` for backward compatibility

#### Low Power Mode (LPM) APIs

**Applicable to**: AM62x, AM62Ax, AM62Px, J7200, J784S4

Low Power Mode messages allow the SoC to enter various power-saving states and manage wake-up behavior.

##### Supported Low Power Modes

| Mode | Devices | Description |
|------|---------|-------------|
| `TISCI_MSG_VALUE_SLEEP_MODE_DEEP_SLEEP` | AM62x, AM62Ax, AM62Px | Deepest sleep, longest resume time |
| `TISCI_MSG_VALUE_SLEEP_MODE_MCU_ONLY` | AM62x, AM62Ax, AM62Px | Main domain off, MCU domain active |
| `TISCI_MSG_VALUE_SLEEP_MODE_IO_ONLY_PLUS_DDR` | AM62Ax, AM62Px | I/O and DDR remain functional |
| `TISCI_MSG_VALUE_SLEEP_MODE_PARTIAL_IO` | AM62x, AM62Ax, AM62Px | Partial I/O retention |
| `TISCI_MSG_VALUE_SLEEP_MODE_STANDBY` | None currently | Reserved for future use |
| `TISCI_MSG_VALUE_SLEEP_MODE_SOC_OFF` | J7200, J784S4 | SoC power off |

##### TISCI_MSG_PREPARE_SLEEP (0x0300)

Prepare the SoC for entering a low power mode.

```c
struct tisci_msg_prepare_sleep_req {
    struct tisci_header hdr;
    uint8_t mode;           // Target low power mode
    uint32_t ctx_lo;        // Context save address (low 32 bits)
    uint32_t ctx_hi;        // Context save address (high 32 bits)
    uint8_t debug_flags;    // Debug configuration
} __attribute__((__packed__));

struct tisci_msg_prepare_sleep_resp {
    struct tisci_header hdr;
    uint32_t ctx_lo;        // Actual context address used (low)
    uint32_t ctx_hi;        // Actual context address used (high)
} __attribute__((__packed__));
```

**Usage**: Call before `TISCI_MSG_ENTER_SLEEP` to allow DMSC to prepare system state.

##### TISCI_MSG_ENTER_SLEEP (0x0301)

Enter the prepared low power mode.

```c
struct tisci_msg_enter_sleep_req {
    struct tisci_header hdr;
} __attribute__((__packed__));

struct tisci_msg_enter_sleep_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

**Note**:
- Must call `TISCI_MSG_PREPARE_SLEEP` first
- **Secure queue only** - must be sent via secure proxy thread
- SoC enters low power mode after this message

##### TISCI_MSG_LPM_WAKE_REASON (0x0306)

Get wake-up source and pin information.

```c
struct tisci_msg_lpm_wake_reason_req {
    struct tisci_header hdr;
} __attribute__((__packed__));

struct tisci_msg_lpm_wake_reason_resp {
    struct tisci_header hdr;
    uint8_t mode;           // Last entered low power mode
    uint32_t timestamp;     // Wake timestamp
    uint8_t wkup_source;    // Wake source ID (see table below)
    uint8_t wkup_pin;       // Wake pin (pad number)
} __attribute__((__packed__));
```

**Wake Sources**:
| Source      | ID   | Description      |
|-------------|------|------------------|
| WKUP_I2C0   | 0x00 | I2C0 wake event  |
| WKUP_UART0  | 0x10 | UART0 wake event |
| MCU_GPIO0   | 0x20 | GPIO wake event  |
| WKUP_TIMER0 | 0x40 | Timer 0 wake     |
| WKUP_TIMER1 | 0x41 | Timer 1 wake     |
| WKUP_RTC0   | 0x50 | RTC wake         |
| RESET       | 0x60 | Reset wake       |
| USB0        | 0x70 | USB port 0       |
| USB1        | 0x71 | USB port 1       |
| MAIN_IO     | 0x80 | Main domain I/O  |
| MCU_IO      | 0x81 | MCU domain I/O   |
| CAN_IO      | 0x82 | CAN I/O          |
| MCU_IPC     | 0x90 | IPC wake event   |
| INVALID     | 0xFF | Invalid/unknown  |

##### TISCI_MSG_SET_IO_ISOLATION (0x0307)

Enable/disable I/O isolation for low power modes.

```c
struct tisci_msg_set_io_isolation_req {
    struct tisci_header hdr;
    uint8_t state;          // TISCI_MSG_VALUE_IO_ENABLE or IO_DISABLE
} __attribute__((__packed__));

struct tisci_msg_set_io_isolation_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

##### TISCI_MSG_LPM_SET_DEVICE_CONSTRAINT (0x0309)

Set constraint to prevent device power-off in low power mode.

```c
struct tisci_msg_lpm_set_device_constraint_req {
    struct tisci_header hdr;
    uint32_t devid;         // Device ID to constrain
    uint8_t state;          // STATE_SET or STATE_CLEAR
    uint8_t mode;           // Low power mode to constrain
} __attribute__((__packed__));

struct tisci_msg_lpm_set_device_constraint_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

**Note**: Setting a constraint on DDR ensures DDR remains functional in the selected low power mode. All constraints auto-clear after resume.

##### TISCI_MSG_LPM_SET_LATENCY_CONSTRAINT (0x030A)

Set maximum acceptable resume latency.

```c
struct tisci_msg_lpm_set_latency_constraint_req {
    struct tisci_header hdr;
    uint8_t latency_constraint;  // Resume latency in ms
    uint8_t state;                // STATE_SET or STATE_CLEAR
} __attribute__((__packed__));

struct tisci_msg_lpm_set_latency_constraint_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

**Latency Table**:
| Mode | Min (ms) | Max (ms) |
|------|----------|----------|
| MCU_ONLY | 10 | 100 |
| DEEP_SLEEP | 101 | 250 |
| DEEPEST (IO_ONLY_PLUS_DDR) | 251 | No limit |

##### TISCI_MSG_LPM_GET_NEXT_SYS_MODE (0x030D)

Query the upcoming system power mode.

```c
struct tisci_msg_lpm_get_next_sys_mode_req {
    struct tisci_header hdr;
} __attribute__((__packed__));

struct tisci_msg_lpm_get_next_sys_mode_resp {
    struct tisci_header hdr;
    uint8_t mode;           // Next system mode (0x00-0x04, 0xFE=not selected)
} __attribute__((__packed__));
```

##### TISCI_MSG_LPM_ABORT (0x0311)

Abort current low power mode entry if error occurs.

```c
struct tisci_msg_lpm_abort_req {
    struct tisci_header hdr;
} __attribute__((__packed__));

struct tisci_msg_lpm_abort_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

##### TISCI_MSG_LPM_ENCRYPT (0x030F) / DECRYPT (0x0310)

**J7200, J784S4 only**: Encrypt/decrypt ATF binary for low power mode transitions.

```c
struct tisci_msg_enc_req {
    struct tisci_header hdr;
    uint32_t addr;          // Source address
    uint32_t size;          // Data size
    uint32_t dest_addr;     // Destination address
    uint8_t key[32];        // AES-256 key
    uint8_t iv[16];         // Initialization vector
} __attribute__((__packed__));

struct tisci_msg_enc_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

### Resource Management (RM) Messages (TISCI Protocol)

Based on `packages/ti/drv/sciclient/soc/sysfw/.../2_tisci_msgs/rm/` documentation.

#### Interrupt Routing (TISCI Protocol)

Based on `rm_irq.rst.txt`

##### TISCI_MSG_RM_IRQ_SET (0x1000)

Configure interrupt routes between peripherals and host processors.

```c
struct tisci_msg_rm_irq_set_req {
    struct tisci_header hdr;
    uint32_t valid_params;      // Bit field indicating which parameters are valid
    uint16_t src_id;            // Source device ID
    uint16_t src_index;         // Source IRQ output index
    uint16_t dst_id;            // Destination device ID (interrupt router/aggregator)
    uint16_t dst_host_irq;      // Destination IRQ input number
    uint16_t ia_id;             // Interrupt aggregator device ID
    uint16_t vint;              // Virtual interrupt number
    uint16_t global_event;      // Global event number
    uint8_t vint_status_bit_index; // Status bit within VINT
    uint8_t secondary_host;     // Secondary host for shared resources
} __attribute__((__packed__));

struct tisci_msg_rm_irq_set_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

**valid_params Bit Mappings:**
| Bit | Parameter | Description |
|-----|-----------|-------------|
| 0 | dst_id | Destination device ID |
| 1 | dst_host_irq | Destination IRQ number |
| 2 | ia_id | Interrupt aggregator ID |
| 3 | vint | Virtual interrupt |
| 4 | global_event | Global event number |
| 5 | vint_status_bit_index | Status bit index |
| 31 | secondary_host | Secondary host ID |

**Configuration Modes:**

1. **Interrupt Router Mux**: Set bits 0,1 (dst_id, dst_host_irq)
   - Routes IR input (src_index) to IR output (dst_host_irq)
   - Both src_id and dst_id must be the IR device ID

2. **Event to VINT Mapping**: Set bits 2,3,4,5 (ia_id, vint, global_event, vint_status_bit_index)
   - Maps peripheral event to interrupt aggregator VINT status bit
   - Also programs OES register (for RA, UDMAP, Proxy)

3. **OES Register Only**: Set bit 4 (global_event)
   - Programs output event steering register
   - Used for UDMAP triggers and non-interrupt events

##### TISCI_MSG_RM_IRQ_RELEASE (0x1001)

Release/clear interrupt route configuration.

```c
struct tisci_msg_rm_irq_release_req {
    struct tisci_header hdr;
    uint32_t valid_params;      // Same bit mappings as SET
    uint16_t src_id;
    uint16_t src_index;
    uint16_t dst_id;
    uint16_t dst_host_irq;
    uint16_t ia_id;
    uint16_t vint;
    uint16_t global_event;
    uint8_t vint_status_bit_index;
    uint8_t secondary_host;
} __attribute__((__packed__));

struct tisci_msg_rm_irq_release_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

**Usage**: Automatically traces and frees all interrupt router and aggregator resources in the route.

#### PSI-L (Packet Streaming Interface - Link) Messages

Based on `rm_psil.rst.txt`

PSI-L provides real-time, peer-to-peer data movement between peripherals and DMA controllers.

##### TISCI_MSG_RM_PSIL_PAIR (0x1280)

Pair a PSI-L source thread to a destination thread.

```c
struct tisci_msg_rm_psil_pair_req {
    struct tisci_header hdr;
    uint32_t nav_id;            // Navigator subsystem ID
    uint32_t src_thread;        // Source thread ID
    uint32_t dst_thread;        // Destination thread ID
} __attribute__((__packed__));

struct tisci_msg_rm_psil_pair_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

**Usage**: Creates peer-to-peer data path (e.g., UART TX → UDMA TX channel).

##### TISCI_MSG_RM_PSIL_UNPAIR (0x1281)

Unpair a PSI-L thread pair.

```c
struct tisci_msg_rm_psil_unpair_req {
    struct tisci_header hdr;
    uint32_t nav_id;
    uint32_t src_thread;
    uint32_t dst_thread;
} __attribute__((__packed__));

struct tisci_msg_rm_psil_unpair_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

##### TISCI_MSG_RM_PSIL_READ (0x1282) / WRITE (0x1283)

Read/write PSI-L configuration registers.

```c
struct tisci_msg_rm_psil_read_req {
    struct tisci_header hdr;
    uint32_t nav_id;
    uint32_t thread;            // Thread ID to read
    uint16_t taddr;             // Configuration address offset
} __attribute__((__packed__));

struct tisci_msg_rm_psil_read_resp {
    struct tisci_header hdr;
    uint32_t data;              // Register value
} __attribute__((__packed__));

struct tisci_msg_rm_psil_write_req {
    struct tisci_header hdr;
    uint32_t nav_id;
    uint32_t thread;
    uint16_t taddr;
    uint32_t data;              // Value to write
} __attribute__((__packed__));
```

#### Ring Accelerator Messages

Based on `rm_ra.rst.txt`

##### TISCI_MSG_RM_RING_CFG (0x1110)

Configure a ring accelerator ring.

```c
struct tisci_msg_rm_ring_cfg_req {
    struct tisci_header hdr;
    uint32_t valid_params;      // Bit field for valid parameters
    uint16_t nav_id;            // Navigator subsystem ID
    uint16_t index;             // Ring index
    uint32_t addr_lo;           // Ring base address (low 32 bits)
    uint32_t addr_hi;           // Ring base address (high 32 bits)
    uint32_t count;             // Number of ring elements
    uint8_t mode;               // Ring mode
    uint8_t size;               // Element size (0-3: 4/8/16/32 bytes, 4-7: 64/128/256 bytes)
    uint8_t order_id;           // Bus order ID
    uint16_t virtid;            // Virtual ID for MMU/SMMU
    uint8_t asel;               // Address select (0=phys, others=virtual)
} __attribute__((__packed__));

struct tisci_msg_rm_ring_cfg_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

**Ring Modes:**
- `RING_MODE_RING` (0) - Ring mode
- `RING_MODE_MESSAGE` (1) - Message mode
- `RING_MODE_CREDENTIALS` (2) - Credentials mode
- `RING_MODE_QM` (3) - Queue manager mode

##### TISCI_MSG_RM_RING_MON_CFG (0x1120)

Configure ring monitor for event generation.

```c
struct tisci_msg_rm_ring_mon_cfg_req {
    struct tisci_header hdr;
    uint32_t valid_params;
    uint16_t nav_id;
    uint16_t index;             // Ring monitor index
    uint8_t mode;               // Monitor mode (0=disabled, 1=threshold, 2=watermark)
    uint16_t queue;             // Queue/ring to monitor
    uint8_t source;             // Event source
    uint32_t data0;             // Mode-specific data (threshold/watermark value)
    uint32_t data1;             // Mode-specific data
} __attribute__((__packed__));

struct tisci_msg_rm_ring_mon_cfg_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

#### UDMAP Channel Configuration Messages

Based on `rm_udmap.rst.txt`

##### TISCI_MSG_RM_UDMAP_TX_CH_CFG (0x1205)

Configure a UDMAP TX (transmit) channel.

```c
struct tisci_msg_rm_udmap_tx_ch_cfg_req {
    struct tisci_header hdr;
    uint32_t valid_params;      // Extensive bit field (32 bits)
    uint16_t nav_id;
    uint16_t index;             // TX channel index
    uint8_t tx_pause_on_err;    // Pause on error
    uint8_t tx_filt_einfo;      // Filter extended info
    uint8_t tx_filt_pswords;    // Filter PS words
    uint8_t tx_atype;           // Address type
    uint8_t tx_chan_type;       // Channel type (normal, h/w triggered)
    uint8_t tx_supr_tdpkt;      // Suppress teardown packet
    uint16_t tx_fetch_size;     // Descriptor fetch size
    uint8_t tx_credit_count;    // Credit count
    uint16_t fdepth;            // FIFO depth
    uint8_t tx_burst_size;      // Burst size
    uint8_t tx_tdtype;          // Teardown type
    uint8_t extended_ch_type;   // Extended channel type
    // Many more fields...
} __attribute__((__packed__));

struct tisci_msg_rm_udmap_tx_ch_cfg_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

**Channel Types:**
- Normal packet mode
- Block copy mode
- Third-party (external trigger)

##### TISCI_MSG_RM_UDMAP_RX_CH_CFG (0x1215)

Configure a UDMAP RX (receive) channel.

```c
struct tisci_msg_rm_udmap_rx_ch_cfg_req {
    struct tisci_header hdr;
    uint32_t valid_params;
    uint16_t nav_id;
    uint16_t index;             // RX channel index
    uint16_t rx_fetch_size;     // Descriptor fetch size
    uint16_t rxcq_qnum;         // Completion queue number
    uint8_t rx_priority;        // Channel priority
    uint8_t rx_qos;             // QoS setting
    uint8_t rx_orderid;         // Order ID
    uint8_t rx_sched_priority;  // Scheduler priority
    uint16_t flowid_start;      // Flow ID range start
    uint16_t flowid_cnt;        // Number of flows
    uint8_t rx_pause_on_err;
    uint8_t rx_atype;
    uint8_t rx_chan_type;
    uint8_t rx_ignore_short;
    uint8_t rx_ignore_long;
    uint8_t rx_burst_size;
    // More fields...
} __attribute__((__packed__));

struct tisci_msg_rm_udmap_rx_ch_cfg_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

##### TISCI_MSG_RM_UDMAP_FLOW_CFG (0x1230)

Configure a UDMAP RX flow.

```c
struct tisci_msg_rm_udmap_flow_cfg_req {
    struct tisci_header hdr;
    uint32_t valid_params;
    uint16_t nav_id;
    uint16_t flow_index;
    uint8_t rx_einfo_present;   // Extended info present
    uint8_t rx_psinfo_present;  // Protocol-specific info present
    uint8_t rx_error_handling;  // Error handling mode
    uint8_t rx_desc_type;       // Descriptor type
    uint16_t rx_ps_location;    // PS data location
    uint16_t rx_src_tag_hi;     // Source tag high
    uint16_t rx_src_tag_lo;     // Source tag low
    uint16_t rx_dest_tag_hi;    // Destination tag high
    uint16_t rx_dest_tag_lo;    // Destination tag low
    uint8_t rx_src_tag_hi_sel;  // Source tag select
    uint8_t rx_src_tag_lo_sel;
    uint8_t rx_dest_tag_hi_sel; // Dest tag select
    uint8_t rx_dest_tag_lo_sel;
    uint16_t rx_fdq0_sz0_qnum;  // Free descriptor queue 0, size 0
    uint16_t rx_fdq1_qnum;      // Free descriptor queue 1
    uint16_t rx_fdq2_qnum;      // Free descriptor queue 2
    uint16_t rx_fdq3_qnum;      // Free descriptor queue 3
    uint8_t rx_size_thresh_en;  // Size threshold enable
    // More fields for multiple buffer pools...
} __attribute__((__packed__));

struct tisci_msg_rm_udmap_flow_cfg_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

**RX Flow**: Defines how received packets are processed and queued.

##### TISCI_MSG_RM_UDMAP_FLOW_SIZE_THRESH_CFG (0x1231)

Configure size thresholds for RX flow buffer selection.

##### TISCI_MSG_RM_UDMAP_FLOW_DELEGATE (0x1234)

Delegate flow to another host for management.

##### TISCI_MSG_RM_UDMAP_GCFG_CFG (0x1240)

Configure global UDMAP settings.

#### Secure Proxy RM Messages

Based on `rm_proxy.rst.txt`

##### TISCI_MSG_RM_PROXY_CFG (0x1300)

Configure secure proxy resources.

```c
struct tisci_msg_rm_proxy_cfg_req {
    struct tisci_header hdr;
    uint32_t valid_params;
    uint16_t nav_id;
    uint16_t index;             // Proxy index
} __attribute__((__packed__));

struct tisci_msg_rm_proxy_cfg_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

**Note**: Proxy thread assignment is typically done via board configuration, not runtime messages.

---

### Resource Management (RM) Wrapper APIs

The following are SCICLIENT FL (Function Layer) wrapper APIs that simplify using the TISCI RM protocol messages above.

#### Interrupt Routing

```c
int32_t Sciclient_rmIrqSet(
    const struct tisci_msg_rm_irq_set_req *req,
    const Sciclient_ReqPrm_t *reqPrm,
    Sciclient_RespPrm_t *respPrm
);
```

**Request Structure:**
```c
struct tisci_msg_rm_irq_set_req {
    struct tisci_header hdr;
    uint32_t valid_params;      // Which params are valid
    uint16_t src_id;            // Source device ID
    uint16_t src_index;         // Source IRQ index
    uint16_t dst_id;            // Destination device ID (core)
    uint16_t dst_host_irq;      // Destination IRQ number
    uint16_t ia_id;             // Interrupt aggregator ID
    uint16_t vint;              // Virtual interrupt number
    uint16_t global_event;      // Global event number
    uint8_t  vint_status_bit_index; // Status bit in VINT
    uint8_t  secondary_host;    // Secondary host for shared IRQ
} __attribute__((__packed__));
```

**Example:**
```c
// Route UART0 RX interrupt to MCU R5F
struct tisci_msg_rm_irq_set_req req = {0};
req.valid_params = TISCI_MSG_VALUE_RM_DST_ID_VALID |
                   TISCI_MSG_VALUE_RM_DST_HOST_IRQ_VALID;
req.src_id = TISCI_DEV_UART0;
req.src_index = 0;  // RX interrupt
req.dst_id = TISCI_DEV_R5FSS0_CORE0;
req.dst_host_irq = 100;  // GIC/VIM IRQ number

Sciclient_rmIrqSet(&req, &reqPrm, &respPrm);
```

#### UDMA Channel Configuration

```c
int32_t Sciclient_rmUdmapTxChCfg(
    const struct tisci_msg_rm_udmap_tx_ch_cfg_req *req,
    const Sciclient_ReqPrm_t *reqPrm,
    Sciclient_RespPrm_t *respPrm
);
```

**TX Channel Config:**
```c
struct tisci_msg_rm_udmap_tx_ch_cfg_req {
    struct tisci_header hdr;
    uint32_t valid_params;
    uint16_t nav_id;        // NAVSS/UDMAP instance
    uint16_t index;         // Channel number
    uint8_t  tx_pause_on_err;
    uint8_t  tx_filt_einfo;
    uint8_t  tx_filt_pswords;
    uint8_t  tx_atype;
    uint8_t  tx_chan_type;
    uint8_t  tx_supr_tdpkt;
    uint16_t tx_fetch_size;
    uint8_t  tx_credit_count;
    uint16_t fdepth;
    uint8_t  tx_burst_size;
    // ... many more fields
} __attribute__((__packed__));
```

#### Ring Accelerator Configuration

```c
int32_t Sciclient_rmRingCfg(
    const struct tisci_msg_rm_ring_cfg_req *req,
    const Sciclient_ReqPrm_t *reqPrm,
    Sciclient_RespPrm_t *respPrm
);
```

**Ring Config:**
```c
struct tisci_msg_rm_ring_cfg_req {
    struct tisci_header hdr;
    uint32_t valid_params;
    uint16_t nav_id;
    uint16_t index;         // Ring number
    uint32_t addr_lo;       // Ring memory address (low 32-bits)
    uint32_t addr_hi;       // Ring memory address (high 32-bits)
    uint32_t count;         // Number of ring elements
    uint8_t  mode;          // Ring mode
    uint8_t  size;          // Element size
    uint8_t  order_id;      // Bus order ID
    uint16_t virtid;        // Virtual ID for isolation
    uint8_t  asel;          // Address select
} __attribute__((__packed__));
```

### Security Messages (TISCI Protocol)

Based on `packages/ti/drv/sciclient/soc/sysfw/.../2_tisci_msgs/security/` documentation.

#### Firewall Configuration Messages (TISCI Protocol)

Based on `firewall_api.rst.txt`

Firewalls protect memory regions and peripherals by controlling access based on host ID and privilege level.

##### TISCI_MSG_SET_FWL_REGION (0x9000)

Configure a firewall region.

```c
struct tisci_msg_fwl_set_firewall_region_req {
    struct tisci_header hdr;
    uint16_t fwl_id;            // Firewall ID
    uint16_t region;            // Region index (0-7, varies by firewall)
    uint32_t n_permission_regs; // Number of permission registers to configure
    uint32_t control;           // Region control settings
    uint32_t permissions[3];    // Permission registers for priv_id groups
    uint64_t start_address;     // Protected region start address
    uint64_t end_address;       // Protected region end address (inclusive)
} __attribute__((__packed__));

struct tisci_msg_fwl_set_firewall_region_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

**Permissions Encoding** (each bit represents a priv_id):
- Bit 0 = Read permission
- Bit 1 = Write permission
- Bit 2 = Cacheable permission
- Bit 3 = Debug permission

**Control Field:**
- Background region select
- Lock enable
- Cache mode

##### TISCI_MSG_GET_FWL_REGION (0x9001)

Query firewall region configuration.

```c
struct tisci_msg_fwl_get_firewall_region_req {
    struct tisci_header hdr;
    uint16_t fwl_id;
    uint16_t region;
    uint32_t n_permission_regs;
} __attribute__((__packed__));

struct tisci_msg_fwl_get_firewall_region_resp {
    struct tisci_header hdr;
    uint16_t fwl_id;
    uint16_t region;
    uint32_t n_permission_regs;
    uint32_t control;
    uint32_t permissions[3];
    uint64_t start_address;
    uint64_t end_address;
} __attribute__((__packed__));
```

##### TISCI_MSG_CHANGE_FWL_OWNER (0x9002)

Transfer firewall ownership to another host.

```c
struct tisci_msg_fwl_change_owner_info_req {
    struct tisci_header hdr;
    uint16_t fwl_id;
    uint16_t region;
    uint8_t owner_index;        // New owner index (0-2)
    uint8_t owner_privid;       // New owner privilege ID
    uint16_t owner_permission_bits; // Permission bits for new owner
} __attribute__((__packed__));

struct tisci_msg_fwl_change_owner_info_resp {
    struct tisci_header hdr;
    uint16_t fwl_id;
    uint16_t region;
    uint8_t owner_index;
    uint8_t owner_privid;
    uint16_t owner_permission_bits;
} __attribute__((__packed__));
```

#### Processor Boot Control Messages (TISCI Protocol)

Based on `PROC_BOOT.rst.txt`

These messages control processor lifecycle: request ownership, authenticate images, configure, and boot.

##### TISCI_MSG_PROC_REQUEST (0xC000)

Request control of a processor.

```c
struct tisci_msg_proc_request_req {
    struct tisci_header hdr;
    uint8_t processor_id;       // Processor to control
} __attribute__((__packed__));

struct tisci_msg_proc_request_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

**Usage**: Must be called before any processor configuration or boot operations.

##### TISCI_MSG_PROC_RELEASE (0xC001)

Release control of a processor.

```c
struct tisci_msg_proc_release_req {
    struct tisci_header hdr;
    uint8_t processor_id;
} __attribute__((__packed__));

struct tisci_msg_proc_release_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

##### TISCI_MSG_PROC_HANDOVER (0xC005)

Handover processor to another host.

```c
struct tisci_msg_proc_handover_req {
    struct tisci_header hdr;
    uint8_t processor_id;
    uint8_t host_id;            // Host to transfer control to
} __attribute__((__packed__));

struct tisci_msg_proc_handover_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

##### TISCI_MSG_PROC_SET_CONFIG (0xC100)

Set processor boot configuration (boot vector, etc.).

```c
struct tisci_msg_set_proc_boot_config_req {
    struct tisci_header hdr;
    uint8_t processor_id;
    uint32_t bootvector_lo;     // Boot vector address (low 32 bits)
    uint32_t bootvector_hi;     // Boot vector address (high 32 bits)
    uint32_t config_flags_1_set;    // Config flags to set
    uint32_t config_flags_1_clear;  // Config flags to clear
} __attribute__((__packed__));

struct tisci_msg_set_proc_boot_config_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

**Config Flags:**
- Processor-specific boot options
- Endianness settings
- Exception handling configuration

##### TISCI_MSG_PROC_SET_CONTROL (0xC101)

Control processor state (reset, halt, run).

```c
struct tisci_msg_set_proc_boot_ctrl_req {
    struct tisci_header hdr;
    uint8_t processor_id;
    uint32_t control_flags_1_set;   // Control flags to set
    uint32_t control_flags_1_clear; // Control flags to clear
} __attribute__((__packed__));

struct tisci_msg_set_proc_boot_ctrl_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

**Control Flags:**
- PROC_BOOT_CTRL_FLAG_R5_CORE_HALT - Hold R5F in halt
- PROC_BOOT_CTRL_FLAG_R5_RESET - Assert reset
- PROC_BOOT_CTRL_FLAG_DSP_CORE_HALT - Hold DSP in halt
- Many processor-specific flags

##### TISCI_MSG_PROC_AUTH_BOOT (0xC120)

Authenticate and optionally boot a processor image.

```c
struct tisci_msg_proc_auth_boot_image_req {
    struct tisci_header hdr;
    uint8_t proc_id;
    uint32_t cert_addr_lo;      // X509 certificate address (low)
    uint32_t cert_addr_hi;      // X509 certificate address (high)
} __attribute__((__packed__));

struct tisci_msg_proc_auth_boot_image_resp {
    struct tisci_header hdr;
    uint32_t image_addr_lo;     // Authenticated image address (low)
    uint32_t image_addr_hi;     // Authenticated image address (high)
    uint32_t image_size;        // Image size in bytes
} __attribute__((__packed__));
```

**Usage:**
1. Load X509-wrapped binary to memory
2. Send PROC_AUTH_BOOT with certificate address
3. TIFS authenticates using ROM-style X509 verification
4. Returns actual image address (after certificate)
5. Optionally boots processor if flags set

**Note**: This is the primary authentication mechanism for processors on HS devices.

##### TISCI_MSG_PROC_GET_STATUS (0xC400)

Get processor status information.

```c
struct tisci_msg_get_proc_boot_status_req {
    struct tisci_header hdr;
    uint8_t processor_id;
} __attribute__((__packed__));

struct tisci_msg_get_proc_boot_status_resp {
    struct tisci_header hdr;
    uint32_t bootvector_lo;
    uint32_t bootvector_hi;
    uint32_t config_flags_1;
    uint32_t control_flags_1;
    uint32_t status_flags_1;    // Current processor status
} __attribute__((__packed__));
```

**Status Flags:**
- Reset status
- Halt status
- Wait for event (WFE/WFI) status
- Processor-specific status information

##### TISCI_MSG_PROC_WAIT_STATUS (0xC401)

Wait for specific processor status conditions.

```c
struct tisci_msg_wait_proc_boot_status_req {
    struct tisci_header hdr;
    uint8_t processor_id;
    uint8_t num_wait_iterations;    // Polling iterations
    uint8_t num_match_iterations;   // Consecutive matches required
    uint8_t delay_per_iteration_us; // Delay between polls (microseconds)
    uint32_t delay_before_iterations_us; // Initial delay
    uint32_t status_flags_1_set_all_wait;    // Flags that must all be set
    uint32_t status_flags_1_set_any_wait;    // Flags where any can be set
    uint32_t status_flags_1_clr_all_wait;    // Flags that must all be clear
    uint32_t status_flags_1_clr_any_wait;    // Flags where any can be clear
} __attribute__((__packed__));

struct tisci_msg_wait_proc_boot_status_resp {
    struct tisci_header hdr;
    uint32_t bootvector_lo;
    uint32_t bootvector_hi;
    uint32_t config_flags_1;
    uint32_t control_flags_1;
    uint32_t status_flags_1;
} __attribute__((__packed__));
```

**Usage**: Wait for processor to enter specific state (e.g., wait for WFI before power-down).

#### OTP Revision Messages (TISCI Protocol)

Based on `otp_revision.rst.txt`

##### TISCI_MSG_WRITE_SWREV (0x9032)

Write software revision to eFuse OTP.

**Usage:**
- **Message Type**: Normal
- **Secure Queue Only?**: Yes

```c
struct tisci_msg_set_swrev_req {
    struct tisci_header hdr;
    uint8_t identifier;     // OTP revision identifier (see tisci_otp_revision_identifier)
} __attribute__((__packed__));

struct tisci_msg_set_swrev_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

**Purpose**: Permanently write software revision to eFuse to prevent rollback attacks.

##### TISCI_MSG_READ_SWREV (0x9033)

Read software revision from eFuse OTP.

**Usage:**
- **Message Type**: Normal
- **Secure Queue Only?**: Yes

```c
struct tisci_msg_get_swrev_req {
    struct tisci_header hdr;
    uint8_t identifier;     // OTP revision identifier
} __attribute__((__packed__));

struct tisci_msg_get_swrev_resp {
    struct tisci_header hdr;
    uint32_t swrev;         // Software revision value
} __attribute__((__packed__));
```

**Note**: SYSFW currently supports reading only SWREV Secure Board Config.

##### TISCI_MSG_READ_KEYCNT_KEYREV (0x9034)

Read key count and key revision from eFuse OTP.

**Usage:**
- **Message Type**: Normal
- **Secure Queue Only?**: Yes

```c
struct tisci_msg_get_keycnt_keyrev_req {
    struct tisci_header hdr;
} __attribute__((__packed__));

struct tisci_msg_get_keycnt_keyrev_resp {
    struct tisci_header hdr;
    uint32_t keycnt;        // Key count
    uint32_t keyrev;        // Key revision
} __attribute__((__packed__));
```

##### TISCI_MSG_WRITE_KEYREV (0x9035)

Write key revision to eFuse OTP.

**Usage:**
- **Message Type**: Normal
- **Secure Queue Only?**: Yes

```c
struct tisci_msg_set_keyrev_req {
    struct tisci_header hdr;
    uint32_t keyrev;        // Key revision value to write
} __attribute__((__packed__));

struct tisci_msg_set_keyrev_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

**Purpose**: Update key revision counter to revoke old keys.

#### Runtime Debug Messages (TISCI Protocol)

Based on `runtime_debug.rst.txt`

**Note**: Applicable to HS devices only. Primary method for JTAG unlock is Secure AP command interface.

##### TISCI_MSG_GET_SOC_UID (0x9021)

Get the unique identifier for the SoC.

**Usage:**
- **Message Type**: Normal
- **Secure Queue Only?**: No
- **Available in GP**: Yes
- **Available in HS-FS**: Yes

```c
struct tisci_msg_get_soc_uid_req {
    struct tisci_header hdr;
} __attribute__((__packed__));

#define UID_LEN_WORDS 4

struct tisci_msg_get_soc_uid_resp {
    struct tisci_header hdr;
    uint32_t uid[UID_LEN_WORDS];  // 128-bit unique device ID
} __attribute__((__packed__));
```

**Purpose**: Extract SOC UID for populating debug unlock certificates. SOC UID is calculated by BOOT ROM and ties debug certificates to specific devices.

##### TISCI_MSG_OPEN_DEBUG_FWLS (0x900C)

Open debug firewalls to unlock JTAG port.

**Usage:**
- **Message Type**: Normal
- **Secure Queue Only?**: Yes
- **Available in GP**: No
- **Available in HS-FS**: No (HS devices only)

```c
struct tisci_msg_open_debug_fwls_req {
    struct tisci_header hdr;
    uint32_t debug_cert_addr_lo;    // Debug certificate address (low 32 bits)
    uint32_t debug_cert_addr_hi;    // Debug certificate address (high 32 bits)
} __attribute__((__packed__));

struct tisci_msg_open_debug_fwls_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

**Purpose**: Provide X509 certificate signed with active root of trust key to unlock JTAG. Certificate must contain SOC UID and debug extension.

##### TISCI_MSG_DISABLE_JTAG_UNLOCK (0x9042)

Permanently disable JTAG unlock by writing to eFuse.

**Usage:**
- **Message Type**: Normal
- **Secure Queue Only?**: Yes
- **Available in GP**: No
- **Available in HS-FS**: No (HS-SE devices only)

```c
struct tisci_msg_disable_jtag_unlock_req {
    struct tisci_header hdr;
} __attribute__((__packed__));

struct tisci_msg_disable_jtag_unlock_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

**Purpose**: Irreversibly disable JTAG unlock capability. Requires disable check flag to be set first (see TISCI_MSG_DISABLE_JTAG_UNLOCK_CHECK).

##### TISCI_MSG_DISABLE_JTAG_UNLOCK_CHECK (0x9043)

Set flag to allow permanent JTAG disable.

**Usage:**
- **Message Type**: Normal
- **Secure Queue Only?**: Yes
- **Available in GP**: No
- **Available in HS-FS**: No

```c
struct tisci_msg_disable_jtag_unlock_check_req {
    struct tisci_header hdr;
    uint8_t check_identifier;   // Check identifier (see tisci_jtag_disable_check_identifier)
} __attribute__((__packed__));

struct tisci_msg_disable_jtag_unlock_check_resp {
    struct tisci_header hdr;
} __attribute__((__packed__));
```

**Purpose**: Safety check before allowing permanent JTAG disable via TISCI_MSG_DISABLE_JTAG_UNLOCK.

#### Security Handover Messages (TISCI Protocol)

Based on `security_handover.rst.txt`

##### TISCI_MSG_SEC_HANDOVER (0x9030)

Perform security handover between boot stages.

**Usage:**
- **Message Type**: Normal
- **Secure Queue Only?**: Yes
- **Available in GP**: Yes
- **Available in HS-FS**: Yes

```c
struct tisci_msg_security_handover_req {
    struct tisci_header hdr;
    // Request structure defined in SYSFW documentation
} __attribute__((__packed__));

struct tisci_msg_security_handover_resp {
    struct tisci_header hdr;
    // Response structure defined in SYSFW documentation
} __attribute__((__packed__));
```

**Purpose**: Transfer security context between boot stages (e.g., ROM to SPL, SPL to U-Boot).

**See Also:**
- User Guide: `6_topic_user_guides/security_handover`
- Board Config: `3_boardcfg/BOARDCFG_SEC` section on `pub_boardcfg_security_handover`

#### Additional Security Messages

**Note**: The following security messages are available but not detailed in this knowledgebase:
- **Extended OTP** (0x9022-0x9026): Read/write/lock OTP rows
- **Crypto/CSP** (0x9040-0x9041): AES encrypt/decrypt operations
- **DKEK/DSMEK** (0x9003-0x9004, 0x9029, 0x9036-0x9038): Derived key management
- **Keyring** (0x9039): Import keys into hardware keyring
- **Keywriter** (0x9031, 0x9045): Program keys to OTP

---

### Security / Firewall Wrapper APIs

The following are SCICLIENT FL (Function Layer) wrapper APIs that simplify using the TISCI Security protocol messages above.

#### Firewall Configuration

```c
int32_t Sciclient_firewallSetRegion(
    const struct tisci_msg_fwl_set_firewall_region_req *req,
    const Sciclient_ReqPrm_t *reqPrm,
    Sciclient_RespPrm_t *respPrm
);
```

**Firewall Request:**
```c
struct tisci_msg_fwl_set_firewall_region_req {
    struct tisci_header hdr;
    uint16_t fwl_id;            // Firewall ID
    uint16_t region;            // Region index (0-7)
    uint32_t n_permission_regs; // Number of permission registers
    uint32_t control;           // Control settings
    uint32_t permissions[3];    // Permission bits for each priv level
    uint64_t start_address;     // Protected region start
    uint64_t end_address;       // Protected region end
} __attribute__((__packed__));
```

**Permissions:**
- Bits define read/write/execute/debug access
- Per privilege level (secure/non-secure, user/supervisor)

#### Processor Boot Control

```c
int32_t Sciclient_procBootRequestProcessor(
    uint8_t processorId,
    uint32_t timeout
);
```

**Example:**
```c
// Request control of C66x DSP 0
Sciclient_procBootRequestProcessor(
    SCICLIENT_PROC_ID_C66SS0_CORE0,
    SCICLIENT_SERVICE_WAIT_FOREVER
);

// Configure processor...

// Set entry point and release from reset
Sciclient_procBootSetProcessorCfg(&cfg, timeout);
Sciclient_procBootSetSequenceCtrl(&ctrl, timeout);
Sciclient_procBootReleaseProcessor(processorId, timeout);
```

### Board Configuration APIs

```c
int32_t Sciclient_boardCfg(
    const Sciclient_BoardCfgPrms_t *pInPrms
);
```

Board configuration defines system-wide settings sent to DMSC during initialization:

**PM Board Config:**
```c
struct tisci_msg_board_config_pm_req {
    struct tisci_header hdr;
    tisci_boardcfg_pm boardcfg;  // Clock settings, power domains
} __attribute__((__packed__));
```

**RM Board Config:**
```c
struct tisci_msg_board_config_rm_req {
    struct tisci_header hdr;
    tisci_boardcfg_rm boardcfg;  // Resource allocations per host
} __attribute__((__packed__));
```

**Security Board Config:**
```c
struct tisci_msg_board_config_security_req {
    struct tisci_header hdr;
    tisci_boardcfg_security boardcfg;  // Firewall policies, SA2UL config
} __attribute__((__packed__));
```

---

## Implementation Deep Dive

### Sequence ID Management

**Problem:** Multiple concurrent requests need unique tracking.

**Solution:** Circular sequence ID counter (0-255) with semaphore array.

```c
#define SCICLIENT_MAX_QUEUE_SIZE (7U)

// For each sequence ID, we have:
SemaphoreP_Handle semHandles[SCICLIENT_MAX_QUEUE_SIZE];
uint8_t respMsgArr[SCICLIENT_MAX_QUEUE_SIZE][MAX_MSG_SIZE];
```

**Sequence ID Allocation:**
```c
seqId = (pHandle->currSeqId++) % SCICLIENT_MAX_QUEUE_SIZE;
```

**Why 7?**
- Limited by number of secure proxy TX threads allocated to each host
- Most hosts have 1-2 TX threads with max 2-4 outstanding messages
- 7 provides reasonable concurrency without excessive memory

**Wraparound Handling:**
```c
// Sequence ID wraps at 256 (uint8_t)
// But queue index wraps at SCICLIENT_MAX_QUEUE_SIZE
// This works because response matching uses seq ID from header
```

### Context Management (Secure vs Non-Secure)

**Context Determination:**
```c
#if defined (BUILD_MCU1_0)
    // MCU R5F can run in secure or non-secure
    if (isSecureMode) {
        context = SCICLIENT_SECURE_CONTEXT;
        txThread = SECURE_TX_THREAD;
    } else {
        context = SCICLIENT_NON_SECURE_CONTEXT;
        txThread = NONSECURE_TX_THREAD;
    }
#elif defined (BUILD_MPU1_0)
    // A72 typically runs non-secure
    context = SCICLIENT_NON_SECURE_CONTEXT;
#endif
```

**Message Header Differences:**
```c
if (gSciclientHandle.isSecureMode) {
    // Add security header
    gSciclient_secHeader.integ_check = 0xAA;
    memcpy(msgBuf, &gSciclient_secHeader, sizeof(struct tisci_sec_header));
    msgBuf += sizeof(struct tisci_sec_header);
}

// Add TISCI header
memcpy(msgBuf, &header, sizeof(struct tisci_header));
```

### Cache Coherency Management

**Problem:** Secure proxy target memory may be cached differently on different cores.

**Solution:** Explicit cache operations before/after access.

```c
// Before writing to secure proxy
CacheP_wbInv((void *)messageBuf, messageSize);

// Write to proxy
CSL_secProxyAccessTarget(...);

// After reading from secure proxy
CacheP_inv((void *)messageBuf, messageSize);
```

**C66x Special Handling:**
```c
#if defined(_TMS320C6X)
// C66x requires byte-wise copy for unaligned access
static void Sciclient_utilByteCopy(uint8_t *src, uint8_t *dest,
                                    uint32_t num_bytes) {
    for (i = 0; i < num_bytes; i++) {
        dest[i] = src[i];
    }
}
#endif
```

### RAT (Region Address Translation) for C66x

**Problem:** C66x DSP has limited address space and needs MMU-like translation.

**Solution:** Configure RAT to map interrupt router registers.

```c
#if defined(_TMS320C6X)
static int32_t Sciclient_C66xRatMap(uint32_t ratRegion) {
    CSL_RatTranslationCfgInfo translationCfg;

    // Map GIC/INTR_ROUTER registers to C66x addressable range
    translationCfg.sizeInBytes = 0x10000;  // 64KB
    translationCfg.baseAddress = GIC_BASE_ADDR;  // Physical
    translationCfg.translatedAddress = 0x40000000;  // C66x virtual

    CSL_ratConfigRegionTranslation(ratRegion, &translationCfg);
}
#endif
```

### Timeout Handling

**Timeout Values:**
```c
#define SCICLIENT_SERVICE_WAIT_FOREVER (0xFFFFFFFFU)
#define SCICLIENT_SERVICE_NO_WAIT      (0x0U)
// Or specific iteration count (not ms!)
```

**Polling Mode Timeout:**
```c
uint32_t iterations = 0;
while (!isMsgReceived && iterations < timeout) {
    // Check for message
    iterations++;

    if (timeout != SCICLIENT_SERVICE_WAIT_FOREVER) {
        // Small delay between polls
        Osal_delay(1);
    }
}
```

**Interrupt Mode Timeout:**
```c
SemaphoreP_Status status;
status = SemaphoreP_pend(semHandle, timeoutMs);

if (status == SemaphoreP_TIMEOUT) {
    return CSL_ETIMEOUT;
}
```

### Error Recovery

**TX Thread Full:**
```c
// Wait for space in TX thread
retries = 0;
while (txThreadStatus.curMsgCnt == 0) {
    if (retries++ > MAX_RETRIES) {
        return CSL_EFAIL;  // TX thread stuck
    }
    Osal_delay(10);
}
```

**Sequence ID Mismatch:**
```c
// In ISR or polling loop
receivedSeqId = ((struct tisci_header *)msg)->seq;

if (receivedSeqId != expectedSeqId) {
    // This is for a different request
    // Store it and continue waiting
    gSciclientHandle.outOfOrderMsg[receivedSeqId] = msg;
}
```

**DMSC NACK Handling:**
```c
if (respHeader->flags & TISCI_MSG_FLAG_NACK) {
    // Check response payload for error details
    struct tisci_msg_set_device_resp *resp =
        (struct tisci_msg_set_device_resp *)pRespPayload;

    // Specific error handling based on message type
}
```

### Memory Layout

**Static Allocation:**
```c
// Global handle
Sciclient_ServiceHandle_t gSciclientHandle;

// Response buffers (one per sequence ID)
uint8_t gRespMsgArr[SCICLIENT_MAX_QUEUE_SIZE][SCICLIENT_MAX_MSG_SIZE];

// Secure proxy configuration
CSL_SecProxyCfg gSciclient_secProxyCfg;
```

**Stack Usage:**
```c
// Sciclient_service() stack frame includes:
uint8_t txMessageBuf[SCICLIENT_MAX_MSG_SIZE];  // TX message construction
// Relatively light stack usage otherwise
```

**Linker Sections:**
```c
// Board configuration data
#pragma DATA_SECTION(gSciclient_boardCfgData, ".boardcfg_data")
uint8_t gSciclient_boardCfgData[SCICLIENT_BOARDCFG_SIZE];
```

Must be placed in OCMRAM accessible by DMSC.

---

## Usage Examples and Patterns

### Example 1: Initialize SCICLIENT

```c
#include <ti/drv/sciclient/sciclient.h>

int main(void) {
    int32_t status;
    Sciclient_ConfigPrms_t configPrms;

    // Initialize with default parameters
    Sciclient_configPrmsInit(&configPrms);

    // Use interrupt mode for RTOS
    configPrms.opModeFlag = SCICLIENT_SERVICE_OPERATION_MODE_INTERRUPT;

    // Initialize SCICLIENT
    status = Sciclient_init(&configPrms);
    if (status != CSL_PASS) {
        // Handle error
        return -1;
    }

    // SCICLIENT is now ready to use
    // ...

    return 0;
}
```

### Example 2: Power On a Module and Configure Clock

```c
int32_t uart0_power_on_and_configure(void) {
    int32_t status;

    // Step 1: Power on UART0 module
    status = Sciclient_pmSetModuleState(
        TISCI_DEV_UART0,
        TISCI_MSG_VALUE_DEVICE_SW_STATE_ON,
        TISCI_MSG_FLAG_AOP,  // Allow power domain control
        SCICLIENT_SERVICE_WAIT_FOREVER
    );

    if (status != CSL_PASS) {
        return status;
    }

    // Step 2: Enable functional clock
    status = Sciclient_pmModuleClkRequest(
        TISCI_DEV_UART0,
        TISCI_DEV_UART0_FCLK_CLK,
        TISCI_MSG_VALUE_CLOCK_SW_STATE_REQ,
        0,
        SCICLIENT_SERVICE_WAIT_FOREVER
    );

    if (status != CSL_PASS) {
        return status;
    }

    // Step 3: Set clock frequency to 48 MHz
    status = Sciclient_pmSetModuleClkFreq(
        TISCI_DEV_UART0,
        TISCI_DEV_UART0_FCLK_CLK,
        48000000ULL,
        TISCI_MSG_FLAG_CLOCK_ALLOW_FREQ_CHANGE,
        SCICLIENT_SERVICE_WAIT_FOREVER
    );

    return status;
}
```

### Example 3: Configure Interrupt Routing

```c
int32_t configure_uart0_rx_interrupt(void) {
    int32_t status;
    struct tisci_msg_rm_irq_set_req req;
    struct tisci_msg_rm_irq_set_resp resp;
    Sciclient_ReqPrm_t reqPrm;
    Sciclient_RespPrm_t respPrm;

    // Clear request structure
    memset(&req, 0, sizeof(req));

    // Set valid parameters
    req.valid_params = TISCI_MSG_VALUE_RM_DST_ID_VALID |
                       TISCI_MSG_VALUE_RM_DST_HOST_IRQ_VALID;

    // Source: UART0 RX interrupt
    req.src_id = TISCI_DEV_UART0;
    req.src_index = 0;  // RX interrupt

    // Destination: MCU R5F core 0
    req.dst_id = TISCI_DEV_MCU_R5FSS0_CORE0;
    req.dst_host_irq = 100;  // VIM interrupt number

    // Setup request parameters
    reqPrm.messageType = TISCI_MSG_RM_IRQ_SET;
    reqPrm.flags = TISCI_MSG_FLAG_AOP;
    reqPrm.pReqPayload = (uint8_t *)&req;
    reqPrm.reqPayloadSize = sizeof(req);
    reqPrm.timeout = SCICLIENT_SERVICE_WAIT_FOREVER;

    // Setup response parameters
    respPrm.pRespPayload = (uint8_t *)&resp;
    respPrm.respPayloadSize = sizeof(resp);

    // Send request
    status = Sciclient_service(&reqPrm, &respPrm);

    if (status != CSL_PASS) {
        return status;
    }

    if (respPrm.flags & TISCI_MSG_FLAG_NACK) {
        return CSL_EFAIL;
    }

    return CSL_PASS;
}
```

### Example 4: Boot a Secondary Core (C66x DSP)

```c
int32_t boot_c66x_dsp0(uint32_t entryPoint) {
    int32_t status;
    struct tisci_msg_proc_request_req proc_req;
    struct tisci_msg_proc_set_config_req cfg_req;
    struct tisci_msg_proc_release_req rel_req;
    Sciclient_ReqPrm_t reqPrm;
    Sciclient_RespPrm_t respPrm;

    // Step 1: Request processor control
    memset(&proc_req, 0, sizeof(proc_req));
    proc_req.processor_id = SCICLIENT_PROC_ID_C66SS0_CORE0;

    reqPrm.messageType = TISCI_MSG_PROC_REQUEST;
    reqPrm.flags = TISCI_MSG_FLAG_AOP;
    reqPrm.pReqPayload = (uint8_t *)&proc_req;
    reqPrm.reqPayloadSize = sizeof(proc_req);
    reqPrm.timeout = SCICLIENT_SERVICE_WAIT_FOREVER;

    respPrm.pRespPayload = NULL;
    respPrm.respPayloadSize = 0;

    status = Sciclient_service(&reqPrm, &respPrm);
    if (status != CSL_PASS) return status;

    // Step 2: Set processor configuration (entry point, boot vector)
    memset(&cfg_req, 0, sizeof(cfg_req));
    cfg_req.processor_id = SCICLIENT_PROC_ID_C66SS0_CORE0;
    cfg_req.bootvector_lo = entryPoint & 0xFFFFFFFF;
    cfg_req.bootvector_hi = (entryPoint >> 32) & 0xFFFFFFFF;
    cfg_req.config_flags_1_set = 0;  // Additional flags if needed

    reqPrm.messageType = TISCI_MSG_PROC_SET_CONFIG;
    reqPrm.pReqPayload = (uint8_t *)&cfg_req;
    reqPrm.reqPayloadSize = sizeof(cfg_req);

    status = Sciclient_service(&reqPrm, &respPrm);
    if (status != CSL_PASS) return status;

    // Step 3: Release processor from reset
    memset(&rel_req, 0, sizeof(rel_req));
    rel_req.processor_id = SCICLIENT_PROC_ID_C66SS0_CORE0;

    reqPrm.messageType = TISCI_MSG_PROC_RELEASE;
    reqPrm.pReqPayload = (uint8_t *)&rel_req;
    reqPrm.reqPayloadSize = sizeof(rel_req);

    status = Sciclient_service(&reqPrm, &respPrm);

    return status;
}
```

### Example 5: Query Firmware Version

```c
int32_t get_firmware_version(void) {
    int32_t status;
    struct tisci_msg_version_req req;
    struct tisci_msg_version_resp resp;
    Sciclient_ReqPrm_t reqPrm;
    Sciclient_RespPrm_t respPrm;

    memset(&req, 0, sizeof(req));
    memset(&resp, 0, sizeof(resp));

    reqPrm.messageType = TISCI_MSG_VERSION;
    reqPrm.flags = TISCI_MSG_FLAG_AOP;
    reqPrm.pReqPayload = (uint8_t *)&req;
    reqPrm.reqPayloadSize = sizeof(req);
    reqPrm.timeout = SCICLIENT_SERVICE_WAIT_FOREVER;

    respPrm.pRespPayload = (uint8_t *)&resp;
    respPrm.respPayloadSize = sizeof(resp);

    status = Sciclient_service(&reqPrm, &respPrm);

    if (status == CSL_PASS) {
        printf("SYSFW Version: %s\n", resp.str);
        printf("ABI Major: %d\n", resp.abi_major);
        printf("ABI Minor: %d\n", resp.abi_minor);
    }

    return status;
}
```

### Common Usage Pattern

```c
// General pattern for using Sciclient_service()

int32_t call_tisci_service(void) {
    int32_t status;
    struct tisci_msg_<service>_req req;
    struct tisci_msg_<service>_resp resp;
    Sciclient_ReqPrm_t reqPrm;
    Sciclient_RespPrm_t respPrm;

    // 1. Clear structures
    memset(&req, 0, sizeof(req));
    memset(&resp, 0, sizeof(resp));

    // 2. Fill request payload
    req.field1 = value1;
    req.field2 = value2;
    // ...

    // 3. Setup request parameters
    reqPrm.messageType = TISCI_MSG_<SERVICE>;
    reqPrm.flags = TISCI_MSG_FLAG_AOP;
    reqPrm.pReqPayload = (uint8_t *)&req;
    reqPrm.reqPayloadSize = sizeof(req);
    reqPrm.timeout = SCICLIENT_SERVICE_WAIT_FOREVER;

    // 4. Setup response parameters
    respPrm.pRespPayload = (uint8_t *)&resp;
    respPrm.respPayloadSize = sizeof(resp);

    // 5. Call service
    status = Sciclient_service(&reqPrm, &respPrm);

    // 6. Check status
    if (status != CSL_PASS) {
        return status;  // Communication error
    }

    if (respPrm.flags & TISCI_MSG_FLAG_NACK) {
        return CSL_EFAIL;  // DMSC rejected request
    }

    // 7. Use response data
    // resp.field1, resp.field2, etc.

    return CSL_PASS;
}
```

---

## Design Decisions and Rationale

### Decision: Single Generic API vs Multiple Specific APIs

**Question:** Should SCICLIENT expose one `Sciclient_service()` API or separate APIs for each message type?

**Alternatives:**

**Alternative 1:** Separate API for each message
```c
int32_t sci_client_pm_set_device(int32_t param_a, uint16_t param_b, ...);
int32_t sci_client_rm_alloc_irq(...);
// Hundreds of APIs
```

**Alternative 2:** Single generic service API
```c
int32_t Sciclient_service(const Sciclient_ReqPrm_t *pReqPrm,
                          Sciclient_RespPrm_t *pRespPrm);
```

**Decision:** Use Alternative 2 with optional FL (Functional Layer) wrappers

**Rationale:**
- **Protocol Evolution**: TISCI protocol can add new messages without changing SCICLIENT API
- **Reduced Code Size**: One implementation handles all messages
- **Flexibility**: Applications can send new/custom messages easily
- **Simplicity**: Core SCICLIENT doesn't need knowledge of every message type

**But Also:** Provide FL wrappers (e.g., `Sciclient_pmSetModuleState()`) for common use cases:
- **Convenience**: Higher-level APIs are easier to use
- **Type Safety**: Compile-time checking of parameters
- **Documentation**: Each FL API can be well-documented

### Decision: OSAL for OS Abstraction

**Question:** How to support both RTOS and bare-metal applications?

**Alternatives:**

**Alternative 1:** Separate libraries for OS and Non-OS
- `sciclient_rtos.a`
- `sciclient_baremetal.a`

**Alternative 2:** Use OSAL for runtime abstraction

**Decision:** Use Alternative 2 (OSAL)

**Rationale:**
- **Code Reuse**: Single SCICLIENT implementation
- **Consistency**: Same approach as other PDK drivers
- **No Code Duplication**: OSAL handles OS vs Non-OS differences
- **Flexible**: Application chooses OSAL build (RTOS or bare-metal)

**OSAL APIs Used:**
- `SemaphoreP_create/pend/post` - Synchronization
- `HwiP_create/delete` - Interrupt registration
- `CacheP_wb/inv` - Cache coherency

### Decision: Polling vs Interrupt Mode

**Question:** Should response waiting be polling-based or interrupt-based?

**Decision:** Support both, runtime-configurable

**Rationale:**

**Polling Mode:**
- **Advantages**: Simple, no interrupt overhead, works before interrupts initialized
- **Disadvantages**: Wastes CPU cycles
- **Use Case**: Bare-metal, early boot, short requests

**Interrupt Mode:**
- **Advantages**: CPU can task-switch, efficient for RTOS
- **Disadvantages**: Interrupt overhead, more complex
- **Use Case**: RTOS applications, long requests, concurrent operations

**Configuration:**
```c
cfgPrms.opModeFlag = SCICLIENT_SERVICE_OPERATION_MODE_POLLED;    // or
cfgPrms.opModeFlag = SCICLIENT_SERVICE_OPERATION_MODE_INTERRUPT;
```

### Decision: Message Construction in Normal Memory

**Question:** Where should messages be constructed before sending?

**Alternatives:**

**Alternative 1:** Directly write to secure proxy buffer
```c
uint32_t *proxyBuf = (uint32_t *)proxyTargetAddr;
proxyBuf[0] = header.type;
proxyBuf[1] = payload.field1;
// ...
```

**Alternative 2:** Construct in normal memory, then copy to proxy
```c
uint8_t msgBuf[MAX_MSG_SIZE];
memcpy(msgBuf, &header, sizeof(header));
memcpy(msgBuf + sizeof(header), &payload, sizeof(payload));
CSL_secProxyAccessTarget(proxyAddr, msgBuf, msgSize);
```

**Decision:** Use Alternative 2

**Rationale:**
- **Cache Management**: Easier to control cache operations on normal memory
- **Alignment**: Avoid unaligned access issues (especially on C66x)
- **Atomicity**: Construct complete message before triggering HW
- **Debugging**: Can inspect message buffer before sending

### Decision: Maximum Queue Size = 7

**Question:** How many concurrent requests should be supported?

**Analysis:**
- Each host has limited TX threads (1-2)
- Each TX thread can queue ~2-4 messages
- Practical concurrency is low in most applications

**Decision:** `SCICLIENT_MAX_QUEUE_SIZE = 7`

**Rationale:**
- **Sufficient**: Handles typical use cases (2-3 concurrent requests)
- **Memory Efficient**: Each queue entry requires semaphore + response buffer
- **Scalable**: Can be increased if needed (rebuild library)

**Memory Cost:**
```c
7 semaphores × 32 bytes = 224 bytes
7 response buffers × 64 bytes = 448 bytes
Total: ~672 bytes
```

### Decision: Timeout in Iterations, Not Milliseconds

**Question:** What units for timeout parameter?

**Decision:** Iteration count (or special values WAIT_FOREVER/NO_WAIT)

**Rationale:**
- **Platform Independent**: Not tied to specific timer frequency
- **Deterministic**: Consistent across cores and clock speeds
- **Simple**: No need for timer infrastructure
- **Flexible**: Application can convert ms to iterations based on workload

**Note:** Some FL APIs use milliseconds internally by converting to iterations.

---

## Troubleshooting and FAQ

### Common Issues and Solutions

#### Issue: Sciclient_init() returns error

**Possible Causes:**
1. DMSC firmware not loaded
2. Secure proxy not configured by ROM/SBL
3. Incorrect host ID mapping
4. Memory allocation failure (semaphores)

**Debug Steps:**
```c
// Check DMSC is alive
struct tisci_msg_version_resp version;
status = Sciclient_getVersion(&version);
if (status != CSL_PASS) {
    // DMSC not responding - firmware issue
}

// Check secure proxy configuration
uint32_t numThreads = CSL_secProxyGetNumThreads(&gSciclient_secProxyCfg);
// Should be > 0

// Enable debug prints
#define SCICLIENT_DEBUG
```

#### Issue: Sciclient_service() times out

**Possible Causes:**
1. DMSC not processing requests (hung/crashed)
2. Wrong message type or malformed payload
3. Permission denied (DMSC silently drops)
4. TX thread full (no space to send)

**Debug Steps:**
```c
// Check TX thread status before send
CSL_SecProxyThreadStatus txStatus;
CSL_secProxyGetThreadStatus(pCfg, txThreadId, &txStatus);
printf("TX curr_cnt: %d\n", txStatus.curMsgCnt);
// Should be > 0

// Check RX thread for stuck messages
CSL_secProxyGetThreadStatus(pCfg, rxThreadId, &rxStatus);
printf("RX curr_cnt: %d\n", rxStatus.curMsgCnt);
// If stuck high, messages not being read

// Verify message type is valid
printf("Message type: 0x%x\n", pReqPrm->messageType);
```

#### Issue: Interrupt mode not working

**Possible Causes:**
1. Interrupt not routed correctly
2. GIC/VIM not initialized
3. Interrupt number mismatch
4. ISR not registered

**Debug Steps:**
```c
// Check interrupt was registered
if (gSciclientHandle.respIntr[0] == NULL) {
    // HwiP_create() failed
}

// Verify interrupt number
uint32_t intrNum = gSciclientHandle.map.respIntrNum;
printf("Response interrupt: %d\n", intrNum);

// Fall back to polling mode for testing
cfgPrms.opModeFlag = SCICLIENT_SERVICE_OPERATION_MODE_POLLED;
```

#### Issue: Power Management APIs fail with NACK

**Possible Causes:**
1. Device ID not valid for this SoC
2. Device assigned to different host (board config)
3. Device already in use (exclusive flag)

**Debug Steps:**
```c
// Check device ID is valid
status = Sciclient_pmIsModuleValid(moduleId);
if (status != CSL_PASS) {
    // Invalid device ID for this SoC
}

// Check board configuration
// Device may be assigned to different host in RM board cfg

// Try without exclusive flag
flags = TISCI_MSG_FLAG_AOP;  // Remove EXCLUSIVE
```

#### Issue: Resource Management APIs fail

**Possible Causes:**
1. Resource not allocated to this host (board config)
2. Resource already allocated
3. Invalid resource index

**Debug Steps:**
```c
// Check board config resource table
// Each host has assigned ranges:
// - UDMA channels
// - Ring accelerator rings
// - IRQ routes

// Verify index is in assigned range
// See soc/<soc>/tisci_resasg_types.h

// Check if resource is free
// Some resources may be pre-allocated at boot
```

### FAQ

#### Q: Can I use SCICLIENT before Sciclient_init()?

**A:** Only `Sciclient_loadFirmware()` can be used before init. This is called by SBL to load DMSC firmware. All other APIs require `Sciclient_init()` first.

#### Q: Is SCICLIENT thread-safe?

**A:** Yes, for RTOS builds:
- Mutex protects secure proxy write access
- Each thread gets own sequence ID and semaphore
- Concurrent calls from multiple threads are safe

For bare-metal builds, application must ensure mutual exclusion if calling from multiple contexts.

#### Q: What's the difference between SCICLIENT and SCISERVER?

**A:**
- **SCICLIENT**: Client-side library, runs on application cores (R5F, A72, etc.)
- **SCISERVER**: Server/proxy that runs on DM R5F, forwards requests from other cores to DMSC

SCISERVER is used when non-DM cores (like A72 running Linux) need to access DMSC but don't have direct secure proxy access.

#### Q: Can I add custom TI SCI messages?

**A:** Technically yes, if you control both client and DMSC firmware:
1. Define new message type and structures
2. Use `Sciclient_service()` with custom `messageType`
3. DMSC firmware must handle the new message type

For standard SoCs, you're limited to messages defined by TI's SYSFW.

#### Q: How do I know which device/clock IDs are valid?

**A:** Check SoC-specific headers:
```
soc/sysfw/include/<soc>/tisci_devices.h
soc/sysfw/include/<soc>/tisci_clocks.h
soc/sysfw/include/<soc>/tisci_hosts.h
```

#### Q: What happens if DMSC crashes?

**A:** System is effectively dead:
- All Sciclient calls will timeout
- Can't power on/off modules
- Can't manage resources
- Requires full system reset

DMSC firmware is designed to be robust and shouldn't crash under normal operation.

#### Q: Can I bypass SCICLIENT and talk to DMSC directly?

**A:** Not recommended:
- Need to understand TI SCI protocol details
- Must handle secure proxy correctly
- No OSAL abstraction
- Code will break if DMSC firmware updates

SCICLIENT exists specifically to provide stable interface.

#### Q: Does SCICLIENT work with Linux?

**A:** Indirectly:
- Linux on A72 typically uses kernel drivers (`ti_sci.c`)
- Kernel driver implements TI SCI protocol
- SCICLIENT is used on RTOS cores (R5F, DSP)
- Both client and kernel driver can coexist, each with assigned resources

#### Q: What's the maximum message size?

**A:** Determined by secure proxy configuration:
```c
uint32_t maxMsgSize = CSL_secProxyGetMaxMsgSize(&gSciclient_secProxyCfg);
// Typically 60-64 bytes on J7 devices
```

Large messages must be split or use indirect memory references (addresses to larger buffers).

#### Q: How fast is TI SCI communication?

**A:** Approximate latency:
- Request to DMSC: ~10-50 µs
- DMSC processing: Varies by message (10 µs to 1 ms)
- Response back: ~10-50 µs
- **Total**: Typically 50-500 µs for simple requests

Not suitable for high-frequency operations. Cache results when possible.

---

## Additional Resources

### Documentation

- **TISCI User Guide**: `soc/sysfw/binaries/system-firmware-public-documentation/index.html`
- **SCICLIENT Design Doc**: `docs/design/sciclient_master_doc.rst`
- **API Reference**: Generated from Doxygen comments in header files

### Source Code Organization

```
sciclient/
├── sciclient.h              # Main API header
├── sciclient_component.mk   # Build configuration
├── include/                 # FL API headers
│   ├── sciclient_pm.h
│   ├── sciclient_rm.h
│   ├── sciclient_firewall.h
│   └── ...
├── src/
│   ├── sciclient/           # Core implementation
│   │   ├── sciclient.c
│   │   ├── sciclient_pm.c
│   │   └── ...
│   └── sec_proxy/           # Secure proxy CSL
│       ├── csl_sec_proxy.h
│       └── src/csl_sec_proxy.c
├── soc/                     # SoC-specific files
│   ├── V0/ V1/ V2/ ...     # Per-SoC board configs
│   └── sysfw/               # System firmware headers
│       └── include/
│           ├── tisci/       # TISCI protocol definitions
│           └── <soc>/       # SoC-specific IDs
└── examples/                # Example applications
```

### Related Components

- **CSL (Chip Support Library)**: Low-level register access
- **OSAL**: OS abstraction (semaphores, interrupts, cache)
- **UDMA Driver**: Uses SCICLIENT RM APIs for channel allocation
- **Board Library**: Uses SCICLIENT PM APIs for initialization
- **SBL (Secondary Boot Loader)**: Loads SYSFW and initializes SCICLIENT

---

## Glossary

| Term | Definition |
|------|------------|
| **ABI** | Application Binary Interface - Versioning scheme for TISCI protocol |
| **CSL** | Chip Support Library - Low-level hardware abstraction |
| **DMSC** | Device Management and Security Controller - Dedicated system control processor |
| **FL** | Functional Layer - High-level wrapper APIs in SCICLIENT |
| **HAL** | Hardware Abstraction Layer - Core SCICLIENT service API |
| **Host ID** | Unique identifier for each processing entity in the SoC |
| **HS** | High Security - Secure SoC variant with authentication/encryption |
| **ISR** | Interrupt Service Routine |
| **NAVSS** | Network Accelerator SubSystem - Contains UDMA and Ring Accelerator |
| **OSAL** | Operating System Abstraction Layer |
| **PM** | Power Management |
| **PSI-L** | Packet Streaming Interface Layer - DMA data path routing |
| **RA** | Ring Accelerator - Hardware-managed circular buffers |
| **RM** | Resource Management |
| **SBL** | Secondary Boot Loader |
| **SCI** | System Control Interface |
| **Sequence ID** | Unique ID (0-255) to match requests with responses |
| **SYSFW** | System Firmware - Firmware running on DMSC |
| **TIFS** | TI Foundational Security - New name for SYSFW in newer SoCs |
| **TISCI** | Texas Instruments System Control Interface Protocol |
| **UDMA** | Unified DMA - High-performance DMA controller |
| **VIM** | Vectored Interrupt Manager - Interrupt controller for R5F |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Jan 2025 | Initial comprehensive knowledgebase creation |

---

**End of TI SCI CLIENT Knowledgebase**
