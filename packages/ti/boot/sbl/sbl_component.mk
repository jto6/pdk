#
# Copyright (c) 2018-2022, Texas Instruments Incorporated
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# *  Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# *  Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# *  Neither the name of Texas Instruments Incorporated nor the names of
#    its contributors may be used to endorse or promote products derived
#    from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
# EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

# File: sbl_component.mk
#       This file is component include make file of SBL.
# List of variables set in this file and their purpose:
# <mod>_RELPATH        - This is the relative path of the module, typically from
#                        top-level directory of the package
# <mod>_PATH           - This is the absolute path of the module. It derives from
#                        absolute path of the top-level directory (set in env.mk)
#                        and relative path set above
# <mod>_INCLUDE        - This is the path that has interface header files of the
#                        module. This can be multiple directories (space separated)
# <mod>_PKG_LIST       - Names of the modules (and sub-modules) that are a part
#                        part of this module, including itself.
# <mod>_BOARD_DEPENDENCY - "yes": means the code for this module depends on
#                             platform and the compiled obj/lib has to be kept
#                             under <platform> directory
#                             "no" or "" or if this variable is not defined: means
#                             this module has no platform dependent code and hence
#                             the obj/libs are not kept under <platform> dir.
# <mod>_CORE_DEPENDENCY     - "yes": means the code for this module depends on
#                             core and the compiled obj/lib has to be kept
#                             under <core> directory
#                             "no" or "" or if this variable is not defined: means
#                             this module has no core dependent code and hence
#                             the obj/libs are not kept under <core> dir.
# <mod>_APP_STAGE_FILES     - List of source files that belongs to the module
#                             <mod>, but that needs to be compiled at application
#                             build stage (in the context of the app). This is
#                             primarily for link time configurations or if the
#                             source file is dependent on options/defines that are
#                             application dependent. This can be left blank or
#                             not defined at all, in which case, it means there
#                             no source files in the module <mod> that are required
#                             to be compiled in the application build stage.
#
ifeq ($(sbl_component_make_include), )

sbl_BOARDLIST = j721e_evm j7200_evm j721s2_evm j784s4_evm j742s2_evm
sbl_SOCLIST = j721e j7200 j721s2 j784s4 j742s2

j721e_lockstep_CORELIST := mcu1_0 mcu2_0 mcu3_0
sbl_j721e_CORELIST := mcu1_0 mcu1_1 mcu2_0 mcu2_1 mcu3_0 mcu3_1 c66xdsp_1 c66xdsp_2 c7x_1 mpu1_0 mpu1_1

j7200_lockstep_CORELIST := mcu1_0 mcu2_0
sbl_j7200_CORELIST := mcu1_0 mcu1_1 mcu2_0 mcu2_1 mpu1_0 mpu1_1

j721s2_lockstep_CORELIST := mcu1_0 mcu2_0 mcu3_0
sbl_j721s2_CORELIST := mcu1_0 mcu1_1 mcu2_0 mcu2_1 mcu3_0 mcu3_1 c7x_1 c7x_2 mpu1_0 mpu1_1

j784s4_lockstep_CORELIST := mcu1_0 mcu2_0 mcu3_0 mcu4_0
sbl_j784s4_CORELIST := mcu1_0 mcu1_1 mcu2_0 mcu2_1 mcu3_0 mcu3_1 mcu4_0 mcu4_1 c7x_1 c7x_2 c7x_3 c7x_4 mpu1_0 mpu1_1 mpu1_2 mpu1_3 mpu2_0 mpu2_1 mpu2_2 mpu2_3

j742s2_lockstep_CORELIST := mcu1_0 mcu2_0 mcu3_0 mcu4_0
sbl_j742s2_CORELIST := mcu1_0 mcu1_1 mcu2_0 mcu2_1 mcu3_0 mcu3_1 mcu4_0 mcu4_1 c7x_1 c7x_2 c7x_3 mpu1_0 mpu1_1 mpu1_2 mpu1_3

$(SOC)_LASTCORE := $(word $(words $(sbl_$(SOC)_CORELIST)), $(sbl_$(SOC)_CORELIST))

sbl_DISABLE_PARALLEL_MAKE = yes
############################
# sbl package
# List of components included under sbl
# The components included here are built and will be part of sbl
############################

# For GP devices :

# Typically sbl_<bootmode>_img uses sbl_lib_<bootmode>. For special boot modes please refer to below:
# sbl_ospi_nand_img uses sbl_lib_ospi_nondma
# sbl_cust_img, sbl_boot_perf_cust_img, sbl_xip_img, sbl_xip_133_img uses sbl_lib_cust
# sbl_ospi_img_hlos uses sbl_lib_ospi_hlos

# For HS devices :

# Typically sbl_<bootmode>_img_hs uses sbl_lib_<bootmode>_hs. For special boot modes please refer to below:
# sbl_ospi_nand_img_hs uses sbl_lib_ospi_nondma_hs
# sbl_cust_img_hs, sbl_xip_img_hs uses sbl_lib_cust
# sbl_mmcsd_img_hlos_hs uses sbl_lib_mmcsd_hlos_hs
# sbl_ospi_img_hlos_hs uses sbl_lib_ospi_hlos_hs
ifeq ($(SOC),$(filter $(SOC), j721s2 j784s4 j721e j7200 j742s2))
  sbl_LIB_LIST = sbl_lib_mmcsd sbl_lib_ospi sbl_lib_uart sbl_lib_cust sbl_lib_emmc
  sbl_LIB_LIST += sbl_lib_mmcsd_hlos sbl_lib_ospi_hlos sbl_lib_ospi_hlos_hs sbl_lib_mmcsd_hlos_hs
  sbl_LIB_LIST += sbl_lib_mmcsd_hs sbl_lib_ospi_hs sbl_lib_uart_hs sbl_lib_cust_hs
  sbl_LIB_LIST += sbl_lib_cust_nondma sbl_lib_cust_nondma_hs
endif

ifeq ($(SOC), $(filter $(SOC), j721e))
  sbl_LIB_LIST += sbl_lib_hyperflash sbl_lib_hyperflash_hlos
  sbl_LIB_LIST += sbl_lib_hyperflash_hs sbl_lib_hyperflash_hlos_hs
endif

############################
# sbl example
# List of examples under sbl (+= is used at each example definition)
# All the tests mentioned in list are built when test target is called
# List below all examples for allowed values
############################
ifeq ($(SOC),$(filter $(SOC), j721s2 j784s4 j742s2))
  sbl_EXAMPLE_LIST = sbl_uart_img sbl_ospi_img sbl_mmcsd_img sbl_emmc_boot0_img
  sbl_EXAMPLE_LIST += sbl_mmcsd_img_hlos sbl_ospi_img_hlos sbl_emmc_uda_img sbl_boot_perf_cust_img_combined
  sbl_EXAMPLE_LIST += sbl_mmcsd_img_hs sbl_ospi_img_hs sbl_uart_img_hs sbl_ospi_img_hlos_hs
  sbl_EXAMPLE_LIST += sbl_mmcsd_img_combined sbl_ospi_img_combined sbl_mmcsd_img_combined_hs sbl_ospi_img_combined_hs
  sbl_EXAMPLE_LIST += sbl_mmcsd_img_combined_hs_fs sbl_ospi_img_combined_hs_fs
  sbl_EXAMPLE_LIST += sbl_ospi_nand_img sbl_ospi_nand_img_hs
  # sbl_hsm_boot_uart_img_hs is used to boot hsm core securely
  sbl_EXAMPLE_LIST += sbl_hsm_boot_uart_img_hs sbl_hsm_boot_uart_img
else ifeq ($(SOC),$(filter $(SOC), j721e))
  sbl_EXAMPLE_LIST = sbl_uart_img sbl_emmc_uda_img sbl_emmc_boot0_img
  sbl_EXAMPLE_LIST += sbl_mmcsd_img sbl_mmcsd_img_hlos sbl_ospi_img sbl_ospi_img_hlos sbl_hyperflash_img sbl_hyperflash_img_hlos
  sbl_EXAMPLE_LIST += sbl_mmcsd_img_hs sbl_ospi_img_hs sbl_hyperflash_img_hs sbl_uart_img_hs
  sbl_EXAMPLE_LIST += sbl_mmcsd_img_hlos_hs sbl_ospi_img_hlos_hs sbl_hyperflash_img_hlos_hs
else
  # for j7200
  sbl_EXAMPLE_LIST = sbl_uart_img sbl_emmc_uda_img sbl_emmc_boot0_img sbl_boot_perf_cust_img_combined
  sbl_EXAMPLE_LIST += sbl_mmcsd_img sbl_mmcsd_img_hlos sbl_ospi_img sbl_ospi_img_hlos
  sbl_EXAMPLE_LIST += sbl_mmcsd_img_hs sbl_ospi_img_hs sbl_uart_img_hs
  sbl_EXAMPLE_LIST += sbl_mmcsd_img_hlos_hs sbl_ospi_img_hlos_hs
  sbl_EXAMPLE_LIST += sbl_mmcsd_img_combined sbl_ospi_img_combined sbl_mmcsd_img_combined_hs sbl_ospi_img_combined_hs
  sbl_EXAMPLE_LIST += sbl_mmcsd_img_combined_hs_fs sbl_ospi_img_combined_hs_fs
endif


#
# SBL Modules
#

# SBL MMCSD LIB
sbl_lib_mmcsd_COMP_LIST = sbl_lib_mmcsd
sbl_lib_mmcsd_RELPATH = ti/boot/sbl
export sbl_lib_mmcsd_OBJPATH = ti/boot/sbl/mmcsd
sbl_lib_mmcsd_LIBNAME = sbl_lib_mmcsd
sbl_lib_mmcsd_PATH = $(PDK_SBL_COMP_PATH)
sbl_lib_mmcsd_LIBPATH = $(PDK_SBL_COMP_PATH)/lib/mmcsd
sbl_lib_mmcsd_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_lib.mk BOOTMODE=mmcsd SBL_USE_DMA=yes
export sbl_lib_mmcsd_MAKEFILE
export sbl_lib_mmcsd_LIBNAME
export sbl_lib_mmcsd_LIBPATH
sbl_lib_mmcsd_BOARD_DEPENDENCY = yes
sbl_lib_mmcsd_SOC_DEPENDENCY = yes
sbl_lib_mmcsd_CORE_DEPENDENCY = no
export sbl_lib_mmcsd_COMP_LIST
export sbl_lib_mmcsd_BOARD_DEPENDENCY
export sbl_lib_mmcsd_CORE_DEPENDENCY
sbl_lib_mmcsd_PKG_LIST = sbl_lib_mmcsd
sbl_lib_mmcsd_INCLUDE = $(sbl_lib_mmcsd_PATH)
sbl_lib_mmcsd_SOCLIST = $(sbl_SOCLIST)
sbl_lib_mmcsd_BOARDLIST = $(sbl_BOARDLIST)
export sbl_lib_mmcsd_SOCLIST
export sbl_lib_mmcsd_BOARDLIST
sbl_lib_mmcsd_$(SOC)_CORELIST = mcu1_0
export sbl_lib_mmcsd_$(SOC)_CORELIST

# SBL MMCSD LIB - HS build variant
sbl_lib_mmcsd_hs_COMP_LIST = sbl_lib_mmcsd_hs
sbl_lib_mmcsd_hs_RELPATH = ti/boot/sbl
export sbl_lib_mmcsd_hs_OBJPATH = ti/boot/sbl/mmcsd_hs
sbl_lib_mmcsd_hs_LIBNAME = sbl_lib_mmcsd_hs
sbl_lib_mmcsd_hs_PATH = $(PDK_SBL_COMP_PATH)
sbl_lib_mmcsd_hs_LIBPATH = $(PDK_SBL_COMP_PATH)/lib/mmcsd_hs
sbl_lib_mmcsd_hs_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_lib.mk BOOTMODE=mmcsd SBL_USE_DMA=yes BUILD_HS=yes
export sbl_lib_mmcsd_hs_MAKEFILE
export sbl_lib_mmcsd_hs_LIBNAME
export sbl_lib_mmcsd_hs_LIBPATH
sbl_lib_mmcsd_hs_BOARD_DEPENDENCY = yes
sbl_lib_mmcsd_hs_SOC_DEPENDENCY = yes
sbl_lib_mmcsd_hs_CORE_DEPENDENCY = no
export sbl_lib_mmcsd_hs_COMP_LIST
export sbl_lib_mmcsd_hs_BOARD_DEPENDENCY
export sbl_lib_mmcsd_hs_CORE_DEPENDENCY
sbl_lib_mmcsd_hs_PKG_LIST = sbl_lib_mmcsd_hs
sbl_lib_mmcsd_hs_INCLUDE = $(sbl_lib_mmcsd_hs_PATH)
sbl_lib_mmcsd_hs_SOCLIST = $(sbl_SOCLIST)
sbl_lib_mmcsd_hs_BOARDLIST = $(sbl_BOARDLIST)
export sbl_lib_mmcsd_hs_SOCLIST
export sbl_lib_mmcsd_hs_BOARDLIST
sbl_lib_mmcsd_hs_$(SOC)_CORELIST = mcu1_0
export sbl_lib_mmcsd_hs_$(SOC)_CORELIST

# SBL MMCSD HLOS LIB
sbl_lib_mmcsd_hlos_COMP_LIST = sbl_lib_mmcsd_hlos
sbl_lib_mmcsd_hlos_RELPATH = ti/boot/sbl
export sbl_lib_mmcsd_hlos_OBJPATH = ti/boot/sbl/mmcsd_hlos
sbl_lib_mmcsd_hlos_LIBNAME = sbl_lib_mmcsd_hlos
sbl_lib_mmcsd_hlos_PATH = $(PDK_SBL_COMP_PATH)
sbl_lib_mmcsd_hlos_LIBPATH = $(PDK_SBL_COMP_PATH)/lib/mmcsd_hlos
sbl_lib_mmcsd_hlos_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_lib.mk BOOTMODE=mmcsd HLOS_BOOT=yes SBL_USE_DMA=yes
export sbl_lib_mmcsd_hlos_MAKEFILE
export sbl_lib_mmcsd_hlos_LIBNAME
export sbl_lib_mmcsd_hlos_LIBPATH
sbl_lib_mmcsd_hlos_BOARD_DEPENDENCY = yes
sbl_lib_mmcsd_hlos_SOC_DEPENDENCY = yes
sbl_lib_mmcsd_hlos_CORE_DEPENDENCY = no
export sbl_lib_mmcsd_hlos_COMP_LIST
export sbl_lib_mmcsd_hlos_BOARD_DEPENDENCY
export sbl_lib_mmcsd_hlos_CORE_DEPENDENCY
sbl_lib_mmcsd_hlos_PKG_LIST = sbl_lib_mmcsd_hlos
sbl_lib_mmcsd_hlos_INCLUDE = $(sbl_lib_mmcsd_hlos_PATH)
sbl_lib_mmcsd_hlos_SOCLIST = $(sbl_SOCLIST)
sbl_lib_mmcsd_hlos_BOARDLIST = $(sbl_BOARDLIST)
export sbl_lib_mmcsd_hlos_SOCLIST
export sbl_lib_mmcsd_hlos_BOARDLIST
sbl_lib_mmcsd_hlos_$(SOC)_CORELIST = mcu1_0
export sbl_lib_mmcsd_hlos_$(SOC)_CORELIST

# SBL MMCSD HLOS LIB - HS build variant
sbl_lib_mmcsd_hlos_hs_COMP_LIST = sbl_lib_mmcsd_hlos_hs
sbl_lib_mmcsd_hlos_hs_RELPATH = ti/boot/sbl
export sbl_lib_mmcsd_hlos_hs_OBJPATH = ti/boot/sbl/mmcsd_hlos_hs
sbl_lib_mmcsd_hlos_hs_LIBNAME = sbl_lib_mmcsd_hlos_hs
sbl_lib_mmcsd_hlos_hs_PATH = $(PDK_SBL_COMP_PATH)
sbl_lib_mmcsd_hlos_hs_LIBPATH = $(PDK_SBL_COMP_PATH)/lib/mmcsd_hlos_hs
sbl_lib_mmcsd_hlos_hs_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_lib.mk BOOTMODE=mmcsd HLOS_BOOT=yes SBL_USE_DMA=yes BUILD_HS=yes
export sbl_lib_mmcsd_hlos_hs_MAKEFILE
export sbl_lib_mmcsd_hlos_hs_LIBNAME
export sbl_lib_mmcsd_hlos_hs_LIBPATH
sbl_lib_mmcsd_hlos_hs_BOARD_DEPENDENCY = yes
sbl_lib_mmcsd_hlos_hs_SOC_DEPENDENCY = yes
sbl_lib_mmcsd_hlos_hs_CORE_DEPENDENCY = no
export sbl_lib_mmcsd_hlos_hs_COMP_LIST
export sbl_lib_mmcsd_hlos_hs_BOARD_DEPENDENCY
export sbl_lib_mmcsd_hlos_hs_CORE_DEPENDENCY
sbl_lib_mmcsd_hlos_hs_PKG_LIST = sbl_lib_mmcsd_hlos_hs
sbl_lib_mmcsd_hlos_hs_INCLUDE = $(sbl_lib_mmcsd_hlos_hs_PATH)
sbl_lib_mmcsd_hlos_hs_SOCLIST = $(sbl_SOCLIST)
sbl_lib_mmcsd_hlos_hs_BOARDLIST = $(sbl_BOARDLIST)
export sbl_lib_mmcsd_hlos_hs_SOCLIST
export sbl_lib_mmcsd_hlos_hs_BOARDLIST
sbl_lib_mmcsd_hlos_hs_$(SOC)_CORELIST = mcu1_0
export sbl_lib_mmcsd_hlos_hs_$(SOC)_CORELIST

# SBL EMMC LIB
sbl_lib_emmc_COMP_LIST = sbl_lib_emmc
sbl_lib_emmc_RELPATH = ti/boot/sbl
export sbl_lib_emmc_OBJPATH = ti/boot/sbl/emmc
sbl_lib_emmc_LIBNAME = sbl_lib_emmc
sbl_lib_emmc_PATH = $(PDK_SBL_COMP_PATH)
sbl_lib_emmc_LIBPATH = $(PDK_SBL_COMP_PATH)/lib/emmc
sbl_lib_emmc_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_lib.mk BOOTMODE=emmc SBL_USE_DMA=yes
export sbl_lib_emmc_MAKEFILE
export sbl_lib_emmc_LIBNAME
export sbl_lib_emmc_LIBPATH
sbl_lib_emmc_BOARD_DEPENDENCY = yes
sbl_lib_emmc_SOC_DEPENDENCY = yes
sbl_lib_emmc_CORE_DEPENDENCY = no
export sbl_lib_emmc_COMP_LIST
export sbl_lib_emmc_BOARD_DEPENDENCY
export sbl_lib_emmc_CORE_DEPENDENCY
sbl_lib_emmc_PKG_LIST = sbl_lib_emmc
sbl_lib_emmc_INCLUDE = $(sbl_lib_emmc_PATH)
sbl_lib_emmc_SOCLIST = $(sbl_SOCLIST)
sbl_lib_emmc_BOARDLIST = $(sbl_BOARDLIST)
export sbl_lib_emmc_SOCLIST
export sbl_lib_emmc_BOARDLIST
sbl_lib_emmc_$(SOC)_CORELIST = mcu1_0
export sbl_lib_emmc_$(SOC)_CORELIST

# SBL OSPI LIB
sbl_lib_ospi_COMP_LIST = sbl_lib_ospi
sbl_lib_ospi_RELPATH = ti/boot/sbl
export sbl_lib_ospi_OBJPATH = ti/boot/sbl/ospi
sbl_lib_ospi_LIBNAME = sbl_lib_ospi
sbl_lib_ospi_PATH = $(PDK_SBL_COMP_PATH)
sbl_lib_ospi_LIBPATH = $(PDK_SBL_COMP_PATH)/lib/ospi
sbl_lib_ospi_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_lib.mk BOOTMODE=ospi SBL_USE_DMA=yes
export sbl_lib_ospi_MAKEFILE
export sbl_lib_ospi_LIBNAME
export sbl_lib_ospi_LIBPATH
sbl_lib_ospi_BOARD_DEPENDENCY = yes
sbl_lib_ospi_SOC_DEPENDENCY = yes
sbl_lib_ospi_CORE_DEPENDENCY = no
export sbl_lib_ospi_COMP_LIST
export sbl_lib_ospi_BOARD_DEPENDENCY
export sbl_lib_ospi_CORE_DEPENDENCY
sbl_lib_ospi_PKG_LIST = sbl_lib_ospi
sbl_lib_ospi_INCLUDE = $(sbl_lib_ospi_PATH)
sbl_lib_ospi_SOCLIST = $(sbl_SOCLIST)
sbl_lib_ospi_BOARDLIST = $(sbl_BOARDLIST)
export sbl_lib_ospi_SOCLIST
export sbl_lib_ospi_BOARDLIST
sbl_lib_ospi_$(SOC)_CORELIST = mcu1_0
export sbl_lib_ospi_$(SOC)_CORELIST

# SBL OSPI LIB - HS build variant
sbl_lib_ospi_hs_COMP_LIST = sbl_lib_ospi_hs
sbl_lib_ospi_hs_RELPATH = ti/boot/sbl
export sbl_lib_ospi_hs_OBJPATH = ti/boot/sbl/ospi_hs
sbl_lib_ospi_hs_LIBNAME = sbl_lib_ospi_hs
sbl_lib_ospi_hs_PATH = $(PDK_SBL_COMP_PATH)
sbl_lib_ospi_hs_LIBPATH = $(PDK_SBL_COMP_PATH)/lib/ospi_hs
sbl_lib_ospi_hs_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_lib.mk BOOTMODE=ospi SBL_USE_DMA=yes BUILD_HS=yes
export sbl_lib_ospi_hs_MAKEFILE
export sbl_lib_ospi_hs_LIBNAME
export sbl_lib_ospi_hs_LIBPATH
sbl_lib_ospi_hs_BOARD_DEPENDENCY = yes
sbl_lib_ospi_hs_SOC_DEPENDENCY = yes
sbl_lib_ospi_hs_CORE_DEPENDENCY = no
export sbl_lib_ospi_hs_COMP_LIST
export sbl_lib_ospi_hs_BOARD_DEPENDENCY
export sbl_lib_ospi_hs_CORE_DEPENDENCY
sbl_lib_ospi_hs_PKG_LIST = sbl_lib_ospi_hs
sbl_lib_ospi_hs_INCLUDE = $(sbl_lib_ospi_hs_PATH)
sbl_lib_ospi_hs_SOCLIST = $(sbl_SOCLIST)
sbl_lib_ospi_hs_BOARDLIST = $(sbl_BOARDLIST)
export sbl_lib_ospi_hs_SOCLIST
export sbl_lib_ospi_hs_BOARDLIST
sbl_lib_ospi_hs_$(SOC)_CORELIST = mcu1_0
export sbl_lib_ospi_hs_$(SOC)_CORELIST

# SBL OSPI HLOS LIB
sbl_lib_ospi_hlos_COMP_LIST = sbl_lib_ospi_hlos
sbl_lib_ospi_hlos_RELPATH = ti/boot/sbl
export sbl_lib_ospi_hlos_OBJPATH = ti/boot/sbl/ospi_hlos
sbl_lib_ospi_hlos_LIBNAME = sbl_lib_ospi_hlos
sbl_lib_ospi_hlos_PATH = $(PDK_SBL_COMP_PATH)
sbl_lib_ospi_hlos_LIBPATH = $(PDK_SBL_COMP_PATH)/lib/ospi_hlos
sbl_lib_ospi_hlos_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_lib.mk BOOTMODE=ospi HLOS_BOOT=yes SBL_USE_DMA=yes
export sbl_lib_ospi_hlos_MAKEFILE
export sbl_lib_ospi_hlos_LIBNAME
export sbl_lib_ospi_hlos_LIBPATH
sbl_lib_ospi_hlos_BOARD_DEPENDENCY = yes
sbl_lib_ospi_hlos_SOC_DEPENDENCY = yes
sbl_lib_ospi_hlos_CORE_DEPENDENCY = no
export sbl_lib_ospi_hlos_COMP_LIST
export sbl_lib_ospi_hlos_BOARD_DEPENDENCY
export sbl_lib_ospi_hlos_CORE_DEPENDENCY
sbl_lib_ospi_hlos_PKG_LIST = sbl_lib_ospi_hlos
sbl_lib_ospi_hlos_INCLUDE = $(sbl_lib_ospi_hlos_PATH)
sbl_lib_ospi_hlos_SOCLIST = $(sbl_SOCLIST)
sbl_lib_ospi_hlos_BOARDLIST = $(sbl_BOARDLIST)
export sbl_lib_ospi_hlos_SOCLIST
export sbl_lib_ospi_hlos_BOARDLIST
sbl_lib_ospi_hlos_$(SOC)_CORELIST = mcu1_0
export sbl_lib_ospi_hlos_$(SOC)_CORELIST

# SBL OSPI HLOS LIB - HS build variant
sbl_lib_ospi_hlos_hs_COMP_LIST = sbl_lib_ospi_hlos_hs
sbl_lib_ospi_hlos_hs_RELPATH = ti/boot/sbl
export sbl_lib_ospi_hlos_hs_OBJPATH = ti/boot/sbl/ospi_hlos_hs
sbl_lib_ospi_hlos_hs_LIBNAME = sbl_lib_ospi_hlos_hs
sbl_lib_ospi_hlos_hs_PATH = $(PDK_SBL_COMP_PATH)
sbl_lib_ospi_hlos_hs_LIBPATH = $(PDK_SBL_COMP_PATH)/lib/ospi_hlos_hs
sbl_lib_ospi_hlos_hs_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_lib.mk BOOTMODE=ospi HLOS_BOOT=yes SBL_USE_DMA=yes BUILD_HS=yes
export sbl_lib_ospi_hlos_hs_MAKEFILE
export sbl_lib_ospi_hlos_hs_LIBNAME
export sbl_lib_ospi_hlos_hs_LIBPATH
sbl_lib_ospi_hlos_hs_BOARD_DEPENDENCY = yes
sbl_lib_ospi_hlos_hs_SOC_DEPENDENCY = yes
sbl_lib_ospi_hlos_hs_CORE_DEPENDENCY = no
export sbl_lib_ospi_hlos_hs_COMP_LIST
export sbl_lib_ospi_hlos_hs_BOARD_DEPENDENCY
export sbl_lib_ospi_hlos_hs_CORE_DEPENDENCY
sbl_lib_ospi_hlos_hs_PKG_LIST = sbl_lib_ospi_hlos_hs
sbl_lib_ospi_hlos_hs_INCLUDE = $(sbl_lib_ospi_hlos_hs_PATH)
sbl_lib_ospi_hlos_hs_SOCLIST = $(sbl_SOCLIST)
sbl_lib_ospi_hlos_hs_BOARDLIST = $(sbl_BOARDLIST)
export sbl_lib_ospi_hlos_hs_SOCLIST
export sbl_lib_ospi_hlos_hs_BOARDLIST
sbl_lib_ospi_hlos_hs_$(SOC)_CORELIST = mcu1_0
export sbl_lib_ospi_hlos_hs_$(SOC)_CORELIST

# SBL CUST LIB with NON-DMA
export sbl_lib_cust_nondma_COMP_LIST = sbl_lib_cust_nondma
sbl_lib_cust_nondma_RELPATH = ti/boot/sbl
export sbl_lib_cust_nondma_OBJPATH = ti/boot/sbl/cust_nondma
sbl_lib_cust_nondma_PATH = $(PDK_SBL_COMP_PATH)
export sbl_lib_cust_nondma_LIBNAME = sbl_lib_cust_nondma
export sbl_lib_cust_nondma_LIBPATH = $(PDK_SBL_COMP_PATH)/lib/cust_nondma
export sbl_lib_cust_nondma_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_lib.mk BOOTMODE=cust SBL_USE_DMA=no CUST_SBL_FLAGS=$(CUST_SBL_TEST_FLAGS)
export sbl_lib_cust_nondma_BOARD_DEPENDENCY = yes
export sbl_lib_cust_nondma_SOC_DEPENDENCY = yes
export sbl_lib_cust_nondma_CORE_DEPENDENCY = no
sbl_lib_cust_nondma_PKG_LIST = sbl_lib_cust_nondma
sbl_lib_cust_nondma_INCLUDE = $(sbl_lib_cust_nondma_PATH)
export sbl_lib_cust_nondma_SOCLIST = $(sbl_SOCLIST)
export sbl_lib_cust_nondma_BOARDLIST = $(sbl_BOARDLIST)
export sbl_lib_cust_nondma_$(SOC)_CORELIST = mcu1_0

# SBL CUST LIB with NON-DMA - HS build variant
export sbl_lib_cust_nondma_hs_COMP_LIST = sbl_lib_cust_nondma_hs
sbl_lib_cust_nondma_hs_RELPATH = ti/boot/sbl
export sbl_lib_cust_nondma_hs_OBJPATH = ti/boot/sbl/cust_nondma_hs
sbl_lib_cust_nondma_hs_PATH = $(PDK_SBL_COMP_PATH)
export sbl_lib_cust_nondma_hs_LIBNAME = sbl_lib_cust_nondma_hs
export sbl_lib_cust_nondma_hs_LIBPATH = $(PDK_SBL_COMP_PATH)/lib/cust_nondma_hs
export sbl_lib_cust_nondma_hs_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_lib.mk BOOTMODE=cust SBL_USE_DMA=no CUST_SBL_FLAGS=$(CUST_SBL_TEST_FLAGS) BUILD_HS=yes
export sbl_lib_cust_nondma_hs_BOARD_DEPENDENCY = yes
export sbl_lib_cust_nondma_hs_SOC_DEPENDENCY = yes
export sbl_lib_cust_nondma_hs_CORE_DEPENDENCY = no
sbl_lib_cust_nondma_hs_PKG_LIST = sbl_lib_cust_nondma_hs
sbl_lib_cust_nondma_hs_INCLUDE = $(sbl_lib_cust_nondma_hs_PATH)
export sbl_lib_cust_nondma_hs_SOCLIST = $(sbl_SOCLIST)
export sbl_lib_cust_nondma_hs_BOARDLIST = $(sbl_BOARDLIST)
export sbl_lib_cust_nondma_hs_$(SOC)_CORELIST = mcu1_0

# SBL HYPERFLASH LIB
sbl_lib_hyperflash_COMP_LIST = sbl_lib_hyperflash
sbl_lib_hyperflash_RELPATH = ti/boot/sbl
export sbl_lib_hyperflash_OBJPATH = ti/boot/sbl/hyperflash
sbl_lib_hyperflash_LIBNAME = sbl_lib_hyperflash
sbl_lib_hyperflash_PATH = $(PDK_SBL_COMP_PATH)
sbl_lib_hyperflash_LIBPATH = $(PDK_SBL_COMP_PATH)/lib/hyperflash
sbl_lib_hyperflash_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_lib.mk BOOTMODE=hyperflash SBL_USE_DMA=yes
export sbl_lib_hyperflash_MAKEFILE
export sbl_lib_hyperflash_LIBNAME
export sbl_lib_hyperflash_LIBPATH
sbl_lib_hyperflash_BOARD_DEPENDENCY = yes
sbl_lib_hyperflash_SOC_DEPENDENCY = yes
sbl_lib_hyperflash_CORE_DEPENDENCY = no
export sbl_lib_hyperflash_COMP_LIST
export sbl_lib_hyperflash_BOARD_DEPENDENCY
export sbl_lib_hyperflash_CORE_DEPENDENCY
sbl_lib_hyperflash_PKG_LIST = sbl_lib_hyperflash
sbl_lib_hyperflash_INCLUDE = $(sbl_lib_hyperflash_PATH)
sbl_lib_hyperflash_SOCLIST = j721e
sbl_lib_hyperflash_BOARDLIST = j721e_evm
export sbl_lib_hyperflash_SOCLIST
export sbl_lib_hyperflash_BOARDLIST
sbl_lib_hyperflash_$(SOC)_CORELIST = mcu1_0
export sbl_lib_hyperflash_$(SOC)_CORELIST

# SBL HYPERFLASH LIB - HS build variant
sbl_lib_hyperflash_hs_COMP_LIST = sbl_lib_hyperflash_hs
sbl_lib_hyperflash_hs_RELPATH = ti/boot/sbl
export sbl_lib_hyperflash_hs_OBJPATH = ti/boot/sbl/hyperflash_hs
sbl_lib_hyperflash_hs_LIBNAME = sbl_lib_hyperflash_hs
sbl_lib_hyperflash_hs_PATH = $(PDK_SBL_COMP_PATH)
sbl_lib_hyperflash_hs_LIBPATH = $(PDK_SBL_COMP_PATH)/lib/hyperflash_hs
sbl_lib_hyperflash_hs_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_lib.mk BOOTMODE=hyperflash SBL_USE_DMA=yes BUILD_HS=yes
export sbl_lib_hyperflash_hs_MAKEFILE
export sbl_lib_hyperflash_hs_LIBNAME
export sbl_lib_hyperflash_hs_LIBPATH
sbl_lib_hyperflash_hs_BOARD_DEPENDENCY = yes
sbl_lib_hyperflash_hs_SOC_DEPENDENCY = yes
sbl_lib_hyperflash_hs_CORE_DEPENDENCY = no
export sbl_lib_hyperflash_hs_COMP_LIST
export sbl_lib_hyperflash_hs_BOARD_DEPENDENCY
export sbl_lib_hyperflash_hs_CORE_DEPENDENCY
sbl_lib_hyperflash_hs_PKG_LIST = sbl_lib_hyperflash_hs
sbl_lib_hyperflash_hs_INCLUDE = $(sbl_lib_hyperflash_hs_PATH)
sbl_lib_hyperflash_hs_SOCLIST = j721e
sbl_lib_hyperflash_hs_BOARDLIST = j721e_evm
export sbl_lib_hyperflash_hs_SOCLIST
export sbl_lib_hyperflash_hs_BOARDLIST
sbl_lib_hyperflash_hs_$(SOC)_CORELIST = mcu1_0
export sbl_lib_hyperflash_hs_$(SOC)_CORELIST

# SBL HYPERFLASH HLOS LIB
sbl_lib_hyperflash_hlos_COMP_LIST = sbl_lib_hyperflash_hlos
sbl_lib_hyperflash_hlos_RELPATH = ti/boot/sbl
export sbl_lib_hyperflash_hlos_OBJPATH = ti/boot/sbl/hyperflash_hlos
sbl_lib_hyperflash_hlos_LIBNAME = sbl_lib_hyperflash_hlos
sbl_lib_hyperflash_hlos_PATH = $(PDK_SBL_COMP_PATH)
sbl_lib_hyperflash_hlos_LIBPATH = $(PDK_SBL_COMP_PATH)/lib/hyperflash_hlos
sbl_lib_hyperflash_hlos_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_lib.mk BOOTMODE=hyperflash HLOS_BOOT=yes SBL_USE_DMA=yes
export sbl_lib_hyperflash_hlos_MAKEFILE
export sbl_lib_hyperflash_hlos_LIBNAME
export sbl_lib_hyperflash_hlos_LIBPATH
sbl_lib_hyperflash_hlos_BOARD_DEPENDENCY = yes
sbl_lib_hyperflash_hlos_SOC_DEPENDENCY = yes
sbl_lib_hyperflash_hlos_CORE_DEPENDENCY = no
export sbl_lib_hyperflash_hlos_COMP_LIST
export sbl_lib_hyperflash_hlos_BOARD_DEPENDENCY
export sbl_lib_hyperflash_hlos_CORE_DEPENDENCY
sbl_lib_hyperflash_hlos_PKG_LIST = sbl_lib_hyperflash_hlos
sbl_lib_hyperflash_hlos_INCLUDE = $(sbl_lib_hyperflash_hlos_PATH)
sbl_lib_hyperflash_hlos_SOCLIST = j721e
sbl_lib_hyperflash_hlos_BOARDLIST = j721e_evm
export sbl_lib_hyperflash_hlos_SOCLIST
export sbl_lib_hyperflash_hlos_BOARDLIST
sbl_lib_hyperflash_hlos_$(SOC)_CORELIST = mcu1_0
export sbl_lib_hyperflash_hlos_$(SOC)_CORELIST

# SBL HYPERFLASH HLOS LIB - HS build variant
sbl_lib_hyperflash_hlos_hs_COMP_LIST = sbl_lib_hyperflash_hlos_hs
sbl_lib_hyperflash_hlos_hs_RELPATH = ti/boot/sbl
export sbl_lib_hyperflash_hlos_hs_OBJPATH = ti/boot/sbl/hyperflash_hlos_hs
sbl_lib_hyperflash_hlos_hs_LIBNAME = sbl_lib_hyperflash_hlos_hs
sbl_lib_hyperflash_hlos_hs_PATH = $(PDK_SBL_COMP_PATH)
sbl_lib_hyperflash_hlos_hs_LIBPATH = $(PDK_SBL_COMP_PATH)/lib/hyperflash_hlos_hs
sbl_lib_hyperflash_hlos_hs_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_lib.mk BOOTMODE=hyperflash HLOS_BOOT=yes SBL_USE_DMA=yes BUILD_HS=yes
export sbl_lib_hyperflash_hlos_hs_MAKEFILE
export sbl_lib_hyperflash_hlos_hs_LIBNAME
export sbl_lib_hyperflash_hlos_hs_LIBPATH
sbl_lib_hyperflash_hlos_hs_BOARD_DEPENDENCY = yes
sbl_lib_hyperflash_hlos_hs_SOC_DEPENDENCY = yes
sbl_lib_hyperflash_hlos_hs_CORE_DEPENDENCY = no
export sbl_lib_hyperflash_hlos_hs_COMP_LIST
export sbl_lib_hyperflash_hlos_hs_BOARD_DEPENDENCY
export sbl_lib_hyperflash_hlos_hs_CORE_DEPENDENCY
sbl_lib_hyperflash_hlos_hs_PKG_LIST = sbl_lib_hyperflash_hlos_hs
sbl_lib_hyperflash_hlos_hs_INCLUDE = $(sbl_lib_hyperflash_hlos_hs_PATH)
sbl_lib_hyperflash_hlos_hs_SOCLIST = j721e
sbl_lib_hyperflash_hlos_hs_BOARDLIST = j721e_evm
export sbl_lib_hyperflash_hlos_hs_SOCLIST
export sbl_lib_hyperflash_hlos_hs_BOARDLIST
sbl_lib_hyperflash_hlos_hs_$(SOC)_CORELIST = mcu1_0
export sbl_lib_hyperflash_hlos_hs_$(SOC)_CORELIST

# SBL UART LIB
sbl_lib_uart_COMP_LIST = sbl_lib_uart
sbl_lib_uart_RELPATH = ti/boot/sbl
export sbl_lib_uart_OBJPATH = ti/boot/sbl/uart
sbl_lib_uart_LIBNAME = sbl_lib_uart
sbl_lib_uart_PATH = $(PDK_SBL_COMP_PATH)
sbl_lib_uart_LIBNAME = sbl_lib_uart
sbl_lib_uart_LIBPATH = $(PDK_SBL_COMP_PATH)/lib/uart
sbl_lib_uart_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_lib.mk BOOTMODE=uart SBL_USE_DMA=yes
export sbl_lib_uart_MAKEFILE
export sbl_lib_uart_LIBNAME
export sbl_lib_uart_LIBPATH
sbl_lib_uart_BOARD_DEPENDENCY = yes
sbl_lib_uart_SOC_DEPENDENCY = yes
sbl_lib_uart_CORE_DEPENDENCY = no
export sbl_lib_uart_COMP_LIST
export sbl_lib_uart_BOARD_DEPENDENCY
export sbl_lib_uart_CORE_DEPENDENCY
sbl_lib_uart_PKG_LIST = sbl_lib_uart
sbl_lib_uart_INCLUDE = $(sbl_lib_uart_PATH)
sbl_lib_uart_SOCLIST = $(sbl_SOCLIST)
sbl_lib_uart_BOARDLIST = $(sbl_BOARDLIST)
export sbl_lib_uart_SOCLIST
export sbl_lib_uart_BOARDLIST
sbl_lib_uart_$(SOC)_CORELIST = mcu1_0
export sbl_lib_uart_$(SOC)_CORELIST

# SBL UART LIB - HS build variant
sbl_lib_uart_hs_COMP_LIST = sbl_lib_uart_hs
sbl_lib_uart_hs_RELPATH = ti/boot/sbl
export sbl_lib_uart_hs_OBJPATH = ti/boot/sbl/uart_hs
sbl_lib_uart_hs_LIBNAME = sbl_lib_uart_hs
sbl_lib_uart_hs_PATH = $(PDK_SBL_COMP_PATH)
sbl_lib_uart_hs_LIBNAME = sbl_lib_uart_hs
sbl_lib_uart_hs_LIBPATH = $(PDK_SBL_COMP_PATH)/lib/uart_hs
sbl_lib_uart_hs_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_lib.mk BOOTMODE=uart SBL_USE_DMA=yes BUILD_HS=yes
export sbl_lib_uart_hs_MAKEFILE
export sbl_lib_uart_hs_LIBNAME
export sbl_lib_uart_hs_LIBPATH
sbl_lib_uart_hs_BOARD_DEPENDENCY = yes
sbl_lib_uart_hs_SOC_DEPENDENCY = yes
sbl_lib_uart_hs_CORE_DEPENDENCY = no
export sbl_lib_uart_hs_COMP_LIST
export sbl_lib_uart_hs_BOARD_DEPENDENCY
export sbl_lib_uart_hs_CORE_DEPENDENCY
sbl_lib_uart_hs_PKG_LIST = sbl_lib_uart_hs
sbl_lib_uart_hs_INCLUDE = $(sbl_lib_uart_hs_PATH)
sbl_lib_uart_hs_SOCLIST = $(sbl_SOCLIST)
sbl_lib_uart_hs_BOARDLIST = $(sbl_BOARDLIST)
export sbl_lib_uart_hs_SOCLIST
export sbl_lib_uart_hs_BOARDLIST
sbl_lib_uart_hs_$(SOC)_CORELIST = mcu1_0
export sbl_lib_uart_hs_$(SOC)_CORELIST

#
# SBL Examples
#
# SBL MMCSD Image
sbl_mmcsd_img_COMP_LIST = sbl_mmcsd_img
sbl_mmcsd_img_RELPATH = ti/boot/sbl/board/k3
sbl_mmcsd_img_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)/mmcsd/bin
sbl_mmcsd_img_PATH = $(PDK_SBL_COMP_PATH)/board/k3
sbl_mmcsd_img_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=mmcsd SBL_USE_DMA=yes BUILD_HS=no
export sbl_mmcsd_img_MAKEFILE
export sbl_mmcsd_img_SBL_CERT_KEY=$(SBL_CERT_KEY)
sbl_mmcsd_img_BOARD_DEPENDENCY = yes
sbl_mmcsd_img_SOC_DEPENDENCY = yes
sbl_mmcsd_img_CORE_DEPENDENCY = no
export sbl_mmcsd_img_COMP_LIST
export sbl_mmcsd_img_BOARD_DEPENDENCY
export sbl_mmcsd_img_SOC_DEPENDENCY
export sbl_mmcsd_img_CORE_DEPENDENCY
sbl_mmcsd_img_PKG_LIST = sbl
sbl_mmcsd_img_INCLUDE = $(sbl_mmcsd_img_PATH)
sbl_mmcsd_img_BOARDLIST = $(sbl_BOARDLIST)
export sbl_mmcsd_img_BOARDLIST
sbl_mmcsd_img_$(SOC)_CORELIST = mcu1_0
export sbl_mmcsd_img_$(SOC)_CORELIST
sbl_mmcsd_img_SBL_IMAGEGEN = yes
export sbl_mmcsd_img_SBL_IMAGEGEN

# SBL MMCSD Image - Combined boot image
sbl_mmcsd_img_combined_COMP_LIST = sbl_mmcsd_img_combined
sbl_mmcsd_img_combined_RELPATH = ti/boot/sbl/board/k3
sbl_mmcsd_img_combined_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)/mmcsd/bin
sbl_mmcsd_img_combined_PATH = $(PDK_SBL_COMP_PATH)/board/k3
sbl_mmcsd_img_combined_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=mmcsd SBL_USE_DMA=yes BUILD_HS=no SBL_IMAGE_TYPE=combined
export sbl_mmcsd_img_combined_MAKEFILE
export sbl_mmcsd_img_combined_SBL_CERT_KEY=$(SBL_CERT_KEY)
sbl_mmcsd_img_combined_BOARD_DEPENDENCY = yes
sbl_mmcsd_img_combined_SOC_DEPENDENCY = yes
sbl_mmcsd_img_combined_CORE_DEPENDENCY = no
export sbl_mmcsd_img_combined_COMP_LIST
export sbl_mmcsd_img_combined_BOARD_DEPENDENCY
export sbl_mmcsd_img_combined_SOC_DEPENDENCY
export sbl_mmcsd_img_combined_CORE_DEPENDENCY
sbl_mmcsd_img_combined_PKG_LIST = sbl
sbl_mmcsd_img_combined_INCLUDE = $(sbl_mmcsd_img_combined_PATH)
sbl_mmcsd_img_combined_BOARDLIST = j7200_evm j721s2_evm j784s4_evm j742s2_evm
export sbl_mmcsd_img_combined_BOARDLIST
sbl_mmcsd_img_combined_$(SOC)_CORELIST = mcu1_0
export sbl_mmcsd_img_combined_$(SOC)_CORELIST
sbl_mmcsd_img_combined_SBL_IMAGEGEN = yes
export sbl_mmcsd_img_combined_SBL_IMAGEGEN

# SBL MMCSD Image - Combined boot image for HS-FS device
sbl_mmcsd_img_combined_hs_fs_COMP_LIST = sbl_mmcsd_img_combined_hs_fs
sbl_mmcsd_img_combined_hs_fs_RELPATH = ti/boot/sbl/board/k3
sbl_mmcsd_img_combined_hs_fs_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)_hs_fs/mmcsd/bin
sbl_mmcsd_img_combined_hs_fs_PATH = $(PDK_SBL_COMP_PATH)/board/k3
sbl_mmcsd_img_combined_hs_fs_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=mmcsd SBL_USE_DMA=yes SBL_IMAGE_TYPE=combined BUILD_HS_FS=yes
export sbl_mmcsd_img_combined_hs_fs_MAKEFILE
export sbl_mmcsd_img_combined_hs_fs_SBL_CERT_KEY=$(SBL_CERT_KEY)
sbl_mmcsd_img_combined_hs_fs_BOARD_DEPENDENCY = yes
sbl_mmcsd_img_combined_hs_fs_SOC_DEPENDENCY = yes
sbl_mmcsd_img_combined_hs_fs_CORE_DEPENDENCY = no
export sbl_mmcsd_img_combined_hs_fs_COMP_LIST
export sbl_mmcsd_img_combined_hs_fs_BOARD_DEPENDENCY
export sbl_mmcsd_img_combined_hs_fs_SOC_DEPENDENCY
export sbl_mmcsd_img_combined_hs_fs_CORE_DEPENDENCY
sbl_mmcsd_img_combined_hs_fs_PKG_LIST = sbl
sbl_mmcsd_img_combined_hs_fs_INCLUDE = $(sbl_mmcsd_img_combined_hs_fs_PATH)
sbl_mmcsd_img_combined_hs_fs_BOARDLIST = j7200_evm j721s2_evm j784s4_evm j742s2_evm
export sbl_mmcsd_img_combined_hs_fs_BOARDLIST
sbl_mmcsd_img_combined_hs_fs_$(SOC)_CORELIST = mcu1_0
export sbl_mmcsd_img_combined_hs_fs_$(SOC)_CORELIST
sbl_mmcsd_img_combined_hs_fs_SBL_IMAGEGEN = yes
export sbl_mmcsd_img_combined_hs_fs_SBL_IMAGEGEN

# SBL MMCSD "HLOS Boot" Image
sbl_mmcsd_img_hlos_COMP_LIST = sbl_mmcsd_img_hlos
sbl_mmcsd_img_hlos_RELPATH = ti/boot/sbl/board/k3
sbl_mmcsd_img_hlos_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)/mmcsd/bin
sbl_mmcsd_img_hlos_PATH = $(PDK_SBL_COMP_PATH)/board/k3
sbl_mmcsd_img_hlos_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=mmcsd HLOS_BOOT=yes SBL_USE_DMA=yes BUILD_HS=no
export sbl_mmcsd_img_hlos_MAKEFILE
export sbl_mmcsd_img_hlos_SBL_CERT_KEY=$(SBL_CERT_KEY)
sbl_mmcsd_img_hlos_BOARD_DEPENDENCY = yes
sbl_mmcsd_img_hlos_SOC_DEPENDENCY = yes
sbl_mmcsd_img_hlos_CORE_DEPENDENCY = no
export sbl_mmcsd_img_hlos_COMP_LIST
export sbl_mmcsd_img_hlos_BOARD_DEPENDENCY
export sbl_mmcsd_img_hlos_SOC_DEPENDENCY
export sbl_mmcsd_img_hlos_CORE_DEPENDENCY
sbl_mmcsd_img_hlos_PKG_LIST = sbl
sbl_mmcsd_img_hlos_INCLUDE = $(sbl_mmcsd_img_hlos_PATH)
sbl_mmcsd_img_hlos_BOARDLIST = $(sbl_BOARDLIST)
export sbl_mmcsd_img_hlos_BOARDLIST
sbl_mmcsd_img_hlos_$(SOC)_CORELIST = mcu1_0
export sbl_mmcsd_img_hlos_$(SOC)_CORELIST
sbl_mmcsd_img_hlos_SBL_IMAGEGEN = yes
export sbl_mmcsd_img_hlos_SBL_IMAGEGEN

# SBL MMCSD Image - For HS build
export sbl_mmcsd_img_hs_COMP_LIST = sbl_mmcsd_img_hs
sbl_mmcsd_img_hs_RELPATH = ti/boot/sbl/board/k3
sbl_mmcsd_img_hs_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)_hs/mmcsd/bin
sbl_mmcsd_img_hs_PATH = $(PDK_SBL_COMP_PATH)/board/k3
export sbl_mmcsd_img_hs_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=mmcsd SBL_USE_DMA=yes BUILD_HS=yes
export sbl_mmcsd_img_hs_SBL_CERT_KEY=$(SBL_CERT_KEY_HS)
export sbl_mmcsd_img_hs_BOARD_DEPENDENCY = yes
export sbl_mmcsd_img_hs_SOC_DEPENDENCY = yes
export sbl_mmcsd_img_hs_CORE_DEPENDENCY = no
sbl_mmcsd_img_hs_PKG_LIST = sbl
sbl_mmcsd_img_hs_INCLUDE = $(sbl_mmcsd_img_hs_PATH)
export sbl_mmcsd_img_hs_BOARDLIST = $(sbl_BOARDLIST)
export sbl_mmcsd_img_hs_$(SOC)_CORELIST = mcu1_0
export sbl_mmcsd_img_hs_SBL_IMAGEGEN = yes

# SBL MMCSD Image - Combined boot image for HS build
export sbl_mmcsd_img_combined_hs_COMP_LIST = sbl_mmcsd_img_combined_hs
sbl_mmcsd_img_combined_hs_RELPATH = ti/boot/sbl/board/k3
sbl_mmcsd_img_combined_hs_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)_hs/mmcsd/bin
sbl_mmcsd_img_combined_hs_PATH = $(PDK_SBL_COMP_PATH)/board/k3
export sbl_mmcsd_img_combined_hs_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=mmcsd SBL_USE_DMA=yes SBL_IMAGE_TYPE=combined BUILD_HS=yes
export sbl_mmcsd_img_combined_hs_SBL_CERT_KEY=$(SBL_CERT_KEY_HS)
export sbl_mmcsd_img_combined_hs_BOARD_DEPENDENCY = yes
export sbl_mmcsd_img_combined_hs_SOC_DEPENDENCY = yes
export sbl_mmcsd_img_combined_hs_CORE_DEPENDENCY = no
sbl_mmcsd_img_combined_hs_PKG_LIST = sbl
sbl_mmcsd_img_combined_hs_INCLUDE = $(sbl_mmcsd_img_combined_hs_PATH)
export sbl_mmcsd_img_combined_hs_BOARDLIST = j7200_evm j721s2_evm j784s4_evm j742s2_evm
export sbl_mmcsd_img_combined_hs_$(SOC)_CORELIST = mcu1_0
export sbl_mmcsd_img_combined_hs_SBL_IMAGEGEN = yes

# SBL MMCSD "HLOS Boot" Image - For HS build
export sbl_mmcsd_img_hlos_hs_COMP_LIST = sbl_mmcsd_img_hlos_hs
sbl_mmcsd_img_hlos_hs_RELPATH = ti/boot/sbl/board/k3
sbl_mmcsd_img_hlos_hs_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)_hs/mmcsd/bin
sbl_mmcsd_img_hlos_hs_PATH = $(PDK_SBL_COMP_PATH)/board/k3
export sbl_mmcsd_img_hlos_hs_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=mmcsd HLOS_BOOT=yes SBL_USE_DMA=yes BUILD_HS=yes
export sbl_mmcsd_img_hlos_hs_SBL_CERT_KEY=$(SBL_CERT_KEY_HS)
export sbl_mmcsd_img_hlos_hs_BOARD_DEPENDENCY = yes
export sbl_mmcsd_img_hlos_hs_SOC_DEPENDENCY = yes
export sbl_mmcsd_img_hlos_hs_CORE_DEPENDENCY = no
sbl_mmcsd_img_hlos_hs_PKG_LIST = sbl
sbl_mmcsd_img_hlos_hs_INCLUDE = $(sbl_mmcsd_img_hlos_hs_PATH)
export sbl_mmcsd_img_hlos_hs_BOARDLIST = $(sbl_BOARDLIST)
export sbl_mmcsd_img_hlos_hs_$(SOC)_CORELIST = mcu1_0
export sbl_mmcsd_img_hlos_hs_SBL_IMAGEGEN = yes

# SBL EMMC Image - Boot from UDA
sbl_emmc_uda_img_COMP_LIST = sbl_emmc_uda_img
sbl_emmc_uda_img_RELPATH = ti/boot/sbl/board/k3
sbl_emmc_uda_img_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)/emmc_uda/bin
sbl_emmc_uda_img_PATH = $(PDK_SBL_COMP_PATH)/board/k3
sbl_emmc_uda_img_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=emmc SBL_USE_DMA=yes BUILD_HS=no EMMC_BOOT0=no
export sbl_emmc_uda_img_MAKEFILE
export sbl_emmc_uda_img_SBL_CERT_KEY=$(SBL_CERT_KEY)
sbl_emmc_uda_img_BOARD_DEPENDENCY = yes
sbl_emmc_uda_img_SOC_DEPENDENCY = yes
sbl_emmc_uda_img_CORE_DEPENDENCY = no
export sbl_emmc_uda_img_COMP_LIST
export sbl_emmc_uda_img_BOARD_DEPENDENCY
export sbl_emmc_uda_img_SOC_DEPENDENCY
export sbl_emmc_uda_img_CORE_DEPENDENCY
sbl_emmc_uda_img_PKG_LIST = sbl
sbl_emmc_uda_img_INCLUDE = $(sbl_emmc_uda_img_PATH)
sbl_emmc_uda_img_BOARDLIST = $(sbl_BOARDLIST)
export sbl_emmc_uda_img_BOARDLIST
sbl_emmc_uda_img_$(SOC)_CORELIST = mcu1_0
export sbl_emmc_uda_img_$(SOC)_CORELIST
sbl_emmc_uda_img_SBL_IMAGEGEN = yes
export sbl_emmc_uda_img_SBL_IMAGEGEN

# SBL EMMC Image - Boot from BOOT0
sbl_emmc_boot0_img_COMP_LIST = sbl_emmc_boot0_img
sbl_emmc_boot0_img_RELPATH = ti/boot/sbl/board/k3
sbl_emmc_boot0_img_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)/emmc_boot0/bin
sbl_emmc_boot0_img_PATH = $(PDK_SBL_COMP_PATH)/board/k3
sbl_emmc_boot0_img_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=emmc SBL_USE_DMA=yes BUILD_HS=no EMMC_BOOT0=yes
export sbl_emmc_boot0_img_MAKEFILE
export sbl_emmc_boot0_img_SBL_CERT_KEY=$(SBL_CERT_KEY)
sbl_emmc_boot0_img_BOARD_DEPENDENCY = yes
sbl_emmc_boot0_img_SOC_DEPENDENCY = yes
sbl_emmc_boot0_img_CORE_DEPENDENCY = no
export sbl_emmc_boot0_img_COMP_LIST
export sbl_emmc_boot0_img_BOARD_DEPENDENCY
export sbl_emmc_boot0_img_SOC_DEPENDENCY
export sbl_emmc_boot0_img_CORE_DEPENDENCY
sbl_emmc_boot0_img_PKG_LIST = sbl
sbl_emmc_boot0_img_INCLUDE = $(sbl_emmc_boot0_img_PATH)
sbl_emmc_boot0_img_BOARDLIST = $(sbl_BOARDLIST)
export sbl_emmc_boot0_img_BOARDLIST
sbl_emmc_boot0_img_$(SOC)_CORELIST = mcu1_0
export sbl_emmc_boot0_img_$(SOC)_CORELIST
sbl_emmc_boot0_img_SBL_IMAGEGEN = yes
export sbl_emmc_boot0_img_SBL_IMAGEGEN

# SBL OSPI Image
sbl_ospi_img_COMP_LIST = sbl_ospi_img
sbl_ospi_img_RELPATH = ti/boot/sbl/board/k3
sbl_ospi_img_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)/ospi/bin
sbl_ospi_img_PATH = $(PDK_SBL_COMP_PATH)/board/k3
sbl_ospi_img_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=ospi SBL_USE_DMA=yes BUILD_HS=no
export sbl_ospi_img_MAKEFILE
export sbl_ospi_img_SBL_CERT_KEY=$(SBL_CERT_KEY)
sbl_ospi_img_BOARD_DEPENDENCY = yes
sbl_ospi_img_SOC_DEPENDENCY = yes
sbl_ospi_img_CORE_DEPENDENCY = no
export sbl_ospi_img_COMP_LIST
export sbl_ospi_img_BOARD_DEPENDENCY
export sbl_ospi_img_SOC_DEPENDENCY
export sbl_ospi_img_CORE_DEPENDENCY
sbl_ospi_img_PKG_LIST = sbl
sbl_ospi_img_INCLUDE = $(sbl_ospi_img_PATH)
sbl_ospi_img_BOARDLIST = $(sbl_BOARDLIST)
export sbl_ospi_img_BOARDLIST
sbl_ospi_img_$(SOC)_CORELIST = mcu1_0
export sbl_ospi_img_$(SOC)_CORELIST
sbl_ospi_img_SBL_IMAGEGEN = yes
export sbl_ospi_img_SBL_IMAGEGEN

# SBL OSPI NAND Image
# It uses sbl_lib_ospi if SBL_USE_DMA=yes and uses sbl_lib_ospi_nondma if SBL_USE_DMA=no
sbl_ospi_nand_img_COMP_LIST = sbl_ospi_nand_img
sbl_ospi_nand_img_RELPATH = ti/boot/sbl/board/k3
sbl_ospi_nand_img_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)/ospi_nand/bin
sbl_ospi_nand_img_PATH = $(PDK_SBL_COMP_PATH)/board/k3
sbl_ospi_nand_img_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=ospi OSPI_NAND=yes SBL_USE_DMA=yes BUILD_HS=no
export sbl_ospi_nand_img_MAKEFILE
export sbl_ospi_nand_img_SBL_CERT_KEY=$(SBL_CERT_KEY)
sbl_ospi_nand_img_BOARD_DEPENDENCY = yes
sbl_ospi_nand_img_SOC_DEPENDENCY = yes
sbl_ospi_nand_img_CORE_DEPENDENCY = no
export sbl_ospi_nand_img_COMP_LIST
export sbl_ospi_nand_img_BOARD_DEPENDENCY
export sbl_ospi_nand_img_SOC_DEPENDENCY
export sbl_ospi_nand_img_CORE_DEPENDENCY
sbl_ospi_nand_img_PKG_LIST = sbl
sbl_ospi_nand_img_INCLUDE = $(sbl_ospi_nand_img_PATH)
sbl_ospi_nand_img_BOARDLIST = j721s2_evm j784s4_evm j742s2_evm
export sbl_ospi_nand_img_BOARDLIST
sbl_ospi_nand_img_$(SOC)_CORELIST = mcu1_0
export sbl_ospi_nand_img_$(SOC)_CORELIST
sbl_ospi_nand_img_SBL_IMAGEGEN = yes
export sbl_ospi_nand_img_SBL_IMAGEGEN

# SBL OSPI - Combined boot image
sbl_ospi_img_combined_COMP_LIST = sbl_ospi_img_combined
sbl_ospi_img_combined_RELPATH = ti/boot/sbl/board/k3
sbl_ospi_img_combined_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)/ospi/bin
sbl_ospi_img_combined_PATH = $(PDK_SBL_COMP_PATH)/board/k3
sbl_ospi_img_combined_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=ospi SBL_USE_DMA=yes BUILD_HS=no SBL_IMAGE_TYPE=combined
export sbl_ospi_img_combined_MAKEFILE
export sbl_ospi_img_combined_SBL_CERT_KEY=$(SBL_CERT_KEY)
sbl_ospi_img_combined_BOARD_DEPENDENCY = yes
sbl_ospi_img_combined_SOC_DEPENDENCY = yes
sbl_ospi_img_combined_CORE_DEPENDENCY = no
export sbl_ospi_img_combined_COMP_LIST
export sbl_ospi_img_combined_BOARD_DEPENDENCY
export sbl_ospi_img_combined_SOC_DEPENDENCY
export sbl_ospi_img_combined_CORE_DEPENDENCY
sbl_ospi_img_combined_PKG_LIST = sbl
sbl_ospi_img_combined_INCLUDE = $(sbl_ospi_img_combined_PATH)
sbl_ospi_img_combined_BOARDLIST = j7200_evm j721s2_evm j784s4_evm j742s2_evm
export sbl_ospi_img_combined_BOARDLIST
sbl_ospi_img_combined_$(SOC)_CORELIST = mcu1_0
export sbl_ospi_img_combined_$(SOC)_CORELIST
sbl_ospi_img_combined_SBL_IMAGEGEN = yes
export sbl_ospi_img_combined_SBL_IMAGEGEN

# SBL OSPI - Combined boot image for HS-FS devices
sbl_ospi_img_combined_hs_fs_COMP_LIST = sbl_ospi_img_combined_hs_fs
sbl_ospi_img_combined_hs_fs_RELPATH = ti/boot/sbl/board/k3
sbl_ospi_img_combined_hs_fs_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)_hs_fs/ospi/bin
sbl_ospi_img_combined_hs_fs_PATH = $(PDK_SBL_COMP_PATH)/board/k3
sbl_ospi_img_combined_hs_fs_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=ospi SBL_USE_DMA=yes SBL_IMAGE_TYPE=combined BUILD_HS_FS=yes
export sbl_ospi_img_combined_hs_fs_MAKEFILE
export sbl_ospi_img_combined_hs_fs_SBL_CERT_KEY=$(SBL_CERT_KEY)
sbl_ospi_img_combined_hs_fs_BOARD_DEPENDENCY = yes
sbl_ospi_img_combined_hs_fs_SOC_DEPENDENCY = yes
sbl_ospi_img_combined_hs_fs_CORE_DEPENDENCY = no
export sbl_ospi_img_combined_hs_fs_COMP_LIST
export sbl_ospi_img_combined_hs_fs_BOARD_DEPENDENCY
export sbl_ospi_img_combined_hs_fs_SOC_DEPENDENCY
export sbl_ospi_img_combined_hs_fs_CORE_DEPENDENCY
sbl_ospi_img_combined_hs_fs_PKG_LIST = sbl
sbl_ospi_img_combined_hs_fs_INCLUDE = $(sbl_ospi_img_combined_hs_fs_PATH)
sbl_ospi_img_combined_hs_fs_BOARDLIST = j7200_evm j721s2_evm j784s4_evm j742s2_evm
export sbl_ospi_img_combined_hs_fs_BOARDLIST
sbl_ospi_img_combined_hs_fs_$(SOC)_CORELIST = mcu1_0
export sbl_ospi_img_combined_hs_fs_$(SOC)_CORELIST
sbl_ospi_img_combined_hs_fs_SBL_IMAGEGEN = yes
export sbl_ospi_img_combined_hs_fs_SBL_IMAGEGEN

# SBL CUST - Combined boot image
sbl_boot_perf_cust_img_combined_COMP_LIST = sbl_boot_perf_cust_img_combined
sbl_boot_perf_cust_img_combined_RELPATH = ti/boot/sbl/board/k3
sbl_boot_perf_cust_img_combined_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)/cust_combined/bin
sbl_boot_perf_cust_img_combined_PATH = $(PDK_SBL_COMP_PATH)/board/k3
sbl_boot_perf_cust_img_combined_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=cust BUILD_HS=no SBL_IMAGE_TYPE=combined CUST_SBL_FLAGS=$(CUST_SBL_BOOT_PERF_TEST_FLAGS) BOOT_PERF=yes
export sbl_boot_perf_cust_img_combined_MAKEFILE
export sbl_boot_perf_cust_img_combined_SBL_CERT_KEY=$(SBL_CERT_KEY)
sbl_boot_perf_cust_img_combined_BOARD_DEPENDENCY = yes
sbl_boot_perf_cust_img_combined_SOC_DEPENDENCY = yes
sbl_boot_perf_cust_img_combined_CORE_DEPENDENCY = no
export sbl_boot_perf_cust_img_combined_COMP_LIST
export sbl_boot_perf_cust_img_combined_BOARD_DEPENDENCY
export sbl_boot_perf_cust_img_combined_SOC_DEPENDENCY
export sbl_boot_perf_cust_img_combined_CORE_DEPENDENCY
sbl_boot_perf_cust_img_combined_PKG_LIST = sbl
sbl_boot_perf_cust_img_combined_INCLUDE = $(sbl_boot_perf_cust_img_combined_PATH)
sbl_boot_perf_cust_img_combined_BOARDLIST = j7200_evm j721s2_evm j784s4_evm j742s2_evm
export sbl_boot_perf_cust_img_combined_BOARDLIST
sbl_boot_perf_cust_img_combined_$(SOC)_CORELIST = mcu1_0
export sbl_boot_perf_cust_img_combined_$(SOC)_CORELIST
sbl_boot_perf_cust_img_combined_SBL_IMAGEGEN = yes
export sbl_boot_perf_cust_img_combined_SBL_IMAGEGEN

# SBL OSPI "HLOS Boot" Image
sbl_ospi_img_hlos_COMP_LIST = sbl_ospi_img_hlos
sbl_ospi_img_hlos_RELPATH = ti/boot/sbl/board/k3
sbl_ospi_img_hlos_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)/ospi/bin
sbl_ospi_img_hlos_PATH = $(PDK_SBL_COMP_PATH)/board/k3
sbl_ospi_img_hlos_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=ospi HLOS_BOOT=yes SBL_USE_DMA=yes BUILD_HS=no
export sbl_ospi_img_hlos_MAKEFILE
export sbl_ospi_img_hlos_SBL_CERT_KEY=$(SBL_CERT_KEY)
sbl_ospi_img_hlos_BOARD_DEPENDENCY = yes
sbl_ospi_img_hlos_SOC_DEPENDENCY = yes
sbl_ospi_img_hlos_CORE_DEPENDENCY = no
export sbl_ospi_img_hlos_COMP_LIST
export sbl_ospi_img_hlos_BOARD_DEPENDENCY
export sbl_ospi_img_hlos_SOC_DEPENDENCY
export sbl_ospi_img_hlos_CORE_DEPENDENCY
sbl_ospi_img_hlos_PKG_LIST = sbl
sbl_ospi_img_hlos_INCLUDE = $(sbl_ospi_img_hlos_PATH)
sbl_ospi_img_hlos_BOARDLIST = $(sbl_BOARDLIST)
export sbl_ospi_img_hlos_BOARDLIST
sbl_ospi_img_hlos_$(SOC)_CORELIST = mcu1_0
export sbl_ospi_img_hlos_$(SOC)_CORELIST
sbl_ospi_img_hlos_SBL_IMAGEGEN = yes
export sbl_ospi_img_hlos_SBL_IMAGEGEN

# SBL OSPI Image - For HS build
export sbl_ospi_img_hs_COMP_LIST = sbl_ospi_img_hs
sbl_ospi_img_hs_RELPATH = ti/boot/sbl/board/k3
sbl_ospi_img_hs_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)_hs/ospi/bin
sbl_ospi_img_hs_PATH = $(PDK_SBL_COMP_PATH)/board/k3
export sbl_ospi_img_hs_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=ospi SBL_USE_DMA=yes BUILD_HS=yes
export sbl_ospi_img_hs_SBL_CERT_KEY=$(SBL_CERT_KEY_HS)
export sbl_ospi_img_hs_BOARD_DEPENDENCY = yes
export sbl_ospi_img_hs_SOC_DEPENDENCY = yes
export sbl_ospi_img_hs_CORE_DEPENDENCY = no
sbl_ospi_img_hs_PKG_LIST = sbl
sbl_ospi_img_hs_INCLUDE = $(sbl_ospi_img_hs_PATH)
export sbl_ospi_img_hs_BOARDLIST = $(sbl_BOARDLIST)
export sbl_ospi_img_hs_$(SOC)_CORELIST = mcu1_0
export sbl_ospi_img_hs_SBL_IMAGEGEN = yes

# SBL OSPI NAND Image - For HS build
# It uses sbl_lib_ospi_hs if SBL_USE_DMA=yes and uses sbl_lib_ospi_nondma_hs if SBL_USE_DMA=no
export sbl_ospi_nand_img_hs_COMP_LIST = sbl_ospi_nand_img_hs
sbl_ospi_nand_img_hs_RELPATH = ti/boot/sbl/board/k3
sbl_ospi_nand_img_hs_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)_hs/ospi_nand/bin
sbl_ospi_nand_img_hs_PATH = $(PDK_SBL_COMP_PATH)/board/k3
export sbl_ospi_nand_img_hs_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=ospi OSPI_NAND=yes SBL_USE_DMA=yes BUILD_HS=yes
export sbl_ospi_nand_img_hs_SBL_CERT_KEY=$(SBL_CERT_KEY_HS)
export sbl_ospi_nand_img_hs_BOARD_DEPENDENCY = yes
export sbl_ospi_nand_img_hs_SOC_DEPENDENCY = yes
export sbl_ospi_nand_img_hs_CORE_DEPENDENCY = no
sbl_ospi_nand_img_hs_PKG_LIST = sbl
sbl_ospi_nand_img_hs_INCLUDE = $(sbl_ospi_nand_img_hs_PATH)
export sbl_ospi_nand_img_hs_BOARDLIST = j721s2_evm
export sbl_ospi_nand_img_hs_$(SOC)_CORELIST = mcu1_0
export sbl_ospi_nand_img_hs_SBL_IMAGEGEN = yes

# SBL OSPI Image - Combined boot image for HS build
export sbl_ospi_img_combined_hs_COMP_LIST = sbl_ospi_img_combined_hs
sbl_ospi_img_combined_hs_RELPATH = ti/boot/sbl/board/k3
sbl_ospi_img_combined_hs_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)_hs/ospi/bin
sbl_ospi_img_combined_hs_PATH = $(PDK_SBL_COMP_PATH)/board/k3
export sbl_ospi_img_combined_hs_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=ospi SBL_USE_DMA=yes SBL_IMAGE_TYPE=combined BUILD_HS=yes
export sbl_ospi_img_combined_hs_SBL_CERT_KEY=$(SBL_CERT_KEY_HS)
export sbl_ospi_img_combined_hs_BOARD_DEPENDENCY = yes
export sbl_ospi_img_combined_hs_SOC_DEPENDENCY = yes
export sbl_ospi_img_combined_hs_CORE_DEPENDENCY = no
sbl_ospi_img_combined_hs_PKG_LIST = sbl
sbl_ospi_img_combined_hs_INCLUDE = $(sbl_ospi_img_combined_hs_PATH)
export sbl_ospi_img_combined_hs_BOARDLIST = j7200_evm j721s2_evm j784s4_evm j742s2_evm
export sbl_ospi_img_combined_hs_$(SOC)_CORELIST = mcu1_0
export sbl_ospi_img_combined_hs_SBL_IMAGEGEN = yes

# SBL OSPI "HLOS Boot" Image - For HS build
export sbl_ospi_img_hlos_hs_COMP_LIST = sbl_ospi_img_hlos_hs
sbl_ospi_img_hlos_hs_RELPATH = ti/boot/sbl/board/k3
sbl_ospi_img_hlos_hs_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)_hs/ospi/bin
sbl_ospi_img_hlos_hs_PATH = $(PDK_SBL_COMP_PATH)/board/k3
export sbl_ospi_img_hlos_hs_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=ospi HLOS_BOOT=yes SBL_USE_DMA=yes BUILD_HS=yes
export sbl_ospi_img_hlos_hs_SBL_CERT_KEY=$(SBL_CERT_KEY_HS)
export sbl_ospi_img_hlos_hs_BOARD_DEPENDENCY = yes
export sbl_ospi_img_hlos_hs_SOC_DEPENDENCY = yes
export sbl_ospi_img_hlos_hs_CORE_DEPENDENCY = no
sbl_ospi_img_hlos_hs_PKG_LIST = sbl
sbl_ospi_img_hlos_hs_INCLUDE = $(sbl_ospi_img_hlos_hs_PATH)
export sbl_ospi_img_hlos_hs_BOARDLIST = $(sbl_BOARDLIST)
export sbl_ospi_img_hlos_hs_$(SOC)_CORELIST = mcu1_0
export sbl_ospi_img_hlos_hs_SBL_IMAGEGEN = yes

# KEYWRITER Image
# SBL HYPERFLASH Image
sbl_hyperflash_img_COMP_LIST = sbl_hyperflash_img
sbl_hyperflash_img_RELPATH = ti/boot/sbl/board/k3
sbl_hyperflash_img_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)/hyperflash/bin
sbl_hyperflash_img_PATH = $(PDK_SBL_COMP_PATH)/board/k3
sbl_hyperflash_img_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=hyperflash SBL_USE_DMA=yes BUILD_HS=no
export sbl_hyperflash_img_SBL_CERT_KEY=$(SBL_CERT_KEY)
export sbl_hyperflash_img_MAKEFILE
sbl_hyperflash_img_BOARD_DEPENDENCY = yes
sbl_hyperflash_img_SOC_DEPENDENCY = yes
sbl_hyperflash_img_CORE_DEPENDENCY = no
export sbl_hyperflash_img_COMP_LIST
export sbl_hyperflash_img_BOARD_DEPENDENCY
export sbl_hyperflash_img_SOC_DEPENDENCY
export sbl_hyperflash_img_CORE_DEPENDENCY
sbl_hyperflash_img_PKG_LIST = sbl
sbl_hyperflash_img_INCLUDE = $(sbl_hyperflash_img_PATH)
sbl_hyperflash_img_BOARDLIST = j721e_evm
export sbl_hyperflash_img_BOARDLIST
sbl_hyperflash_img_$(SOC)_CORELIST = mcu1_0
export sbl_hyperflash_img_$(SOC)_CORELIST
sbl_hyperflash_img_SBL_IMAGEGEN = yes
export sbl_hyperflash_img_SBL_IMAGEGEN

# SBL HYPERFLASH "HLOS Boot" Image
sbl_hyperflash_img_hlos_COMP_LIST = sbl_hyperflash_img_hlos
sbl_hyperflash_img_hlos_RELPATH = ti/boot/sbl/board/k3
sbl_hyperflash_img_hlos_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)/hyperflash/bin
sbl_hyperflash_img_hlos_PATH = $(PDK_SBL_COMP_PATH)/board/k3
sbl_hyperflash_img_hlos_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=hyperflash HLOS_BOOT=yes SBL_USE_DMA=yes BUILD_HS=no
export sbl_hyperflash_img_hlos_SBL_CERT_KEY=$(SBL_CERT_KEY)
export sbl_hyperflash_img_hlos_MAKEFILE
sbl_hyperflash_img_hlos_BOARD_DEPENDENCY = yes
sbl_hyperflash_img_hlos_SOC_DEPENDENCY = yes
sbl_hyperflash_img_hlos_CORE_DEPENDENCY = no
export sbl_hyperflash_img_hlos_COMP_LIST
export sbl_hyperflash_img_hlos_BOARD_DEPENDENCY
export sbl_hyperflash_img_hlos_SOC_DEPENDENCY
export sbl_hyperflash_img_hlos_CORE_DEPENDENCY
sbl_hyperflash_img_hlos_PKG_LIST = sbl
sbl_hyperflash_img_hlos_INCLUDE = $(sbl_hyperflash_img_hlos_PATH)
sbl_hyperflash_img_hlos_BOARDLIST = j721e_evm
export sbl_hyperflash_img_hlos_BOARDLIST
sbl_hyperflash_img_hlos_$(SOC)_CORELIST = mcu1_0
export sbl_hyperflash_img_hlos_$(SOC)_CORELIST
sbl_hyperflash_img_hlos_SBL_IMAGEGEN = yes
export sbl_hyperflash_img_hlos_SBL_IMAGEGEN

# SBL HYPERFLASH Image - For HS build
export sbl_hyperflash_img_hs_COMP_LIST = sbl_hyperflash_img_hs
sbl_hyperflash_img_hs_RELPATH = ti/boot/sbl/board/k3
sbl_hyperflash_img_hs_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)_hs/hyperflash/bin
sbl_hyperflash_img_hs_PATH = $(PDK_SBL_COMP_PATH)/board/k3
export sbl_hyperflash_img_hs_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=hyperflash SBL_USE_DMA=yes BUILD_HS=yes
export sbl_hyperflash_img_hs_SBL_CERT_KEY=$(SBL_CERT_KEY_HS)
export sbl_hyperflash_img_hs_BOARD_DEPENDENCY = yes
export sbl_hyperflash_img_SOC_DEPENDENCY = yes
export sbl_hyperflash_img_hs_CORE_DEPENDENCY = no
sbl_hyperflash_img_hs_PKG_LIST = sbl
sbl_hyperflash_img_hs_INCLUDE = $(sbl_hyperflash_img_hs_PATH)
export sbl_hyperflash_img_hs_BOARDLIST = j721e_evm
export sbl_hyperflash_img_hs_$(SOC)_CORELIST = mcu1_0
export sbl_hyperflash_img_hs_SBL_IMAGEGEN = yes

# SBL HYPERFLASH "HLOS Boot" Image - For HS build
export sbl_hyperflash_img_hlos_hs_COMP_LIST = sbl_hyperflash_img_hlos_hs
sbl_hyperflash_img_hlos_hs_RELPATH = ti/boot/sbl/board/k3
sbl_hyperflash_img_hlos_hs_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)_hs/hyperflash/bin
sbl_hyperflash_img_hlos_hs_PATH = $(PDK_SBL_COMP_PATH)/board/k3
export sbl_hyperflash_img_hlos_hs_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=hyperflash HLOS_BOOT=yes SBL_USE_DMA=yes BUILD_HS=yes
export sbl_hyperflash_img_hlos_hs_SBL_CERT_KEY=$(SBL_CERT_KEY_HS)
export sbl_hyperflash_img_hlos_hs_BOARD_DEPENDENCY = yes
export sbl_hyperflash_img_hlos_SOC_DEPENDENCY = yes
export sbl_hyperflash_img_hlos_hs_CORE_DEPENDENCY = no
sbl_hyperflash_img_hlos_hs_PKG_LIST = sbl
sbl_hyperflash_img_hlos_hs_INCLUDE = $(sbl_hyperflash_img_hlos_hs_PATH)
export sbl_hyperflash_img_hlos_hs_BOARDLIST = j721e_evm
export sbl_hyperflash_img_hlos_hs_$(SOC)_CORELIST = mcu1_0
export sbl_hyperflash_img_hlos_hs_SBL_IMAGEGEN = yes

# SBL UART Image
sbl_uart_img_COMP_LIST = sbl_uart_img
sbl_uart_img_RELPATH = ti/boot/sbl/board/k3
sbl_uart_img_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)/uart/bin
sbl_uart_img_PATH = $(PDK_SBL_COMP_PATH)/board/k3
sbl_uart_img_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=uart SBL_USE_DMA=yes BUILD_HS=no
export sbl_uart_img_MAKEFILE
export sbl_uart_img_SBL_CERT_KEY=$(SBL_CERT_KEY)
sbl_uart_img_BOARD_DEPENDENCY = yes
sbl_uart_img_SOC_DEPENDENCY = yes
sbl_uart_img_CORE_DEPENDENCY = no
export sbl_uart_img_COMP_LIST
export sbl_uart_img_BOARD_DEPENDENCY
export sbl_uart_img_SOC_DEPENDENCY
export sbl_uart_img_CORE_DEPENDENCY
sbl_uart_img_PKG_LIST = sbl
sbl_uart_img_INCLUDE = $(sbl_uart_img_PATH)
sbl_uart_img_BOARDLIST = $(sbl_BOARDLIST)
export sbl_uart_img_BOARDLIST
sbl_uart_img_$(SOC)_CORELIST = mcu1_0
export sbl_uart_img_$(SOC)_CORELIST
sbl_uart_img_SBL_IMAGEGEN = yes
export sbl_uart_img_SBL_IMAGEGEN

# SBL UART Image - For HS build
export sbl_uart_img_hs_COMP_LIST = sbl_uart_img_hs
sbl_uart_img_hs_RELPATH = ti/boot/sbl/board/k3
sbl_uart_img_hs_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)_hs/uart/bin
sbl_uart_img_hs_PATH = $(PDK_SBL_COMP_PATH)/board/k3
export sbl_uart_img_hs_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=uart SBL_USE_DMA=yes BUILD_HS=yes
export sbl_uart_img_hs_SBL_CERT_KEY=$(SBL_CERT_KEY_HS)
export sbl_uart_img_hs_BOARD_DEPENDENCY = yes
export sbl_uart_img_hs_SOC_DEPENDENCY = yes
export sbl_uart_img_hs_CORE_DEPENDENCY = no
sbl_uart_img_hs_PKG_LIST = sbl
sbl_uart_img_hs_INCLUDE = $(sbl_uart_img_hs_PATH)
export sbl_uart_img_hs_BOARDLIST = $(sbl_BOARDLIST)
export sbl_uart_img_hs_$(SOC)_CORELIST = mcu1_0
export sbl_uart_img_hs_SBL_IMAGEGEN = yes

# SBL Boot HSM UART Image
export sbl_hsm_boot_uart_img_hs_COMP_LIST = sbl_hsm_boot_uart_img_hs
sbl_hsm_boot_uart_img_hs_RELPATH = ti/boot/sbl/board/k3
sbl_hsm_boot_uart_img_hs_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)_hs/uart/bin
sbl_hsm_boot_uart_img_hs_PATH = $(PDK_SBL_COMP_PATH)/board/k3
export sbl_hsm_boot_uart_img_hs_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=uart SBL_USE_DMA=yes BUILD_HS=yes SECURE_HSM_BOOT=yes
export sbl_hsm_boot_uart_img_hs_SBL_CERT_KEY=$(SBL_CERT_KEY_HS)
export sbl_hsm_boot_uart_img_hs_BOARD_DEPENDENCY = yes
export sbl_hsm_boot_uart_img_hs_SOC_DEPENDENCY = yes
export sbl_hsm_boot_uart_img_hs_CORE_DEPENDENCY = no
sbl_hsm_boot_uart_img_hs_PKG_LIST = sbl
sbl_hsm_boot_uart_img_hs_INCLUDE = $(sbl_hsm_boot_uart_img_hs_PATH)
export sbl_hsm_boot_uart_img_hs_BOARDLIST = j721s2_evm j784s4_evm j742s2_evm
export sbl_hsm_boot_uart_img_hs_$(SOC)_CORELIST = mcu1_0
export sbl_hsm_boot_uart_img_hs_SBL_IMAGEGEN = yes

# SBL Boot HSM UART Image
export sbl_hsm_boot_uart_img_COMP_LIST = sbl_hsm_boot_uart_img
sbl_hsm_boot_uart_img_RELPATH = ti/boot/sbl/board/k3
sbl_hsm_boot_uart_img_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)/uart/bin
sbl_hsm_boot_uart_img_PATH = $(PDK_SBL_COMP_PATH)/board/k3
export sbl_hsm_boot_uart_img_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=uart SBL_USE_DMA=yes BUILD_HS=no SECURE_HSM_BOOT=yes
export sbl_hsm_boot_uart_img_SBL_CERT_KEY=$(SBL_CERT_KEY)
export sbl_hsm_boot_uart_img_BOARD_DEPENDENCY = yes
export sbl_hsm_boot_uart_img_SOC_DEPENDENCY = yes
export sbl_hsm_boot_uart_img_CORE_DEPENDENCY = no
sbl_hsm_boot_uart_img_PKG_LIST = sbl
sbl_hsm_boot_uart_img_INCLUDE = $(sbl_hsm_boot_uart_img_PATH)
export sbl_hsm_boot_uart_img_BOARDLIST = j721s2_evm j784s4_evm j742s2_evm
export sbl_hsm_boot_uart_img_$(SOC)_CORELIST = mcu1_0
export sbl_hsm_boot_uart_img_SBL_IMAGEGEN = yes

# Individual Core Boot Test
sbl_boot_test_COMP_LIST = sbl_boot_test
sbl_boot_test_RELPATH = ti/boot/sbl/example/k3MulticoreApp
sbl_boot_test_BINPATH = $(PDK_SBL_COMP_PATH)/example/k3MulticoreApp/binary
sbl_boot_test_PATH = $(PDK_SBL_COMP_PATH)/example/k3MulticoreApp
sbl_boot_test_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_boot_test.mk
export sbl_boot_test_MAKEFILE
sbl_boot_test_BOARD_DEPENDENCY = no
sbl_boot_test_SOC_DEPENDENCY = no
sbl_boot_test_CORE_DEPENDENCY = no
export sbl_boot_test_COMP_LIST
export sbl_boot_test_BOARD_DEPENDENCY
export sbl_boot_test_SOC_DEPENDENCY
export sbl_boot_test_CORE_DEPENDENCY
sbl_boot_test_PKG_LIST = sbl_boot_test
sbl_boot_test_INCLUDE = $(sbl_boot_test_PATH)
sbl_boot_test_BOARDLIST = $(sbl_BOARDLIST)
export sbl_boot_test_BOARDLIST
sbl_boot_test_$(SOC)_CORELIST = $(sbl_$(SOC)_CORELIST)
export sbl_boot_test_$(SOC)_CORELIST
sbl_EXAMPLE_LIST += sbl_boot_test
sbl_boot_test_SBL_APPIMAGEGEN = yes
export sbl_boot_test_SBL_APPIMAGEGEN

# Multicore Boot Test
sbl_multicore_boot_test_COMP_LIST = sbl_multicore_boot_test
sbl_multicore_boot_test_RELPATH = ti/boot/sbl/example/k3MulticoreApp
sbl_multicore_boot_test_BINPATH = $(PDK_SBL_COMP_PATH)/example/k3MulticoreApp/binary
sbl_multicore_boot_test_PATH = $(PDK_SBL_COMP_PATH)/example/k3MulticoreApp
sbl_multicore_boot_test_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_multicore_boot_test.mk
export sbl_multicore_boot_test_MAKEFILE
# SBL multicore boot depends on sbl_boot_test for all the cores
sbl_multicore_boot_test_DEPENDS_ON=sbl_boot_test
export sbl_multicore_boot_test_DEPENDS_ON
sbl_multicore_boot_test_BOARD_DEPENDENCY = no
sbl_multicore_boot_test_SOC_DEPENDENCY = no
sbl_multicore_boot_test_CORE_DEPENDENCY = no
export sbl_multicore_boot_test_COMP_LIST
export sbl_multicore_boot_test_BOARD_DEPENDENCY
export sbl_multicore_boot_test_SOC_DEPENDENCY
export sbl_multicore_boot_test_CORE_DEPENDENCY
sbl_multicore_boot_test_PKG_LIST = sbl_multicore_boot_test
sbl_multicore_boot_test_INCLUDE = $(sbl_multicore_boot_test_PATH)
sbl_multicore_boot_test_BOARDLIST = $(sbl_BOARDLIST)
export sbl_multicore_boot_test_BOARDLIST
sbl_multicore_boot_test_$(SOC)_CORELIST = $($(SOC)_LASTCORE)
export sbl_multicore_boot_test_$(SOC)_CORELIST
sbl_EXAMPLE_LIST += sbl_multicore_boot_test
sbl_multicore_boot_test_SBL_APPIMAGEGEN = no
export sbl_multicore_boot_test_SBL_APPIMAGEGEN

# Boot App individual core boot test
bootapp_boot_test_COMP_LIST = bootapp_boot_test
bootapp_boot_test_RELPATH = ti/boot/sbl/example/k3MulticoreApp
bootapp_boot_test_BINPATH = $(PDK_SBL_COMP_PATH)/example/k3MulticoreApp/binary
bootapp_boot_test_PATH = $(PDK_SBL_COMP_PATH)/example/k3MulticoreApp
bootapp_boot_test_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_boot_test.mk IS_BOOTAPP_TEST=yes
export bootapp_boot_test_MAKEFILE
bootapp_boot_test_BOARD_DEPENDENCY = no
bootapp_boot_test_SOC_DEPENDENCY = no
bootapp_boot_test_CORE_DEPENDENCY = no
export bootapp_boot_test_COMP_LIST
export bootapp_boot_test_BOARD_DEPENDENCY
export bootapp_boot_test_SOC_DEPENDENCY
export bootapp_boot_test_CORE_DEPENDENCY
bootapp_boot_test_PKG_LIST = bootapp_boot_test
bootapp_boot_test_INCLUDE = $(bootapp_boot_test_PATH)
bootapp_boot_test_BOARDLIST = $(sbl_BOARDLIST)
export bootapp_boot_test_BOARDLIST
bootapp_boot_test_$(SOC)_CORELIST = $(CORE_LIST_$(SOC))
export bootapp_boot_test_$(SOC)_CORELIST
sbl_EXAMPLE_LIST += bootapp_boot_test
bootapp_boot_test_SBL_APPIMAGEGEN = yes
export bootapp_boot_test_SBL_APPIMAGEGEN

# SBL lockstep example
sbl_lockstep_boot_test_COMP_LIST = sbl_lockstep_boot_test
sbl_lockstep_boot_test_RELPATH = ti/boot/sbl/example/k3MulticoreApp
sbl_lockstep_boot_test_BINPATH = $(PDK_SBL_COMP_PATH)/example/k3MulticoreApp/binary
sbl_lockstep_boot_test_PATH = $(PDK_SBL_COMP_PATH)/example/k3MulticoreApp
sbl_lockstep_boot_test_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/example/k3MulticoreApp/lockstep_example/makefile
export sbl_lockstep_boot_test_MAKEFILE
sbl_lockstep_boot_test_BOARD_DEPENDENCY = no
sbl_lockstep_boot_test_SOC_DEPENDENCY = yes
sbl_lockstep_boot_test_CORE_DEPENDENCY = yes
export sbl_lockstep_boot_test_COMP_LIST
export sbl_lockstep_boot_test_BOARD_DEPENDENCY
export sbl_lockstep_boot_test_SOC_DEPENDENCY
export sbl_lockstep_boot_test_CORE_DEPENDENCY
sbl_lockstep_boot_test_PKG_LIST = sbl_lockstep_boot_test
sbl_lockstep_boot_test_INCLUDE = $(sbl_lockstep_boot_test_PATH)
sbl_lockstep_boot_test_BOARDLIST = $(sbl_BOARDLIST)
export sbl_lockstep_boot_test_BOARDLIST
sbl_lockstep_boot_test_$(SOC)_CORELIST = $($(SOC)_lockstep_CORELIST)
export sbl_lockstep_boot_test_$(SOC)_CORELIST
sbl_EXAMPLE_LIST += sbl_lockstep_boot_test
sbl_lockstep_boot_test_SBL_APPIMAGEGEN = yes
export sbl_lockstep_boot_test_SBL_APPIMAGEGEN

# SBL lockstep multicore example
sbl_lockstep_multicore_boot_test_COMP_LIST = sbl_lockstep_multicore_boot_test
sbl_lockstep_multicore_boot_test_RELPATH = ti/boot/sbl/example/k3MulticoreApp
sbl_lockstep_multicore_boot_test_BINPATH = $(PDK_SBL_COMP_PATH)/example/k3MulticoreApp/binary
sbl_lockstep_multicore_boot_test_PATH = $(PDK_SBL_COMP_PATH)/example/k3MulticoreApp
sbl_lockstep_multicore_boot_test_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/example/k3MulticoreApp/lockstep_example/sbl_lockstep_multicore.mk
export sbl_lockstep_multicore_boot_test_MAKEFILE
sbl_lockstep_multicore_boot_test_BOARD_DEPENDENCY = no
sbl_lockstep_multicore_boot_test_SOC_DEPENDENCY = no
sbl_lockstep_multicore_boot_test_CORE_DEPENDENCY = no
export sbl_lockstep_multicore_boot_test_COMP_LIST
export sbl_lockstep_multicore_boot_test_BOARD_DEPENDENCY
export sbl_lockstep_multicore_boot_test_SOC_DEPENDENCY
export sbl_lockstep_multicore_boot_test_CORE_DEPENDENCY
sbl_lockstep_multicore_boot_test_PKG_LIST = sbl_lockstep_multicore_boot_test
sbl_lockstep_multicore_boot_test_INCLUDE = $(sbl_lockstep_multicore_boot_test_PATH)
sbl_lockstep_multicore_boot_test_BOARDLIST = $(sbl_BOARDLIST)
export sbl_lockstep_multicore_boot_test_BOARDLIST
sbl_lockstep_multicore_boot_test_$(SOC)_CORELIST = $($(SOC)_LASTCORE)
export sbl_lockstep_multicore_boot_test_$(SOC)_CORELIST
sbl_EXAMPLE_LIST += sbl_lockstep_multicore_boot_test
sbl_lockstep_multicore_boot_test_SBL_APPIMAGEGEN = no
export sbl_lockstep_multicore_boot_test_SBL_APPIMAGEGEN

# R5 boot XIP Test
sbl_boot_xip_test_COMP_LIST = sbl_boot_xip_test
sbl_boot_xip_test_RELPATH = ti/boot/sbl/example/k3MulticoreApp
sbl_boot_xip_test_BINPATH = $(PDK_SBL_COMP_PATH)/example/k3MulticoreApp/binary
sbl_boot_xip_test_PATH = $(PDK_SBL_COMP_PATH)/example/k3MulticoreApp
sbl_boot_xip_test_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_mcu0_boot_xip_test.mk
export sbl_boot_xip_test_MAKEFILE
sbl_boot_xip_test_BOARD_DEPENDENCY = no
sbl_boot_xip_test_SOC_DEPENDENCY = no
sbl_boot_xip_test_CORE_DEPENDENCY = no
export sbl_boot_xip_test_COMP_LIST
export sbl_boot_xip_test_BOARD_DEPENDENCY
export sbl_boot_xip_test_SOC_DEPENDENCY
export sbl_boot_xip_test_CORE_DEPENDENCY
sbl_boot_xip_test_PKG_LIST = sbl_boot_xip_test
sbl_boot_xip_test_INCLUDE = $(sbl_boot_xip_test_PATH)
sbl_boot_xip_test_BOARDLIST = $(sbl_BOARDLIST)
export sbl_boot_xip_test_BOARDLIST
sbl_boot_xip_test_$(SOC)_CORELIST = mcu1_0
export sbl_boot_xip_test_$(SOC)_CORELIST
sbl_EXAMPLE_LIST += sbl_boot_xip_test
sbl_boot_xip_test_SBL_APPIMAGEGEN = yes
sbl_boot_xip_test_SBL_APP_BINIMAGEGEN = yes
sbl_boot_xip_test_SBL_APP_BIN_SECTIONS = --only-section .rstvectors --only-section .sbl_mcu_1_0_resetvector --only-section .text --only-section .rodata
export sbl_boot_xip_test_SBL_APPIMAGEGEN
export sbl_boot_xip_test_SBL_APP_BINIMAGEGEN
export sbl_boot_xip_test_SBL_APP_BIN_SECTIONS

# R5 boot XIP entry
sbl_boot_xip_entry_COMP_LIST = sbl_boot_xip_entry
sbl_boot_xip_entry_RELPATH = ti/boot/sbl/example/k3MulticoreApp
sbl_boot_xip_entry_BINPATH = $(PDK_SBL_COMP_PATH)/example/k3MulticoreApp/binary
sbl_boot_xip_entry_PATH = $(PDK_SBL_COMP_PATH)/example/k3MulticoreApp
sbl_boot_xip_entry_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_mcu0_boot_xip_entry.mk
export sbl_boot_xip_entry_MAKEFILE
sbl_boot_xip_entry_BOARD_DEPENDENCY = no
sbl_boot_xip_entry_SOC_DEPENDENCY = no
sbl_boot_xip_entry_CORE_DEPENDENCY = no
export sbl_boot_xip_entry_COMP_LIST
export sbl_boot_xip_entry_BOARD_DEPENDENCY
export sbl_boot_xip_entry_SOC_DEPENDENCY
export sbl_boot_xip_entry_CORE_DEPENDENCY
sbl_boot_xip_entry_PKG_LIST = sbl_boot_xip_entry
sbl_boot_xip_entry_INCLUDE = $(sbl_boot_xip_entry_PATH)
sbl_boot_xip_entry_BOARDLIST = $(sbl_BOARDLIST)
export sbl_boot_xip_entry_BOARDLIST
sbl_boot_xip_entry_$(SOC)_CORELIST = mcu1_0
export sbl_boot_xip_entry_$(SOC)_CORELIST
sbl_EXAMPLE_LIST += sbl_boot_xip_entry
sbl_boot_xip_entry_SBL_APPIMAGEGEN = yes
export sbl_boot_xip_entry_SBL_APPIMAGEGEN

# Multicore XIP entry
sbl_boot_multicore_xip_entry_COMP_LIST = sbl_boot_multicore_xip_entry
sbl_boot_multicore_xip_entry_RELPATH = ti/boot/sbl/example/sblMcXipEntryApp
sbl_boot_multicore_xip_entry_BINPATH = $(PDK_SBL_COMP_PATH)/example/k3MulticoreApp/binary
sbl_boot_multicore_xip_entry_PATH = $(PDK_SBL_COMP_PATH)/example/sblMcXipEntryApp
sbl_boot_multicore_xip_entry_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/example/sblMcXipEntryApp/makefile.mk
export sbl_boot_multicore_xip_entry_MAKEFILE
sbl_boot_multicore_xip_entry_BOARD_DEPENDENCY = no
sbl_boot_multicore_xip_entry_SOC_DEPENDENCY = no
sbl_boot_multicore_xip_entry_CORE_DEPENDENCY = no
export sbl_boot_multicore_xip_entry_COMP_LIST
export sbl_boot_multicore_xip_entry_BOARD_DEPENDENCY
export sbl_boot_multicore_xip_entry_SOC_DEPENDENCY
export sbl_boot_multicore_xip_entry_CORE_DEPENDENCY
sbl_boot_multicore_xip_entry_PKG_LIST = sbl_boot_multicore_xip_entry
sbl_boot_multicore_xip_entry_INCLUDE = $(sbl_boot_multicore_xip_entry_PATH)
sbl_boot_multicore_xip_entry_BOARDLIST = j721e_evm j7200_evm
export sbl_boot_multicore_xip_entry_BOARDLIST
sbl_boot_multicore_xip_entry_$(SOC)_CORELIST = mcu1_0 mcu2_0
export sbl_boot_multicore_xip_entry_$(SOC)_CORELIST
sbl_EXAMPLE_LIST += sbl_boot_multicore_xip_entry
sbl_boot_multicore_xip_entry_SBL_APPIMAGEGEN = yes
export sbl_boot_multicore_xip_entry_SBL_APPIMAGEGEN

# Display profiling info before MCU1_0 boot
# increases delay time, between end of SBL
# and start of app, but useful for
# debugging and tuning performace knobs
#SBL_CFLAGS += -DSBL_DISPLAY_PROFILE_INFO

###### Use boot_perf_benchmark example#######
###### to fine tune the perf knobs  #########

###########START BOOT PERF KNOBS#############
# SBL log level
# no logs = 0, only errors =1, normal logs = 2, all logs = 3

SBL_CFLAGS += -DSBL_LOG_LEVEL=2

SBL_CFLAGS += -DSBL_ENABLE_PLL
SBL_CFLAGS += -DSBL_ENABLE_CLOCKS
SBL_CFLAGS += -DSBL_ENABLE_DDR

ifeq ($(SOC), $(filter $(SOC), j721e))
SBL_CFLAGS += -DSBL_ENABLE_SERDES
endif

############################################
# DISABLING the options above this caption
# improves boot time at the cost of moving
# PLL, LPSC and DDR init to the app
#
# ENABLING the options below this caption
# improves boot time by skipping stuff SBL
# usually does.
###########################################
# If enabled, the SBL will branch to the start
# of MCU_0 app without resetting the core
# if csl defaults are godd enough this enables
# app to skip redoing mcu initialization
#SBL_CFLAGS += -DSBL_SKIP_MCU_RESET

# If enabled, SBL will skip initializing
# sysfw. The SBL will only load it.
# No SCI Client APIs will work. Saves
# boot time. When this is enabled
# make sure that SBL_SKIP_MCU_RESET is also
# enabled, as resetting a core needs SYSFW
# to be running.
# SBL_CFLAGS += -DSBL_SKIP_SYSFW_INIT

# If enabled, SBL will skip calling
# Sciclient_boardCfg* API.  Enabling
# it saves boot time, can affect
# functionality. The app must call the
# Sciclient_boardCfg* APIs that the SBL
# skips. Like for eg, if SBL skips calling
# Sciclient_boardCfgPm, then Sciclient_boardCfgRm
# and Sciclient_boardCfgSec must also
# be skipped.
#SBL_CFLAGS += -DSBL_SKIP_BRD_CFG_BOARD
#SBL_CFLAGS += -DSBL_SKIP_BRD_CFG_RM
#SBL_CFLAGS += -DSBL_SKIP_BRD_CFG_SEC
#SBL_CFLAGS += -DSBL_SKIP_BRD_CFG_PM

# If enabled, SBL will use alternate
# config steps to directly boot an HLOS,
# including an alternate set of Sciclient
# RM board cfg settings.
# NOTE: Currently supported only for J721E, J7200
#SBL_CFLAGS += -DSBL_ENABLE_HLOS_BOOT

# If enabled, SBL will not leave the OSPI
# flash in XIP mode, so that the MAIN
# domain Cortex-A code (HLOS) can reset
# the flash and take control of it, if
# needed.
#SBL_CFLAGS += -DSBL_HLOS_OWNS_FLASH

# If enabled, SBL will skip any PINMUX
# init being used in the bootloader and
# expect that it will be handled by
# another app.
#SBL_CFLAGS += -DSBL_SKIP_PINMUX_ENABLE

# If enabled, SBL will skip handling the
# SoC Late Init functions normally contained
# in SBL_SocLateInit()
#SBL_CFLAGS += -DSBL_SKIP_LATE_INIT

# If enabled, the SBL will configure & use
# resources in the MCU domain ONLY to
# enable MCU-only code to run.
#SBL_CFLAGS += -DSBL_USE_MCU_DOMAIN_ONLY

# If enabled for OSPI boot the SBL will bypass the
# OSPI driver completely and let ROM copy the sysftw/application
# from flash.
#SBL_CFLAGS += -DSBL_BYPASS_OSPI_DRIVER

# If enabled for OSPI boot the SBL will bypass the
# OSPI driver for system firmware download and use the OSPI driver for
# downloading application from the flash
#SBL_CFLAGS += -DSBL_BYPASS_OSPI_DRIVER_FOR_SYSFW_DOWNLOAD

# If enabled the SBL image is built for running on VLAB simulation.
#SBL_CFLAGS += -DVLAB_SIM

###########END BOOT PERF KNOBS#############

# Example - Building Custom SBL Images
# Build and SBl with custom flags to change
# different build configurations
CUST_SBL_TEST_SOCS = j721e j7200 j721s2 j784s4 j742s2
CUST_SBL_TEST_BOARDS = j721e_evm j7200_evm j721s2_evm j784s4_evm j742s2_evm
ifeq ($(SOC),$(filter $(SOC), j721e j7200 j721s2 j784s4 j742s2))
CUST_SBL_TEST_FLAGS =" -DSBL_LOG_LEVEL=1 -DSBL_SCRATCH_MEM_START=0xB8000000 -DSBL_SCRATCH_MEM_SIZE=0x4000000 -DSBL_ENABLE_PLL -DSBL_ENABLE_CLOCKS -DSBL_ENABLE_DDR -DSBL_SKIP_MCU_RESET -DBOOT_OSPI ${OCM_RAT_STRING}"
CUST_SBL_BOOT_PERF_TEST_FLAGS =" -DSBL_LOG_LEVEL=1 -DSBL_SCRATCH_MEM_START=0x41cc0000 -DSBL_SCRATCH_MEM_SIZE=0x40000 -DSBL_ENABLE_PLL -DSBL_ENABLE_CLOCKS -DSBL_SKIP_MCU_RESET -DBOOT_OSPI -DSBL_HLOS_OWNS_FLASH -DSBL_SKIP_LATE_INIT -DSBL_USE_MCU_DOMAIN_ONLY"
# NOTE: To measure Early CAN response uncomment below line and comment above line
#CUST_SBL_BOOT_PERF_TEST_FLAGS =" -DSBL_LOG_LEVEL=1 -DSBL_SCRATCH_MEM_START=0x41cc0000 -DSBL_SCRATCH_MEM_SIZE=0x40000 -DSBL_ENABLE_PLL -DSBL_ENABLE_CLOCKS -DSBL_SKIP_MCU_RESET -DBOOT_OSPI -DSBL_HLOS_OWNS_FLASH -DSBL_SKIP_LATE_INIT -DSBL_SKIP_PINMUX_ENABLE -DSBL_USE_MCU_DOMAIN_ONLY"
endif

# SBL Custom LIB
sbl_lib_cust_COMP_LIST = sbl_lib_cust
sbl_lib_cust_RELPATH = ti/boot/sbl
export sbl_lib_cust_OBJPATH = ti/boot/sbl/cust
sbl_lib_cust_LIBNAME = sbl_lib_cust
sbl_lib_cust_PATH = $(PDK_SBL_COMP_PATH)
sbl_lib_cust_LIBNAME = sbl_lib_cust
sbl_lib_cust_LIBPATH = $(PDK_SBL_COMP_PATH)/lib/cust
sbl_lib_cust_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_lib.mk BOOTMODE=cust SBL_USE_DMA=yes CUST_SBL_FLAGS=$(CUST_SBL_TEST_FLAGS)
export sbl_lib_cust_MAKEFILE
export sbl_lib_cust_LIBNAME
export sbl_lib_cust_LIBPATH
sbl_lib_cust_BOARD_DEPENDENCY = yes
sbl_lib_cust_SOC_DEPENDENCY = yes
sbl_lib_cust_CORE_DEPENDENCY = no
export sbl_lib_cust_COMP_LIST
export sbl_lib_cust_BOARD_DEPENDENCY
export sbl_lib_cust_CORE_DEPENDENCY
sbl_lib_cust_PKG_LIST = sbl_lib_cust
sbl_lib_cust_INCLUDE = $(sbl_lib_cust_PATH)
sbl_lib_cust_SOCLIST = $(CUST_SBL_TEST_SOCS)
sbl_lib_cust_BOARDLIST = $(CUST_SBL_TEST_BOARDS)
export sbl_lib_cust_SOCLIST
export sbl_lib_cust_BOARDLIST
sbl_lib_cust_$(SOC)_CORELIST = mcu1_0
export sbl_lib_cust_$(SOC)_CORELIST

# SBL Custom LIB - HS build variant
# This SBL target uses sbl_lib_cust_hs if SBL_USE_DMA=yes and sbl_lib_cust_nondma_hs if SBL_USE_DMA=no 
sbl_lib_cust_hs_COMP_LIST = sbl_lib_cust_hs
sbl_lib_cust_hs_RELPATH = ti/boot/sbl
export sbl_lib_cust_hs_OBJPATH = ti/boot/sbl/cust_hs
sbl_lib_cust_hs_LIBNAME = sbl_lib_cust_hs
sbl_lib_cust_hs_PATH = $(PDK_SBL_COMP_PATH)
sbl_lib_cust_hs_LIBNAME = sbl_lib_cust_hs
sbl_lib_cust_hs_LIBPATH = $(PDK_SBL_COMP_PATH)/lib/cust_hs
sbl_lib_cust_hs_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_lib.mk BOOTMODE=cust SBL_USE_DMA=yes CUST_SBL_FLAGS=$(CUST_SBL_TEST_FLAGS) BUILD_HS=yes
export sbl_lib_cust_hs_MAKEFILE
export sbl_lib_cust_hs_LIBNAME
export sbl_lib_cust_hs_LIBPATH
sbl_lib_cust_hs_BOARD_DEPENDENCY = yes
sbl_lib_cust_hs_SOC_DEPENDENCY = yes
sbl_lib_cust_hs_CORE_DEPENDENCY = no
export sbl_lib_cust_hs_COMP_LIST
export sbl_lib_cust_hs_BOARD_DEPENDENCY
export sbl_lib_cust_hs_CORE_DEPENDENCY
sbl_lib_cust_hs_PKG_LIST = sbl_lib_cust_hs
sbl_lib_cust_hs_INCLUDE = $(sbl_lib_cust_hs_PATH)
sbl_lib_cust_hs_SOCLIST = $(CUST_SBL_TEST_SOCS)
sbl_lib_cust_hs_BOARDLIST = $(CUST_SBL_TEST_BOARDS)
export sbl_lib_cust_hs_SOCLIST
export sbl_lib_cust_hs_BOARDLIST
sbl_lib_cust_hs_$(SOC)_CORELIST = mcu1_0
export sbl_lib_cust_hs_$(SOC)_CORELIST

# SBL XIP image
# Used to boot an application directly from OSPI flash
sbl_xip_img_COMP_LIST = sbl_xip_img
sbl_xip_img_RELPATH = ti/boot/sbl/board/k3
sbl_xip_img_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)/xip/bin
sbl_xip_img_PATH = $(PDK_SBL_COMP_PATH)/board/k3
sbl_xip_img_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=xip SBL_USE_DMA=no CUST_SBL_FLAGS=$(CUST_SBL_TEST_FLAGS)
export sbl_xip_img_MAKEFILE
export sbl_xip_img_SBL_CERT_KEY=$(SBL_CERT_KEY)
sbl_xip_img_BOARD_DEPENDENCY = yes
sbl_xip_img_SOC_DEPENDENCY = yes
sbl_xip_img_CORE_DEPENDENCY = no
export sbl_xip_img_COMP_LIST
export sbl_xip_img_BOARD_DEPENDENCY
export sbl_xip_img_SOC_DEPENDENCY
export sbl_xip_img_CORE_DEPENDENCY
sbl_xip_img_PKG_LIST = sbl
sbl_xip_img_INCLUDE = $(sbl_xip_img_PATH)
sbl_xip_img_SOCLIST = $(CUST_SBL_TEST_SOCS)
sbl_xip_img_BOARDLIST = $(CUST_SBL_TEST_BOARDS)
export sbl_xip_img_SOCLIST
export sbl_xip_img_BOARDLIST
sbl_xip_img_$(SOC)_CORELIST = mcu1_0
export sbl_xip_img_$(SOC)_CORELIST
sbl_EXAMPLE_LIST += sbl_xip_img
sbl_xip_img_SBL_IMAGEGEN = yes
export sbl_xip_img_SBL_IMAGEGEN

# SBL xip image - For HS build
# # Used to boot an application directly from OSPI flash
export sbl_xip_img_hs_COMP_LIST = sbl_xip_img_hs
sbl_xip_img_hs_RELPATH = ti/boot/sbl/board/k3
sbl_xip_img_hs_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)_hs/xip/bin
sbl_xip_img_hs_PATH = $(PDK_SBL_COMP_PATH)/board/k3
export sbl_xip_img_hs_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk CUST_SBL_FLAGS=$(CUST_SBL_TEST_FLAGS) BOOTMODE=xip OSPI_FREQ=166 SBL_USE_DMA=no BUILD_HS=yes
export sbl_xip_img_hs_SBL_CERT_KEY=$(SBL_CERT_KEY_HS)
export sbl_xip_img_hs_BOARD_DEPENDENCY = yes
export sbl_xip_img_hs_SOC_DEPENDENCY = yes
export sbl_xip_img_hs_CORE_DEPENDENCY = no
sbl_xip_img_hs_PKG_LIST = sbl
sbl_xip_img_hs_INCLUDE = $(sbl_xip_img_hs_PATH)
export sbl_xip_img_hs_SOCLIST = $(CUST_SBL_TEST_SOCS)
export sbl_xip_img_hs_BOARDLIST = $(CUST_SBL_TEST_BOARDS)
export sbl_xip_img_hs_$(SOC)_CORELIST = mcu1_0
export sbl_xip_img_hs_SBL_IMAGEGEN = yes
sbl_EXAMPLE_LIST += sbl_xip_img_hs
sbl_xip_img_hs_SBL_IMAGEGEN = yes
export sbl_xip_img_hs_SBL_IMAGEGEN

# SBL custom image
# This SBL target uses sbl_lib_cust if SBL_USE_DMA=yes and sbl_lib_cust_nondma if SBL_USE_DMA=no 
sbl_cust_img_COMP_LIST = sbl_cust_img
sbl_cust_img_RELPATH = ti/boot/sbl/board/k3
sbl_cust_img_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)/cust/bin
sbl_cust_img_PATH = $(PDK_SBL_COMP_PATH)/board/k3
sbl_cust_img_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=cust SBL_USE_DMA=yes BUILD_HS=no CUST_SBL_FLAGS=$(CUST_SBL_TEST_FLAGS)
export sbl_cust_img_MAKEFILE
export sbl_cust_img_SBL_CERT_KEY=$(SBL_CERT_KEY)
sbl_cust_img_BOARD_DEPENDENCY = yes
sbl_cust_img_SOC_DEPENDENCY = yes
sbl_cust_img_CORE_DEPENDENCY = no
export sbl_cust_img_COMP_LIST
export sbl_cust_img_BOARD_DEPENDENCY
export sbl_cust_img_SOC_DEPENDENCY
export sbl_cust_img_CORE_DEPENDENCY
sbl_cust_img_PKG_LIST = sbl
sbl_cust_img_INCLUDE = $(sbl_cust_img_PATH)
sbl_cust_img_SOCLIST = $(CUST_SBL_TEST_SOCS)
sbl_cust_img_BOARDLIST = $(CUST_SBL_TEST_BOARDS)
export sbl_cust_img_SOCLIST
export sbl_cust_img_BOARDLIST
sbl_cust_img_$(SOC)_CORELIST = mcu1_0
export sbl_cust_img_$(SOC)_CORELIST
sbl_EXAMPLE_LIST += sbl_cust_img
sbl_cust_img_SBL_IMAGEGEN = yes
export sbl_cust_img_SBL_IMAGEGEN

# SBL custom image which RAT maps main OCM to DDR(0xD0000000)
# This SBL target is used to run ocmc_memory_benchmarking app on mcu2_0.
# Since main OCM is situated at 40 bit address RAT map main OCM to 0xD0000000
sbl_cust_rat_main_ocm_img_COMP_LIST = sbl_cust_rat_main_ocm_img
sbl_cust_rat_main_ocm_img_RELPATH = ti/boot/sbl/board/k3
sbl_cust_rat_main_ocm_img_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)/cust/bin
sbl_cust_rat_main_ocm_img_PATH = $(PDK_SBL_COMP_PATH)/board/k3
sbl_cust_rat_main_ocm_img_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=cust RAT=1 SBL_USE_DMA=no BUILD_HS=no CUST_SBL_FLAGS=$(CUST_SBL_TEST_FLAGS)
export sbl_cust_rat_main_ocm_img_MAKEFILE
export sbl_cust_rat_main_ocm_img_SBL_CERT_KEY=$(SBL_CERT_KEY)
sbl_cust_rat_main_ocm_img_BOARD_DEPENDENCY = yes
sbl_cust_rat_main_ocm_img_SOC_DEPENDENCY = yes
sbl_cust_rat_main_ocm_img_CORE_DEPENDENCY = no
export sbl_cust_rat_main_ocm_img_COMP_LIST
export sbl_cust_rat_main_ocm_img_BOARD_DEPENDENCY
export sbl_cust_rat_main_ocm_img_SOC_DEPENDENCY
export sbl_cust_rat_main_ocm_img_CORE_DEPENDENCY
sbl_cust_rat_main_ocm_img_PKG_LIST = sbl
sbl_cust_rat_main_ocm_img_INCLUDE = $(sbl_cust_rat_main_ocm_img_PATH)
sbl_cust_rat_main_ocm_img_SOCLIST = j7200 j721s2 j784s4 j742s2
sbl_cust_rat_main_ocm_img_BOARDLIST = j7200_evm j721s2_evm j784s4_evm j742s2_evm
export sbl_cust_rat_main_ocm_img_SOCLIST
export sbl_cust_rat_main_ocm_img_BOARDLIST
sbl_cust_rat_main_ocm_img_$(SOC)_CORELIST = mcu1_0
export sbl_cust_rat_main_ocm_img_$(SOC)_CORELIST
sbl_EXAMPLE_LIST += sbl_cust_rat_main_ocm_img
sbl_cust_rat_main_ocm_img_SBL_IMAGEGEN = yes
export sbl_cust_rat_main_ocm_img_SBL_IMAGEGEN

# SBL perf custom image 
sbl_boot_perf_cust_img_COMP_LIST = sbl_boot_perf_cust_img
sbl_boot_perf_cust_img_RELPATH = ti/boot/sbl/board/k3
sbl_boot_perf_cust_img_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)/cust/bin
sbl_boot_perf_cust_img_PATH = $(PDK_SBL_COMP_PATH)/board/k3
sbl_boot_perf_cust_img_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=cust SBL_USE_DMA=yes BUILD_HS=no CUST_SBL_FLAGS=$(CUST_SBL_BOOT_PERF_TEST_FLAGS) BOOT_PERF=yes
export sbl_boot_perf_cust_img_MAKEFILE
export sbl_boot_perf_cust_img_SBL_CERT_KEY=$(SBL_CERT_KEY)
sbl_boot_perf_cust_img_BOARD_DEPENDENCY = yes
sbl_boot_perf_cust_img_SOC_DEPENDENCY = yes
sbl_boot_perf_cust_img_CORE_DEPENDENCY = no
export sbl_boot_perf_cust_img_COMP_LIST
export sbl_boot_perf_cust_img_BOARD_DEPENDENCY
export sbl_boot_perf_cust_img_SOC_DEPENDENCY
export sbl_boot_perf_cust_img_CORE_DEPENDENCY
sbl_boot_perf_cust_img_PKG_LIST = sbl
sbl_boot_perf_cust_img_INCLUDE = $(sbl_boot_perf_cust_img_PATH)
sbl_boot_perf_cust_img_SOCLIST = $(CUST_SBL_TEST_SOCS)
sbl_boot_perf_cust_img_BOARDLIST = $(CUST_SBL_TEST_BOARDS)
export sbl_boot_perf_cust_img_SOCLIST
export sbl_boot_perf_cust_img_BOARDLIST
sbl_boot_perf_cust_img_$(SOC)_CORELIST = mcu1_0
export sbl_boot_perf_cust_img_$(SOC)_CORELIST
sbl_EXAMPLE_LIST += sbl_boot_perf_cust_img
sbl_boot_perf_cust_img_SBL_IMAGEGEN = yes
export sbl_boot_perf_cust_img_SBL_IMAGEGEN

# SBL OSPI NAND performance custom image 
sbl_boot_perf_cust_nand_img_COMP_LIST = sbl_boot_perf_cust_nand_img
sbl_boot_perf_cust_nand_img_RELPATH = ti/boot/sbl/board/k3
sbl_boot_perf_cust_nand_img_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)/cust_nand/bin
sbl_boot_perf_cust_nand_img_PATH = $(PDK_SBL_COMP_PATH)/board/k3
sbl_boot_perf_cust_nand_img_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=cust SBL_USE_DMA=yes BUILD_HS=no CUST_SBL_FLAGS=$(CUST_SBL_BOOT_PERF_TEST_FLAGS) BOOT_PERF=yes OSPI_NAND=yes
export sbl_boot_perf_cust_nand_img_MAKEFILE
export sbl_boot_perf_cust_nand_img_SBL_CERT_KEY=$(SBL_CERT_KEY)
sbl_boot_perf_cust_nand_img_BOARD_DEPENDENCY = yes
sbl_boot_perf_cust_nand_img_SOC_DEPENDENCY = yes
sbl_boot_perf_cust_nand_img_CORE_DEPENDENCY = no
export sbl_boot_perf_cust_nand_img_COMP_LIST
export sbl_boot_perf_cust_nand_img_BOARD_DEPENDENCY
export sbl_boot_perf_cust_nand_img_SOC_DEPENDENCY
export sbl_boot_perf_cust_nand_img_CORE_DEPENDENCY
sbl_boot_perf_cust_nand_img_PKG_LIST = sbl
sbl_boot_perf_cust_nand_img_INCLUDE = $(sbl_boot_perf_cust_nand_img_PATH)
sbl_boot_perf_cust_nand_img_SOCLIST = j721s2 j784s4
sbl_boot_perf_cust_nand_img_BOARDLIST = j721s2_evm j784s4_evm
export sbl_boot_perf_cust_nand_img_SOCLIST
export sbl_boot_perf_cust_nand_img_BOARDLIST
sbl_boot_perf_cust_nand_img_$(SOC)_CORELIST = mcu1_0
export sbl_boot_perf_cust_nand_img_$(SOC)_CORELIST
sbl_EXAMPLE_LIST += sbl_boot_perf_cust_nand_img
sbl_boot_perf_cust_nand_img_SBL_IMAGEGEN = yes
export sbl_boot_perf_cust_nand_img_SBL_IMAGEGEN

# SBL XIP image
# Used to boot an application directly from OSPI flash at 133 MHz
# Used to validate xip memory benchmarking apps at 133 MHz frequency
sbl_xip_133_img_COMP_LIST = sbl_xip_133_img
sbl_xip_133_img_RELPATH = ti/boot/sbl/board/k3
sbl_xip_133_img_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)/xip/bin
sbl_xip_133_img_PATH = $(PDK_SBL_COMP_PATH)/board/k3
sbl_xip_133_img_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk BOOTMODE=xip OSPI_FREQ=133 SBL_USE_DMA=no CUST_SBL_FLAGS=$(CUST_SBL_TEST_FLAGS)
export sbl_xip_133_img_MAKEFILE
export sbl_xip_133_img_SBL_CERT_KEY=$(SBL_CERT_KEY)
sbl_xip_133_img_BOARD_DEPENDENCY = yes
sbl_xip_133_img_SOC_DEPENDENCY = yes
sbl_xip_133_img_CORE_DEPENDENCY = no
export sbl_xip_133_img_COMP_LIST
export sbl_xip_133_img_BOARD_DEPENDENCY
export sbl_xip_133_img_SOC_DEPENDENCY
export sbl_xip_133_img_CORE_DEPENDENCY
sbl_xip_133_img_PKG_LIST = sbl
sbl_xip_133_img_INCLUDE = $(sbl_xip_133_img_PATH)
sbl_xip_133_img_SOCLIST = $(CUST_SBL_TEST_SOCS)
sbl_xip_133_img_BOARDLIST = $(CUST_SBL_TEST_BOARDS)
export sbl_xip_133_img_SOCLIST
export sbl_xip_133_img_BOARDLIST
sbl_xip_133_img_$(SOC)_CORELIST = mcu1_0
export sbl_xip_133_img_$(SOC)_CORELIST
sbl_EXAMPLE_LIST += sbl_xip_133_img
sbl_xip_133_img_SBL_IMAGEGEN = yes
export sbl_xip_133_img_SBL_IMAGEGEN

# SBL custom image - For HS build
export sbl_cust_img_hs_COMP_LIST = sbl_cust_img_hs
sbl_cust_img_hs_RELPATH = ti/boot/sbl/board/k3
sbl_cust_img_hs_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/binary/$(BOARD)_hs/cust/bin
sbl_cust_img_hs_PATH = $(PDK_SBL_COMP_PATH)/board/k3
export sbl_cust_img_hs_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_img.mk CUST_SBL_FLAGS=$(CUST_SBL_TEST_FLAGS) BOOTMODE=cust SBL_USE_DMA=yes BUILD_HS=yes
export sbl_cust_img_hs_SBL_CERT_KEY=$(SBL_CERT_KEY_HS)
export sbl_cust_img_hs_BOARD_DEPENDENCY = yes
export sbl_cust_img_hs_SOC_DEPENDENCY = yes
export sbl_cust_img_hs_CORE_DEPENDENCY = no
sbl_cust_img_hs_PKG_LIST = sbl
sbl_cust_img_hs_INCLUDE = $(sbl_cust_img_hs_PATH)
export sbl_cust_img_hs_SOCLIST = $(CUST_SBL_TEST_SOCS)
export sbl_cust_img_hs_BOARDLIST = $(CUST_SBL_TEST_BOARDS)
export sbl_cust_img_hs_$(SOC)_CORELIST = mcu1_0
export sbl_cust_img_hs_SBL_IMAGEGEN = yes
sbl_EXAMPLE_LIST += sbl_cust_img_hs

# R5 boot performance Test - works only with custom SBL
sbl_boot_perf_test_COMP_LIST = sbl_boot_perf_test
sbl_boot_perf_test_RELPATH = ti/boot/sbl/example/k3MulticoreApp
sbl_boot_perf_test_BINPATH = $(PDK_SBL_COMP_PATH)/example/k3MulticoreApp/binary
sbl_boot_perf_test_PATH = $(PDK_SBL_COMP_PATH)/example/k3MulticoreApp
sbl_boot_perf_test_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_mcu0_boot_perf_test.mk BOOTMODE=cust CUST_SBL_FLAGS=$(CUST_SBL_BOOT_PERF_TEST_FLAGS)
export sbl_boot_perf_test_MAKEFILE
sbl_boot_perf_test_BOARD_DEPENDENCY = no
sbl_boot_perf_test_SOC_DEPENDENCY = no
sbl_boot_perf_test_CORE_DEPENDENCY = no
export sbl_boot_perf_test_COMP_LIST
export sbl_boot_perf_test_BOARD_DEPENDENCY
export sbl_boot_perf_test_SOC_DEPENDENCY
export sbl_boot_perf_test_CORE_DEPENDENCY
sbl_boot_perf_test_PKG_LIST = sbl_boot_perf_test
sbl_boot_perf_test_INCLUDE = $(sbl_boot_perf_test_PATH)
sbl_boot_perf_test_SOCLIST = $(CUST_SBL_TEST_SOCS)
sbl_boot_perf_test_BOARDLIST = $(CUST_SBL_TEST_BOARDS)
export sbl_boot_perf_test_SOCLIST
export sbl_boot_perf_test_BOARDLIST
sbl_boot_perf_test_$(SOC)_CORELIST = mcu1_0
export sbl_boot_perf_test_$(SOC)_CORELIST
sbl_EXAMPLE_LIST += sbl_boot_perf_test
sbl_boot_perf_test_SBL_APPIMAGEGEN = yes
export sbl_boot_perf_test_SBL_APPIMAGEGEN

# R5 combined boot performance Test - works only with custom combined SBL
sbl_combined_boot_perf_test_COMP_LIST = sbl_combined_boot_perf_test
sbl_combined_boot_perf_test_RELPATH = ti/boot/sbl/example/k3MulticoreApp
sbl_combined_boot_perf_test_BINPATH = $(PDK_SBL_COMP_PATH)/example/k3MulticoreApp/binary
sbl_combined_boot_perf_test_PATH = $(PDK_SBL_COMP_PATH)/example/k3MulticoreApp
sbl_combined_boot_perf_test_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/sbl_mcu0_boot_perf_test.mk BOOTMODE=cust CUST_SBL_FLAGS=$(CUST_SBL_BOOT_PERF_TEST_FLAGS) COMBINED_BOOT_PERF=yes
export sbl_combined_boot_perf_test_MAKEFILE
sbl_combined_boot_perf_test_BOARD_DEPENDENCY = no
sbl_combined_boot_perf_test_SOC_DEPENDENCY = no
sbl_combined_boot_perf_test_CORE_DEPENDENCY = no
export sbl_combined_boot_perf_test_COMP_LIST
export sbl_combined_boot_perf_test_BOARD_DEPENDENCY
export sbl_combined_boot_perf_test_SOC_DEPENDENCY
export sbl_combined_boot_perf_test_CORE_DEPENDENCY
sbl_combined_boot_perf_test_PKG_LIST = sbl_combined_boot_perf_test
sbl_combined_boot_perf_test_INCLUDE = $(sbl_combined_boot_perf_test_PATH)
sbl_combined_boot_perf_test_SOCLIST = $(CUST_SBL_TEST_SOCS)
sbl_combined_boot_perf_test_BOARDLIST = j7200_evm j721s2_evm j784s4_evm j742s2_evm


export sbl_combined_boot_perf_test_SOCLIST
export sbl_combined_boot_perf_test_BOARDLIST
sbl_combined_boot_perf_test_$(SOC)_CORELIST = mcu1_0
export sbl_combined_boot_perf_test_$(SOC)_CORELIST
sbl_EXAMPLE_LIST += sbl_combined_boot_perf_test
sbl_combined_boot_perf_test_SBL_APPIMAGEGEN = yes
export sbl_combined_boot_perf_test_SBL_APPIMAGEGEN

# Boot App OSPI
boot_app_ospi_COMP_LIST = boot_app_ospi
boot_app_ospi_RELPATH = ti/boot/sbl/example/boot_app
boot_app_ospi_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/example/boot_app/binary/$(BOARD)/ospi
boot_app_ospi_PATH = $(PDK_SBL_COMP_PATH)/example/boot_app
boot_app_ospi_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/boot_app.mk BOOTMODE=ospi BUILD_HS=no HLOSBOOT=none CANRESP=disabled
export boot_app_ospi_MAKEFILE
boot_app_ospi_BOARD_DEPENDENCY = yes
boot_app_ospi_SOC_DEPENDENCY = yes
boot_app_ospi_CORE_DEPENDENCY = yes
export boot_app_ospi_COMP_LIST
export boot_app_ospi_BOARD_DEPENDENCY
export boot_app_ospi_SOC_DEPENDENCY
export boot_app_ospi_CORE_DEPENDENCY
boot_app_ospi_PKG_LIST = boot_app_ospi
boot_app_ospi_INCLUDE = $(boot_app_ospi_PATH)
boot_app_ospi_SOCLIST = $(sbl_SOCLIST)
boot_app_ospi_BOARDLIST = $(sbl_BOARDLIST)
export boot_app_ospi_SOCLIST
export boot_app_ospi_BOARDLIST
boot_app_ospi_$(SOC)_CORELIST = mcu1_0
export boot_app_ospi_$(SOC)_CORELIST
sbl_EXAMPLE_LIST += boot_app_ospi
boot_app_ospi_SBL_APPIMAGEGEN = yes
export boot_app_ospi_SBL_APPIMAGEGEN

# Boot App OSPI NAND
boot_app_ospi_nand_COMP_LIST = boot_app_ospi_nand
boot_app_ospi_nand_RELPATH = ti/boot/sbl/example/boot_app
boot_app_ospi_nand_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/example/boot_app/binary/$(BOARD)/ospi_nand
boot_app_ospi_nand_PATH = $(PDK_SBL_COMP_PATH)/example/boot_app
boot_app_ospi_nand_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/boot_app.mk BOOTMODE=ospi_nand BOOT_OSPI_NAND=yes BUILD_HS=no HLOSBOOT=none CANRESP=disabled
export boot_app_ospi_nand_MAKEFILE
boot_app_ospi_nand_BOARD_DEPENDENCY = yes
boot_app_ospi_nand_SOC_DEPENDENCY = yes
boot_app_ospi_nand_CORE_DEPENDENCY = yes
export boot_app_ospi_nand_COMP_LIST
export boot_app_ospi_nand_BOARD_DEPENDENCY
export boot_app_ospi_nand_SOC_DEPENDENCY
export boot_app_ospi_nand_CORE_DEPENDENCY
boot_app_ospi_nand_PKG_LIST = boot_app_ospi_nand
boot_app_ospi_nand_INCLUDE = $(boot_app_ospi_nand_PATH)
boot_app_ospi_nand_SOCLIST = $(sbl_SOCLIST)
boot_app_ospi_nand_BOARDLIST = $(sbl_BOARDLIST)
export boot_app_ospi_nand_SOCLIST
export boot_app_ospi_nand_BOARDLIST
boot_app_ospi_nand_$(SOC)_CORELIST = mcu1_0
export boot_app_ospi_nand_$(SOC)_CORELIST
sbl_EXAMPLE_LIST += boot_app_ospi_nand
boot_app_ospi_nand_SBL_APPIMAGEGEN = yes
export boot_app_ospi_nand_SBL_APPIMAGEGEN

# Boot App OSPI to boot qnx
boot_app_ospi_qnx_COMP_LIST = boot_app_ospi_qnx
boot_app_ospi_qnx_RELPATH = ti/boot/sbl/example/boot_app
boot_app_ospi_qnx_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/example/boot_app/binary/$(BOARD)/ospi
boot_app_ospi_qnx_PATH = $(PDK_SBL_COMP_PATH)/example/boot_app
boot_app_ospi_qnx_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/boot_app.mk BOOTMODE=ospi BUILD_HS=no HLOSBOOT=qnx
export boot_app_ospi_qnx_MAKEFILE
boot_app_ospi_qnx_BOARD_DEPENDENCY = yes
boot_app_ospi_qnx_SOC_DEPENDENCY = yes
boot_app_ospi_qnx_CORE_DEPENDENCY = yes
export boot_app_ospi_qnx_COMP_LIST
export boot_app_ospi_qnx_BOARD_DEPENDENCY
export boot_app_ospi_qnx_SOC_DEPENDENCY
export boot_app_ospi_qnx_CORE_DEPENDENCY
boot_app_ospi_qnx_PKG_LIST = boot_app_ospi_qnx
boot_app_ospi_qnx_INCLUDE = $(boot_app_ospi_qnx_PATH)
boot_app_ospi_qnx_SOCLIST = $(sbl_SOCLIST)
boot_app_ospi_qnx_BOARDLIST = $(sbl_BOARDLIST)
export boot_app_ospi_qnx_SOCLIST
export boot_app_ospi_qnx_BOARDLIST
boot_app_ospi_qnx_$(SOC)_CORELIST = mcu1_0
export boot_app_ospi_qnx_$(SOC)_CORELIST
sbl_EXAMPLE_LIST += boot_app_ospi_qnx
boot_app_ospi_qnx_SBL_APPIMAGEGEN = yes
export boot_app_ospi_qnx_SBL_APPIMAGEGEN

# Boot App OSPI to boot linux
boot_app_ospi_linux_COMP_LIST = boot_app_ospi_linux
boot_app_ospi_linux_RELPATH = ti/boot/sbl/example/boot_app
boot_app_ospi_linux_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/example/boot_app/binary/$(BOARD)/ospi
boot_app_ospi_linux_PATH = $(PDK_SBL_COMP_PATH)/example/boot_app
boot_app_ospi_linux_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/boot_app.mk BOOTMODE=ospi BUILD_HS=no HLOSBOOT=linux
export boot_app_ospi_linux_MAKEFILE
boot_app_ospi_linux_BOARD_DEPENDENCY = yes
boot_app_ospi_linux_SOC_DEPENDENCY = yes
boot_app_ospi_linux_CORE_DEPENDENCY = yes
export boot_app_ospi_linux_COMP_LIST
export boot_app_ospi_linux_BOARD_DEPENDENCY
export boot_app_ospi_linux_SOC_DEPENDENCY
export boot_app_ospi_linux_CORE_DEPENDENCY
boot_app_ospi_linux_PKG_LIST = boot_app_ospi_linux
boot_app_ospi_linux_INCLUDE = $(boot_app_ospi_linux_PATH)
boot_app_ospi_linux_SOCLIST = $(sbl_SOCLIST)
boot_app_ospi_linux_BOARDLIST = $(sbl_BOARDLIST)
export boot_app_ospi_linux_SOCLIST
export boot_app_ospi_linux_BOARDLIST
boot_app_ospi_linux_$(SOC)_CORELIST = mcu1_0
export boot_app_ospi_linux_$(SOC)_CORELIST
sbl_EXAMPLE_LIST += boot_app_ospi_linux
boot_app_ospi_linux_SBL_APPIMAGEGEN = yes
export boot_app_ospi_linux_SBL_APPIMAGEGEN

# Boot App MMCSD
boot_app_mmcsd_COMP_LIST = boot_app_mmcsd
boot_app_mmcsd_RELPATH = ti/boot/sbl/example/boot_app
boot_app_mmcsd_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/example/boot_app/binary/$(BOARD)/mmcsd
boot_app_mmcsd_PATH = $(PDK_SBL_COMP_PATH)/example/boot_app
boot_app_mmcsd_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/boot_app.mk BOOTMODE=mmcsd BUILD_HS=no HLOSBOOT=none
export boot_app_mmcsd_MAKEFILE
boot_app_mmcsd_BOARD_DEPENDENCY = yes
boot_app_mmcsd_SOC_DEPENDENCY = yes
boot_app_mmcsd_CORE_DEPENDENCY = yes
export boot_app_mmcsd_COMP_LIST
export boot_app_mmcsd_BOARD_DEPENDENCY
export boot_app_mmcsd_SOC_DEPENDENCY
export boot_app_mmcsd_CORE_DEPENDENCY
boot_app_mmcsd_PKG_LIST = boot_app_mmcsd
boot_app_mmcsd_INCLUDE = $(boot_app_mmcsd_PATH)
boot_app_mmcsd_SOCLIST = $(sbl_SOCLIST)
boot_app_mmcsd_BOARDLIST = $(sbl_BOARDLIST)
export boot_app_mmcsd_SOCLIST
export boot_app_mmcsd_BOARDLIST
boot_app_mmcsd_$(SOC)_CORELIST = mcu1_0
export boot_app_mmcsd_$(SOC)_CORELIST
sbl_EXAMPLE_LIST += boot_app_mmcsd
boot_app_mmcsd_SBL_APPIMAGEGEN = yes
export boot_app_mmcsd_SBL_APPIMAGEGEN

# Boot App MMCSD with safety loop enabled
boot_app_mmcsd_safety_COMP_LIST = boot_app_mmcsd_safety
boot_app_mmcsd_safety_RELPATH = ti/boot/sbl/example/boot_app
boot_app_mmcsd_safety_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/example/boot_app/binary/$(BOARD)/mmcsd
boot_app_mmcsd_safety_PATH = $(PDK_SBL_COMP_PATH)/example/boot_app
boot_app_mmcsd_safety_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/boot_app.mk BOOTMODE=mmcsd SAFETY_LOOP=yes
export boot_app_mmcsd_safety_MAKEFILE
boot_app_mmcsd_safety_BOARD_DEPENDENCY = yes
boot_app_mmcsd_safety_SOC_DEPENDENCY = yes
boot_app_mmcsd_safety_CORE_DEPENDENCY = yes
export boot_app_mmcsd_safety_COMP_LIST
export boot_app_mmcsd_safety_BOARD_DEPENDENCY
export boot_app_mmcsd_safety_SOC_DEPENDENCY
export boot_app_mmcsd_safety_CORE_DEPENDENCY
boot_app_mmcsd_safety_PKG_LIST = boot_app_mmcsd_safety
boot_app_mmcsd_safety_INCLUDE = $(boot_app_mmcsd_safety_PATH)
boot_app_mmcsd_safety_SOCLIST = $(sbl_SOCLIST)
boot_app_mmcsd_safety_BOARDLIST = $(sbl_BOARDLIST)
export boot_app_mmcsd_safety_SOCLIST
export boot_app_mmcsd_safety_BOARDLIST
boot_app_mmcsd_safety_$(SOC)_CORELIST = mcu1_0
export boot_app_mmcsd_safety_$(SOC)_CORELIST
sbl_EXAMPLE_LIST += boot_app_mmcsd_safety
boot_app_mmcsd_safety_SBL_APPIMAGEGEN = yes
export boot_app_mmcsd_safety_SBL_APPIMAGEGEN

# Boot App MMCSD to boot qnx
boot_app_mmcsd_qnx_COMP_LIST = boot_app_mmcsd_qnx
boot_app_mmcsd_qnx_RELPATH = ti/boot/sbl/example/boot_app
boot_app_mmcsd_qnx_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/example/boot_app/binary/$(BOARD)/mmcsd
boot_app_mmcsd_qnx_PATH = $(PDK_SBL_COMP_PATH)/example/boot_app
boot_app_mmcsd_qnx_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/boot_app.mk BOOTMODE=mmcsd BUILD_HS=no HLOSBOOT=qnx
export boot_app_mmcsd_qnx_MAKEFILE
boot_app_mmcsd_qnx_BOARD_DEPENDENCY = yes
boot_app_mmcsd_qnx_SOC_DEPENDENCY = yes
boot_app_mmcsd_qnx_CORE_DEPENDENCY = yes
export boot_app_mmcsd_qnx_COMP_LIST
export boot_app_mmcsd_qnx_BOARD_DEPENDENCY
export boot_app_mmcsd_qnx_SOC_DEPENDENCY
export boot_app_mmcsd_qnx_CORE_DEPENDENCY
boot_app_mmcsd_qnx_PKG_LIST = boot_app_mmcsd_qnx
boot_app_mmcsd_qnx_INCLUDE = $(boot_app_mmcsd_qnx_PATH)
boot_app_mmcsd_qnx_SOCLIST = $(sbl_SOCLIST)
boot_app_mmcsd_qnx_BOARDLIST = $(sbl_BOARDLIST)
export boot_app_mmcsd_qnx_SOCLIST
export boot_app_mmcsd_qnx_BOARDLIST
boot_app_mmcsd_qnx_$(SOC)_CORELIST = mcu1_0
export boot_app_mmcsd_qnx_$(SOC)_CORELIST
sbl_EXAMPLE_LIST += boot_app_mmcsd_qnx
boot_app_mmcsd_qnx_SBL_APPIMAGEGEN = yes
export boot_app_mmcsd_qnx_SBL_APPIMAGEGEN

# Boot App MMCSD to boot linux
boot_app_mmcsd_linux_COMP_LIST = boot_app_mmcsd_linux
boot_app_mmcsd_linux_RELPATH = ti/boot/sbl/example/boot_app
boot_app_mmcsd_linux_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/example/boot_app/binary/$(BOARD)/mmcsd
boot_app_mmcsd_linux_PATH = $(PDK_SBL_COMP_PATH)/example/boot_app
boot_app_mmcsd_linux_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/boot_app.mk BOOTMODE=mmcsd BUILD_HS=no HLOSBOOT=linux
export boot_app_mmcsd_linux_MAKEFILE
boot_app_mmcsd_linux_BOARD_DEPENDENCY = yes
boot_app_mmcsd_linux_SOC_DEPENDENCY = yes
boot_app_mmcsd_linux_CORE_DEPENDENCY = yes
export boot_app_mmcsd_linux_COMP_LIST
export boot_app_mmcsd_linux_BOARD_DEPENDENCY
export boot_app_mmcsd_linux_SOC_DEPENDENCY
export boot_app_mmcsd_linux_CORE_DEPENDENCY
boot_app_mmcsd_linux_PKG_LIST = boot_app_mmcsd_linux
boot_app_mmcsd_linux_INCLUDE = $(boot_app_mmcsd_linux_PATH)
boot_app_mmcsd_linux_SOCLIST = $(sbl_SOCLIST)
boot_app_mmcsd_linux_BOARDLIST = $(sbl_BOARDLIST)
export boot_app_mmcsd_linux_SOCLIST
export boot_app_mmcsd_linux_BOARDLIST
boot_app_mmcsd_linux_$(SOC)_CORELIST = mcu1_0
export boot_app_mmcsd_linux_$(SOC)_CORELIST
sbl_EXAMPLE_LIST += boot_app_mmcsd_linux
boot_app_mmcsd_linux_SBL_APPIMAGEGEN = yes
export boot_app_mmcsd_linux_SBL_APPIMAGEGEN

# Boot App OSPI HS
boot_app_ospi_hs_COMP_LIST = boot_app_ospi_hs
boot_app_ospi_hs_RELPATH = ti/boot/sbl/example/boot_app
boot_app_ospi_hs_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/example/boot_app/binary/$(BOARD)_hs/ospi
boot_app_ospi_hs_PATH = $(PDK_SBL_COMP_PATH)/example/boot_app
boot_app_ospi_hs_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/boot_app.mk BOOTMODE=ospi BUILD_HS=yes HLOSBOOT=none
export boot_app_ospi_hs_MAKEFILE
boot_app_ospi_hs_BOARD_DEPENDENCY = yes
boot_app_ospi_hs_SOC_DEPENDENCY = yes
boot_app_ospi_hs_CORE_DEPENDENCY = yes
export boot_app_ospi_hs_COMP_LIST
export boot_app_ospi_hs_BOARD_DEPENDENCY
export boot_app_ospi_hs_SOC_DEPENDENCY
export boot_app_ospi_hs_CORE_DEPENDENCY
boot_app_ospi_hs_PKG_LIST = boot_app_ospi_hs
boot_app_ospi_hs_INCLUDE = $(boot_app_ospi_hs_PATH)
boot_app_ospi_hs_SOCLIST = $(sbl_SOCLIST)
boot_app_ospi_hs_BOARDLIST = $(sbl_BOARDLIST)
export boot_app_ospi_hs_SOCLIST
export boot_app_ospi_hs_BOARDLIST
boot_app_ospi_hs_$(SOC)_CORELIST = mcu1_0
export boot_app_ospi_hs_$(SOC)_CORELIST
sbl_EXAMPLE_LIST += boot_app_ospi_hs
boot_app_ospi_hs_SBL_APPIMAGEGEN = yes
export boot_app_ospi_hs_SBL_APPIMAGEGEN

# Boot App OSPI HS to boot qnx
boot_app_ospi_qnx_hs_COMP_LIST = boot_app_ospi_qnx_hs
boot_app_ospi_qnx_hs_RELPATH = ti/boot/sbl/example/boot_app
boot_app_ospi_qnx_hs_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/example/boot_app/binary/$(BOARD)_hs/ospi
boot_app_ospi_qnx_hs_PATH = $(PDK_SBL_COMP_PATH)/example/boot_app
boot_app_ospi_qnx_hs_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/boot_app.mk BOOTMODE=ospi BUILD_HS=yes HLOSBOOT=qnx
export boot_app_ospi_qnx_hs_MAKEFILE
boot_app_ospi_qnx_hs_BOARD_DEPENDENCY = yes
boot_app_ospi_qnx_hs_SOC_DEPENDENCY = yes
boot_app_ospi_qnx_hs_CORE_DEPENDENCY = yes
export boot_app_ospi_qnx_hs_COMP_LIST
export boot_app_ospi_qnx_hs_BOARD_DEPENDENCY
export boot_app_ospi_qnx_hs_SOC_DEPENDENCY
export boot_app_ospi_qnx_hs_CORE_DEPENDENCY
boot_app_ospi_qnx_hs_PKG_LIST = boot_app_ospi_qnx_hs
boot_app_ospi_qnx_hs_INCLUDE = $(boot_app_ospi_qnx_hs_PATH)
boot_app_ospi_qnx_hs_SOCLIST = $(sbl_SOCLIST)
boot_app_ospi_qnx_hs_BOARDLIST = $(sbl_BOARDLIST)
export boot_app_ospi_qnx_hs_SOCLIST
export boot_app_ospi_qnx_hs_BOARDLIST
boot_app_ospi_qnx_hs_$(SOC)_CORELIST = mcu1_0
export boot_app_ospi_qnx_hs_$(SOC)_CORELIST
sbl_EXAMPLE_LIST += boot_app_ospi_qnx_hs
boot_app_ospi_qnx_hs_SBL_APPIMAGEGEN = yes
export boot_app_ospi_qnx_hs_SBL_APPIMAGEGEN

# Boot App MMCSD HS
boot_app_mmcsd_hs_COMP_LIST = boot_app_mmcsd_hs
boot_app_mmcsd_hs_RELPATH = ti/boot/sbl/example/boot_app
boot_app_mmcsd_hs_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/example/boot_app/binary/$(BOARD)_hs/mmcsd
boot_app_mmcsd_hs_PATH = $(PDK_SBL_COMP_PATH)/example/boot_app
boot_app_mmcsd_hs_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/boot_app.mk BOOTMODE=mmcsd BUILD_HS=yes HLOSBOOT=none
export boot_app_mmcsd_hs_MAKEFILE
boot_app_mmcsd_hs_BOARD_DEPENDENCY = yes
boot_app_mmcsd_hs_SOC_DEPENDENCY = yes
boot_app_mmcsd_hs_CORE_DEPENDENCY = yes
export boot_app_mmcsd_hs_COMP_LIST
export boot_app_mmcsd_hs_BOARD_DEPENDENCY
export boot_app_mmcsd_hs_SOC_DEPENDENCY
export boot_app_mmcsd_hs_CORE_DEPENDENCY
boot_app_mmcsd_hs_PKG_LIST = boot_app_mmcsd
boot_app_mmcsd_hs_INCLUDE = $(boot_app_mmcsd_PATH)
boot_app_mmcsd_hs_SOCLIST = $(sbl_SOCLIST)
boot_app_mmcsd_hs_BOARDLIST = $(sbl_BOARDLIST)
export boot_app_mmcsd_hs_SOCLIST
export boot_app_mmcsd_hs_BOARDLIST
boot_app_mmcsd_hs_$(SOC)_CORELIST = mcu1_0
export boot_app_mmcsd_hs_$(SOC)_CORELIST
sbl_EXAMPLE_LIST += boot_app_mmcsd_hs
boot_app_mmcsd_hs_SBL_APPIMAGEGEN = yes
export boot_app_mmcsd_hs_SBL_APPIMAGEGEN

# Boot App MMCSD HS to boot qnx
boot_app_mmcsd_qnx_hs_COMP_LIST = boot_app_mmcsd_qnx_hs
boot_app_mmcsd_qnx_hs_RELPATH = ti/boot/sbl/example/boot_app
boot_app_mmcsd_qnx_hs_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/example/boot_app/binary/$(BOARD)_hs/mmcsd
boot_app_mmcsd_qnx_hs_PATH = $(PDK_SBL_COMP_PATH)/example/boot_app
boot_app_mmcsd_qnx_hs_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/build/boot_app.mk BOOTMODE=mmcsd BUILD_HS=yes HLOSBOOT=qnx
export boot_app_mmcsd_qnx_hs_MAKEFILE
boot_app_mmcsd_qnx_hs_BOARD_DEPENDENCY = yes
boot_app_mmcsd_qnx_hs_SOC_DEPENDENCY = yes
boot_app_mmcsd_qnx_hs_CORE_DEPENDENCY = yes
export boot_app_mmcsd_qnx_hs_COMP_LIST
export boot_app_mmcsd_qnx_hs_BOARD_DEPENDENCY
export boot_app_mmcsd_qnx_hs_SOC_DEPENDENCY
export boot_app_mmcsd_qnx_hs_CORE_DEPENDENCY
boot_app_mmcsd_qnx_hs_PKG_LIST = boot_app_mmcsd
boot_app_mmcsd_qnx_hs_INCLUDE = $(boot_app_mmcsd_PATH)
boot_app_mmcsd_qnx_hs_SOCLIST = $(sbl_SOCLIST)
boot_app_mmcsd_qnx_hs_BOARDLIST = $(sbl_BOARDLIST)
export boot_app_mmcsd_qnx_hs_SOCLIST
export boot_app_mmcsd_qnx_hs_BOARDLIST
boot_app_mmcsd_qnx_hs_$(SOC)_CORELIST = mcu1_0
export boot_app_mmcsd_qnx_hs_$(SOC)_CORELIST
sbl_EXAMPLE_LIST += boot_app_mmcsd_qnx_hs
boot_app_mmcsd_qnx_hs_SBL_APPIMAGEGEN = yes
export boot_app_mmcsd_qnx_hs_SBL_APPIMAGEGEN

# SBL example to verify EEPROM read functionality
export sbl_eeprom_test_COMP_LIST = sbl_eeprom_test
sbl_eeprom_test_RELPATH = ti/boot/sbl/example/eeprom_test
sbl_eeprom_test_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/example/binary/$(BOARD)
sbl_eeprom_test_PATH = $(PDK_SBL_COMP_PATH)/example/eeprom_test
export sbl_eeprom_test_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/example/eeprom_test/makefile
export sbl_eeprom_test_BOARD_DEPENDENCY = yes
export sbl_eeprom_test_SOC_DEPENDENCY = no
export sbl_eeprom_test_CORE_DEPENDENCY = no
sbl_eeprom_test_PKG_LIST = sbl_eeprom_test
sbl_eeprom_test_INCLUDE = $(sbl_eeprom_test_PATH)
export sbl_eeprom_test_BOARDLIST = $(sbl_BOARDLIST)
export sbl_eeprom_test_$(SOC)_CORELIST = mcu1_0
export sbl_eeprom_test_SBL_APPIMAGEGEN = yes
sbl_EXAMPLE_LIST += sbl_eeprom_test

# SBL example to verify whether non-booted cores are properly switched off or not
export sbl_non_booted_core_test_COMP_LIST = sbl_non_booted_core_test
sbl_non_booted_core_test_RELPATH = ti/boot/sbl/example/non_booted_core_test
sbl_non_booted_core_test_CUSTOM_BINPATH = $(PDK_SBL_COMP_PATH)/example/binary/$(BOARD)/non_booted_core_test
sbl_non_booted_core_test_PATH = $(PDK_SBL_COMP_PATH)/example/non_booted_core_test
export sbl_non_booted_core_test_MAKEFILE = -f$(PDK_SBL_COMP_PATH)/example/non_booted_core_test/makefile
export sbl_non_booted_core_test_BOARD_DEPENDENCY = yes
export sbl_non_booted_core_test_SOC_DEPENDENCY = no
export sbl_non_booted_core_test_CORE_DEPENDENCY = no
sbl_non_booted_core_test_PKG_LIST = sbl_non_booted_core_test
sbl_non_booted_core_test_INCLUDE = $(sbl_non_booted_core_test_PATH)
export sbl_non_booted_core_test_BOARDLIST = $(sbl_BOARDLIST)
export sbl_non_booted_core_test_$(SOC)_CORELIST = mcu1_0
export sbl_non_booted_core_test_SBL_APPIMAGEGEN = yes
sbl_EXAMPLE_LIST += sbl_non_booted_core_test

# SBL not supported for any profile
# other than release
ifneq ($(BUILD_PROFILE), release)
sbl_LIB_LIST =
sbl_EXAMPLE_LIST =
SBL_CFLAGS =
endif # ifneq ($(BUILD_PROFILE), release)

export sbl_LIB_LIST
export sbl_EXAMPLE_LIST
export SBL_CFLAGS

sbl_component_make_include := 1
endif
