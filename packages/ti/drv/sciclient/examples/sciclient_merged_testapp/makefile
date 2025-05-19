#
# This file is the makefile for building Sciclient merged test application.
#
ifeq ($(RULES_MAKE), )
include $(PDK_INSTALL_PATH)/ti/build/Rules.make
else
include $(RULES_MAKE)
endif

APP_NAME = sciclient_merged_testapp_$(BUILD_OS_TYPE)

HS_SUFFIX=
ifeq ($(BUILD_HS), yes)
HS_SUFFIX=_hs
endif

SRCDIR = . $(PDK_INSTALL_PATH)/ti/drv/sciclient/examples/common
INCDIR = . $(PDK_INSTALL_PATH)/ti/drv/sciclient/examples/common

COMP_LIST_COMMON = csl csl_init uart i2c board rm_pm_hal sciclient_merged$(HS_SUFFIX)

ifeq ($(BUILD_OS_TYPE), freertos)
CFLAGS_OS_DEFINES = -DFREERTOS
COMP_LIST_COMMON  += osal_freertos freertos
EXTERNAL_INTERFACES = freertos
endif

ifeq ($(BUILD_OS_TYPE), safertos)
CFLAGS_OS_DEFINES = -DSAFERTOS
COMP_LIST_COMMON  += osal_safertos safertos
EXTERNAL_INTERFACES = safertos
endif

# List all the external components/interfaces, whose interface header files
# need to be included for this component
INCLUDE_EXTERNAL_INTERFACES = pdk sciclient_merged board uart $(EXTERNAL_INTERFACES)

# Common source files and CFLAGS across all platforms and cores
SRCS_COMMON = sciclient_merged_main.c \
              sci_app_common.c

CFLAGS_LOCAL_COMMON = $(PDK_CFLAGS) $(CFLAGS_OS_DEFINES)
PACKAGE_SRCS_COMMON = . ../common

# When building app for cores other than MCU1_0, then MCU1_0 should host sciclient server.
# Not required when running app on MCU1_0.
# Please refer the user guide for more details on sciclient server.

ifeq ($(SOC),$(filter $(SOC), j721e j7200 j721s2 j784s4 j742s2))
  SCI_CUSTOM_MULTI_CORE_APP_PARAMS = $(SBL_CORE_ID_mcu1_0) $(PDK_INSTALL_PATH)/ti/binary/sciserver_testapp_freertos/bin/$(SOC)/sciserver_testapp_freertos_mcu1_0_$(BUILD_PROFILE).rprc
else
  SCI_CUSTOM_MULTI_CORE_APP_PARAMS =
endif

ifeq ($(BUILD_CORE),$(filter $(BUILD_CORE), mcu1_0))
  SCI_CUSTOM_MULTI_CORE_APP_PARAMS =
endif

# MCUx_1 cores require a dummy application to run from MCUx_0 core
# as MCUx_1 core cannot be at a higher power state than MCUx_0 core.
# In case of mcu1_1, mcu1_0 always host the server, so dummy app is not needed for MCU1_0
ifeq ($(SOC),$(filter $(SOC), j721e j7200 j721s2 j784s4 j742s2))
  ifeq ($(BUILD_CORE),$(filter $(BUILD_CORE), mcu2_1))
  SCI_CUSTOM_MULTI_CORE_APP_PARAMS += $(SBL_CORE_ID_mcu2_0) $(PDK_INSTALL_PATH)/ti/build/$(SOC)/sbl_mcux_0_dummy_app.rprc
  endif
  ifeq ($(BUILD_CORE),$(filter $(BUILD_CORE), mcu3_1))
  SCI_CUSTOM_MULTI_CORE_APP_PARAMS += $(SBL_CORE_ID_mcu3_0) $(PDK_INSTALL_PATH)/ti/build/$(SOC)/sbl_mcux_0_dummy_app.rprc
  endif
  ifeq ($(BUILD_CORE),$(filter $(BUILD_CORE), mcu4_1))
  SCI_CUSTOM_MULTI_CORE_APP_PARAMS += $(SBL_CORE_ID_mcu4_0) $(PDK_INSTALL_PATH)/ti/build/$(SOC)/sbl_mcux_0_dummy_app.rprc
  endif
endif

SCI_CUSTOM_APPIMAGE_PATH = $(BINDIR)/$(APP_NAME)_$(BUILD_CORE)_$(BUILD_PROFILE).appimage
SCI_CUSTOM_APPIMAGE_PATH_BE = $(BINDIR)/$(APP_NAME)_$(BUILD_CORE)_$(BUILD_PROFILE)_BE.appimage
SCI_CUSTOM_RPRC_PATH = $(BINDIR)/$(APP_NAME)_$(BUILD_CORE)_$(BUILD_PROFILE).rprc
SCI_CUSTOM_MULTI_CORE_APP_PARAMS += $(SBL_CORE_ID_$(BUILD_CORE)) $(SCI_CUSTOM_RPRC_PATH)
SCI_CUSTOM_EXE_NAME = $(BINDIR)/$(APP_NAME)_$(CORE)_$(BUILD_PROFILE).$(EXEEXT)

ifneq ($(SCI_BUILD_INTERNAL),yes)
gen_appimage:
	$(MAKE) -C $($(APP_NAME)_PATH) $($(APP_NAME)_MAKEFILE) SCI_BUILD_INTERNAL=yes
ifneq ($(BUILD_CORE), mcu1_0)
	$(MAKE) -C $(sciserver_testapp_freertos_PATH) $(sciserver_testapp_freertos_MAKEFILE) SCI_BUILD_INTERNAL=yes
	$(RM) -f $(PDK_INSTALL_PATH)/ti/binary/sciserver_testapp_freertos/bin/$(SOC)/sciserver_testapp_freertos_mcu1_0_$(BUILD_PROFILE).rprc
	$(SBL_OUTRPRC) $(PDK_INSTALL_PATH)/ti/binary/sciserver_testapp_freertos/bin/$(SOC)/sciserver_testapp_freertos_mcu1_0_$(BUILD_PROFILE).xer5f $(PDK_INSTALL_PATH)/ti/binary/sciserver_testapp_freertos/bin/$(SOC)/sciserver_testapp_freertos_mcu1_0_$(BUILD_PROFILE).rprc >> $(SBL_STDOUT_FILE)
endif
	$(RM) -f $(SCI_CUSTOM_APPIMAGE_PATH) $(SCI_CUSTOM_APPIMAGE_PATH_BE) $(SCI_CUSTOM_RPRC_PATH)
	$(SBL_OUTRPRC) $(SCI_CUSTOM_EXE_NAME) $(SCI_CUSTOM_RPRC_PATH) >> $(SBL_STDOUT_FILE)
ifneq ($(OS),Windows_NT)
	$(CHMOD) a+x $(SBL_IMAGE_GEN)
endif
	$(SBL_IMAGE_GEN) LE $(SBL_DEV_ID) $(SCI_CUSTOM_APPIMAGE_PATH) $(SCI_CUSTOM_MULTI_CORE_APP_PARAMS) >> $(SBL_STDOUT_FILE)
	$(SBL_IMAGE_GEN) BE $(SBL_DEV_ID) $(SCI_CUSTOM_APPIMAGE_PATH_BE) $(SCI_CUSTOM_MULTI_CORE_APP_PARAMS) >> $(SBL_STDOUT_FILE)
ifneq ($(OS),Windows_NT)
	$(CHMOD) a+x $(SBL_CERT_GEN)
endif
	$(SBL_CERT_GEN) -b $(SCI_CUSTOM_APPIMAGE_PATH) -o $(SCI_CUSTOM_APPIMAGE_PATH).signed -c R5 -l $(SBL_RUN_ADDRESS) -k $(SBL_CERT_KEY_HS)
	$(SBL_CERT_GEN) -b $(SCI_CUSTOM_APPIMAGE_PATH) -o $(SCI_CUSTOM_APPIMAGE_PATH).hs_fs -c R5 -l $(SBL_RUN_ADDRESS) -k $(SBL_CERT_KEY)
endif

# Core/SoC/platform specific source files and CFLAGS
# Example:
#   SRCS_<coqre/SoC/platform-name> =
#   CFLAGS_LOCAL_<core/SoC/platform-name> =

# Include common make files
ifeq ($(MAKERULEDIR), )
#Makerule path not defined, define this and assume relative path from ROOTDIR
  MAKERULEDIR := $(ROOTDIR)/ti/build/makerules
  export MAKERULEDIR
endif
include $(MAKERULEDIR)/common.mk

# OBJs and libraries are built by using rule defined in rules_<target>.mk
#     and need not be explicitly specified here

# Nothing beyond this point
