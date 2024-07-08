#
# This file is the makefile for building SBL image
# that is loaded by R5 ROM.
#
include $(PDK_INSTALL_PATH)/ti/build/Rules.make

HLOS_SUFFIX=
ifeq ($(HLOS_BOOT),yes)
HLOS_SUFFIX=_hlos
endif
COMBINE_SUFFIX=
ifeq ($(SBL_IMAGE_TYPE),combined)
COMBINE_SUFFIX=_combined
endif
HS_SUFFIX=
ifeq ($(BUILD_HS),yes)
HS_SUFFIX=_hs
endif
HS_FS_SUFFIX=
ifeq ($(BUILD_HS_FS),yes)
  HS_FS_SUFFIX=_hs_fs
endif
DMA_SUFFIX=
ifeq ($(BOOTMODE), $(filter $(BOOTMODE),ospi cust xip))
  ifeq ($(SBL_USE_DMA),no)
    DMA_SUFFIX=_nondma
  endif
endif
EMMC_SUFFIX=
ifeq ($(EMMC_BOOT0), yes)
  EMMC_SUFFIX=_boot0
else ifeq ($(EMMC_BOOT0), no)
  EMMC_SUFFIX=_uda
endif
OSPI_NAND_SUFFIX=
ifeq ($(OSPI_NAND), yes)
  OSPI_NAND_SUFFIX=_nand
endif
SECURE_HSM_BOOT_SUFFIX=
ifeq ($(BOOTMODE), uart)
  ifeq ($(SECURE_HSM_BOOT), yes)
    SECURE_HSM_BOOT_SUFFIX=hsm_boot_
  endif
endif

# if you want to boot app more than 500KB you need to change the following macro
# for instance your app is x KB then you need to give the macro with the following value from cmd line
# (x * 1024) in hexadecimal
MAX_APP_SIZE_EMMC ?= 0x7D000

# If no address is specified from command prompt, SBL copies EEPROM content to 0x90000000 
EEPROM_DATA_DDR_ADDRESS ?= 0x90000000

ifeq ($(BOOT_PERF), yes)
  ifeq ($(SBL_IMAGE_TYPE),combined)
    APP_NAME = sbl_boot_perf_$(BOOTMODE)_img_combined
    LOCAL_APP_NAME = sbl_boot_perf_$(BOOTMODE)_img_combined_$(CORE)
  else
    APP_NAME = sbl_boot_perf_$(BOOTMODE)$(OSPI_NAND_SUFFIX)_img
    LOCAL_APP_NAME = sbl_boot_perf_$(BOOTMODE)$(OSPI_NAND_SUFFIX)_img_$(CORE)
  endif
else ifeq ($(BOOTMODE), xip)
  ifeq ($(OSPI_FREQ), 133)
    APP_NAME = sbl_xip_133_img$(HS_SUFFIX)
    LOCAL_APP_NAME = sbl_xip_133_img_$(CORE)
  else
    APP_NAME = sbl_xip_img$(HS_SUFFIX)
    LOCAL_APP_NAME = sbl_xip_img_$(CORE)
  endif
else ifeq ($(RAT), 1)
  APP_NAME = sbl_cust_rat_main_ocm_img
  LOCAL_APP_NAME = sbl_cust_rat_main_ocm_img_$(CORE)
else
  APP_NAME = sbl_$(SECURE_HSM_BOOT_SUFFIX)$(BOOTMODE)$(OSPI_NAND_SUFFIX)$(EMMC_SUFFIX)_img$(COMBINE_SUFFIX)$(HLOS_SUFFIX)$(HS_SUFFIX)$(HS_FS_SUFFIX)
  LOCAL_APP_NAME=sbl_$(SECURE_HSM_BOOT_SUFFIX)$(BOOTMODE)$(OSPI_NAND_SUFFIX)$(EMMC_SUFFIX)_img$(COMBINE_SUFFIX)$(HLOS_SUFFIX)_$(CORE)
endif
BUILD_OS_TYPE = baremetal

SRCDIR += $(PDK_SBL_COMP_PATH)/board/k3

INCDIR      += $(PDK_SBL_COMP_PATH)
INCDIR      += $(PDK_SBL_COMP_PATH)/soc
INCDIR      += $(PDK_SBL_COMP_PATH)/soc/k3

SOC_DIR=$(SOC)
ifeq ($(SOC), j742s2)
  SOC_DIR=j784s4
endif

# List all the external components/interfaces, whose interface header files
#  need to be included for this component
INCLUDE_EXTERNAL_INTERFACES = pdk

# List all the components required by the application
COMP_LIST_COMMON = $(PDK_COMMON_BAREMETAL_COMP)
ifneq ($(strip $(HS_SUFFIX)),) #if $(HS_SUFFIX) is non-empty
  SCICLIENT := $(filter sciclient%,$(COMP_LIST_COMMON))
  COMP_LIST_COMMON := $(subst $(SCICLIENT),$(SCICLIENT)_hs,$(COMP_LIST_COMMON))
endif

CFLAGS_LOCAL_COMMON = $(PDK_CFLAGS) $(SBL_CFLAGS)

# Check for custom flags
ifeq ($(BOOTMODE), cust)
  SBL_CFLAGS = $(CUST_SBL_FLAGS)
  COMP_LIST_COMMON += sbl_lib_$(BOOTMODE)$(DMA_SUFFIX)$(HS_SUFFIX)
  ifeq ($(RAT), 1)
    SBL_CFLAGS += -DSBL_OCM_MAIN_DOMAIN_RAT
  endif
  ifeq ($(OSPI_NAND), yes)
    SBL_CFLAGS += -DOSPI_NAND_BOOT
  endif
else ifeq ($(BOOTMODE), xip)
  SBL_CFLAGS = $(CUST_SBL_FLAGS)
  SBL_CFLAGS += -DBUILD_XIP
  ifeq ($(OSPI_FREQ), 133)
    SBL_CFLAGS += -DOSPI_FREQ_133
  else
    SBL_CFLAGS += -DOSPI_FREQ_166
  endif
  COMP_LIST_COMMON += sbl_lib_cust$(DMA_SUFFIX)$(HS_SUFFIX)
else
  COMP_LIST_COMMON += sbl_lib_$(BOOTMODE)$(DMA_SUFFIX)$(HLOS_SUFFIX)$(HS_SUFFIX)
endif # ifeq ($(BOOTMODE), cust)

ifeq ($(SBL_USE_DMA),yes)
  SBL_CFLAGS += -DSBL_USE_DMA=1
else
  SBL_CFLAGS += -DSBL_USE_DMA=0
endif

ifeq ($(BOOT_PERF), yes)
  SBL_CFLAGS += -DBOOT_PERF 
endif

# Combined boot image flags
ifeq ($(SBL_IMAGE_TYPE), combined)
  SBL_CFLAGS += -DSBL_COMBINED_BOOT
endif

# HLOS Boot flags
ifeq ($(HLOS_BOOT),yes)
  SBL_CFLAGS += -DSBL_ENABLE_HLOS_BOOT -DSBL_HLOS_OWNS_FLASH
endif
ifeq ($(BUILD_HS),yes)
  SBL_CFLAGS += -DSBL_BUILD_HS -DBUILD_HS
endif
# BOOTMODE specific CFLAGS
ifeq ($(BOOTMODE), mmcsd)
  SBL_CFLAGS += -DBOOT_MMCSD
endif # ifeq ($(BOOTMODE), mmcsd)

ifeq ($(BOOTMODE), emmc)
  SBL_CFLAGS += -DBOOT_EMMC
  ifeq ($(EMMC_BOOT0), yes)
    SBL_CFLAGS += -DEMMC_BOOT0
  endif
endif # ifeq ($(BOOTMODE), emmc)

ifeq ($(BOOTMODE), ospi)
  SBL_CFLAGS += -DBOOT_OSPI
  ifeq ($(OSPI_NAND), yes)
    SBL_CFLAGS += -DOSPI_NAND_BOOT
  endif
endif # ifeq ($(BOOTMODE), ospi)

ifeq ($(SECURE_HSM_BOOT), yes)
  SBL_CFLAGS += -DSECURE_HSM_BOOT
endif

ifeq ($(BOOTMODE), hyperflash)
  SBL_CFLAGS += -DBOOT_HYPERFLASH
endif # ifeq ($(BOOTMODE), hyperflash)

ifeq ($(BOOTMODE), uart)
  SBL_CFLAGS += -DBOOT_UART
endif # ifeq ($(BOOTMODE), uart)

ifeq ($(BOOTMODE), qspi)
  SBL_CFLAGS += -DBOOT_QSPI
endif # ifeq ($(BOOTMODE), qspi)

ifeq ($(filter $(SBL_CFLAGS), -DBOOT_MMCSD), -DBOOT_MMCSD)
  COMP_LIST_COMMON += mmcsd fatfs_indp
endif # ifeq ($(filter $(SBL_CFLAGS), -DBOOT_MMCSD), -DBOOT_MMCSD)

ifeq ($(filter $(SBL_CFLAGS), -DBOOT_EMMC), -DBOOT_EMMC)
  COMP_LIST_COMMON += mmcsd fatfs_indp
endif # ifeq ($(filter $(SBL_CFLAGS), -DBOOT_EMMC), -DBOOT_EMMC)

ifeq ($(filter $(SBL_CFLAGS), -DBOOT_HYPERFLASH), -DBOOT_HYPERFLASH)
  COMP_LIST_COMMON += spi
endif # ifeq ($(filter $(SBL_CFLAGS), -DBOOT_HYPERFLASH), -DBOOT_HYPERFLASH)

ifeq ($(filter $(SBL_CFLAGS), -DBOOT_OSPI), -DBOOT_OSPI)
ifeq ($(filter $(SBL_CFLAGS), -DSBL_USE_DMA=1), -DSBL_USE_DMA=1)
  COMP_LIST_COMMON += spi_dma
else
  COMP_LIST_COMMON += spi
endif # ifeq ($(filter $(SBL_CFLAGS), -DSBL_USE_DMA=1), -DSBL_USE_DMA=1)
endif # ifeq ($(filter $(SBL_CFLAGS), -DBOOT_OSPI), -DBOOT_OSPI)

ifeq ($(filter $(SBL_CFLAGS), -DBOOT_QSPI), -DBOOT_QSPI)
ifeq ($(filter $(SBL_CFLAGS), -DSBL_USE_DMA=1), -DSBL_USE_DMA=1)
  COMP_LIST_COMMON += spi_dma
else
  COMP_LIST_COMMON += spi
endif # ifeq ($(filter $(SBL_CFLAGS), -DSBL_USE_DMA=1), -DSBL_USE_DMA=1)
endif # ifeq ($(filter $(SBL_CFLAGS), -DBOOT_OSPI), -DBOOT_OSPI)

SBL_CFLAGS += -DMAX_APP_SIZE_EMMC=$(MAX_APP_SIZE_EMMC)
SBL_CFLAGS += -DEEPROM_DATA_DDR_ADDRESS=$(EEPROM_DATA_DDR_ADDRESS)

SRCS_COMMON += sbl_main.c

EXTERNAL_LNKCMD_FILE_LOCAL = $(PDK_SBL_COMP_PATH)/soc/k3/$(SOC_DIR)/linker.cmd

# Core/SoC/platform specific source files and CFLAGS
# Example:
#   SRCS_<core/SoC/platform-name> =
#   CFLAGS_LOCAL_<core/SoC/platform-name> =

# Include common make files
ifeq ($(MAKERULEDIR), )
#Makerule path not defined, define this and assume relative path from ROOTDIR
  MAKERULEDIR := $(ROOTDIR)/ti/build/makerules
  export MAKERULEDIR
endif

# EFUSE_DEFAULT - R5 ROM will run the SBL in lockstep mode in lockstep
# #                 enabled devices and in split mode, if the devices do
# #                 not support lockstep.
# # SPLIT_MODE -    R5 ROM will awlys run the SBL on MCU1_0 in split mode
# #                 irrespective of whether the EFuse says the device can
# #                 support lockstep mode.
R5_STARTUP_MODE := SPLIT_MODE
export R5_STARTUP_MODE

include $(MAKERULEDIR)/common.mk

# OBJs and libraries are built by using rule defined in rules_<target>.mk
#     and need not be explicitly specified here

# Nothing beyond this point
