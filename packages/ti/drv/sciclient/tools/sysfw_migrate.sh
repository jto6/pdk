#!/bin/bash
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
# Usage : sysfw_migrate.sh <release tag> [OPTIONS]

################################################################################
export RM=rm
export MV=mv
export MKDIR=mkdir
export MAKE=gcc
export ECHO=echo
export CHMOD=chmod
export COPY=cp
export CAT=cat

################################################################################
# Parse CLI arguments
RELEASE_TAG=$1
SOC_LIST="j721e j7200 j721s2 j784s4 j742s2"
for i in "$@"; do
case $i in
    -sr|--skip-reset) # Skips the PDK reset and rebase step
        SKIP_RESET=YES
        shift
        ;;
    -sk|--skip-checkout) # Skips the SYSFW checkout step
        SKIP_CHECKOUT=YES
        shift
        ;;
    -sb|--skip-build) # Skips the sciclient binaries build step
        SKIP_BUILD=YES
        shift
        ;;
    -sg|--skip-gen) # Skips the firmwareHeaderGen.sh step
        SKIP_GEN_BIN=YES
        shift
        ;;
    -sc|--skip-commit) # Skips the PDK commit step
        SKIP_COMMIT=YES
        shift
        ;;
    -st|--skip-testreport) # Skips the Copy SYSFW Test Report step
        SKIP_TEST_REPORT=YES
        shift
        ;;
    --soc=*) #List of SOC's
        if [ "${i#*=}" != "" ]; then
            SOC_LIST="${i#*=}"
        fi
        shift
        ;;
    -gf|--generate-firmwares) # generate DM and ipc firmwares
        GEN_DM_IPC=YES
        shift
        ;;
    -gl|--generate-lpr) # generate firmware patches for LPR
        GEN_LPR_PATCH=YES
        shift
        ;;
    -h|--help)
        $ECHO "Usage : sysfw_migrate.sh <release tag> [OPTIONS]"
        $ECHO
        $ECHO "OPTIONS:-"
        $ECHO " -sr or --skip-reset           : Skips the PDK reset and rebase step"
        $ECHO " -sk or --skip-checkout        : Skips the SYSFW checkout step"
        $ECHO " -sb or --skip-build           : Skips the sciclient binaries build step"
        $ECHO " -sg or --skip-gen             : Skips the firmwareHeaderGen.sh step"
        $ECHO " -sc or --skip-commit          : Skips the PDK commit step"
        $ECHO " -gf or --generate-firmwares   : Generate DM and ipc firmwares"
        $ECHO " -gl or --generate-lpr         : Generate firmware patches for LPR"
        $ECHO " --soc=\"\<soc_list\>\" : List of SOCs. Default will be all supported SOCs"
        $ECHO "     Supported SOCs:-"
        $ECHO "     - j721e"
        $ECHO "     - j7200"
        $ECHO "     - j721s2"
        $ECHO "     - j784s4"
        $ECHO "    For example, --soc=\"j721e\" or  --soc=\"j721e j7200\""
        exit 0
        ;;
    -*) # Invalid flag
        $ECHO "!!!WARNING!!! - IGNORING INVALID FLAG: $1"
        shift
        ;;
esac
done

# Check CLI positional args (must always include a SYSFW release tag)
if [ "$RELEASE_TAG" == "" ]; then
    $ECHO "Usage : sysfw_migrate.sh <release tag> <soc_list>(optional) [OPTIONS]"
    exit 1
fi

################################################################################
# Specify paths relative to script
export SCRIPT_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}")" && pwd )
export SCI_CLIENT_DIR=$(cd "$SCRIPT_DIR/.." && pwd )
export ROOTDIR=$(cd "$SCI_CLIENT_DIR/../../.." && pwd )
export PDK_DIR=$(cd "$ROOTDIR/.." && pwd )

$ECHO " Starting TIFS Migration for $SOC_LIST "

################################################################################
# Checkout SYSFW release and prepare it for use with PDK

if [ "$SKIP_RESET" != "YES" ]; then
    $ECHO "Reset PDK branch and rebase onto master"
    git reset --hard HEAD
    git fetch origin; git rebase origin/master

    cd $PDK_DIR/docs/
    $ECHO "Reset PDK_DOCS branch and rebase onto master"
    git reset --hard HEAD
    git fetch origin; git rebase origin/master
fi

if [ "$SKIP_CHECKOUT" != "YES" ]; then

    $ECHO "Cloning the system-firmware-releases"
    cd $SCI_CLIENT_DIR/soc/
    git clone ssh://git@bitbucket.itg.ti.com/sysfw/system-firmware-releases.git --branch $RELEASE_TAG
    if [ $? -ne 0 ]; then
        $ECHO
        $ECHO "!!!ABORT!!! - SYSFW TAG NOT FOUND: $RELEASE_TAG"
        exit 1
    fi

    $ECHO "Remove old SYSFW dir, and replace it with the newly cloned repo"
    $RM -fr sysfw/binaries/scripts
    $MV system-firmware-releases/binaries/scripts sysfw/binaries
    $RM -fr sysfw/binaries/system-firmware-public-documentation
    $MV system-firmware-releases/binaries/system-firmware-public-documentation sysfw/binaries
    $MV system-firmware-releases/binaries/ti-fs*j7*gp.bin sysfw/binaries
    $MV system-firmware-releases/binaries/ti-fs*j7*cert.bin sysfw/binaries
    $MV system-firmware-releases/binaries/ti-fs*j7*enc.bin sysfw/binaries
    $MV system-firmware-releases/reports sysfw/reports
    $RM -fr sysfw/include/tisci
    $COPY -r system-firmware-releases/include/tisci sysfw/include
    for SOC in $SOC_LIST
    do
        if [ "$SOC" = "j742s2" ]; then
            echo "j742s2 uses same sysfw include folder as j784s4. Skipping further actions."
            continue
        fi
        $RM -fr sysfw/include/$SOC
        $MV system-firmware-releases/include/$SOC sysfw/include
    done

    $RM -fr system-firmware-release



    cd sysfw

    $ECHO "Removing files not required from SYSFW release.."
    $RM -fr .git
    $RM -fr src
    $RM -fr log
    $RM -fr binaries/system-firmware-design-documentation
    $RM -fr binaries/system-firmware-full-documentation
    $RM -fr docs/BUILD.md
fi

if [ "$SKIP_TEST_REPORT" != "YES" ]; then
    
    $ECHO "Copy SYSFW Test report to pdk_docs.."
    cd $PDK_DIR/docs/

    for SOC in $SOC_LIST
    do
        $COPY $SCI_CLIENT_DIR/soc/sysfw/reports/tests/JACINTO_SYSFW_TestExecutionResult.xlsx test_report/$SOC/syfw_testreport.xlsx
    done

    git add $PDK_DIR/docs/test_report/
    git commit -m "Update SYSFW version $RELEASE_TAG Test report"

    $RM -fr $SCI_CLIENT_DIR/soc/sysfw/reports
fi
################################################################################
# Build sciclient_ccs_init for use with launch.js
if [ "$SKIP_BUILD" != "YES" ]; then
    cd $ROOTDIR/ti/build

    for SOC in $SOC_LIST
    do
        make -j -s allclean
        make -j -s sciclient_boardcfg BOARD="$SOC"_evm
        make -j -s sciclient_boardcfg BOARD="$SOC"_evm BUILD_HS=yes
        make -j -s sciclient_ccs_init_clean BOARD="$SOC"_evm
        make -j -s sciclient_ccs_init BOARD="$SOC"_evm
        make -j -s sciserver_testapp_freertos_clean BOARD="$SOC"_evm
        make -j -s sciserver_testapp_freertos BOARD="$SOC"_evm
        $COPY $ROOTDIR/ti/binary/sciclient_ccs_init/bin/"$SOC"/sciclient_ccs_init_mcu1_0_release.xer5f $SCI_CLIENT_DIR/tools/ccsLoadDmsc/"$SOC"/
        $COPY $ROOTDIR/ti/binary/sciserver_testapp_freertos/bin/"$SOC"/sciserver_testapp_freertos_mcu1_0_release.xer5f $SCI_CLIENT_DIR/tools/ccsLoadDmsc/"$SOC"/
        $COPY $ROOTDIR/ti/binary/sciserver_testapp_freertos/bin/"$SOC"/sciserver_testapp_freertos_mcu1_0_release.rprc $SCI_CLIENT_DIR/tools/ccsLoadDmsc/"$SOC"/
        if [ $SOC=="j721e" ] || [ $SOC=="j7200" ] || [ $SOC=="j721s2" ] || [ $SOC=="j784s4" ]; then
            make -j -s sciserver_testapp_safertos_clean BOARD="$SOC"_evm
            make -j -s sciserver_testapp_safertos BOARD="$SOC"_evm
        fi

        if [ $SOC=="j7200" ] || [ $SOC=="j721s2" ] || [ $SOC=="j784s4" ]; then
            make -j -s sciclient_boardcfg_combined BOARD="$SOC"_evm
        fi
    done

    cd -
fi

################################################################################

if [ "$SKIP_GEN_BIN" != "YES" ];  then

    cd $ROOTDIR/ti/drv/sciclient/tools/

    for SOC in $SOC_LIST
    do
        case $SOC in
            "j721e")
                ./firmwareHeaderGen.sh j721e
                ./firmwareHeaderGen.sh j721e-hs
                ./firmwareHeaderGen.sh j721e_sr1_1-hs
                ./firmwareHeaderGen.sh j721e_sr2-hs
                ./firmwareHeaderGen.sh j721e_sr2-hs-fs
                shift
                ;;
            "j7200")
                ./firmwareHeaderGen.sh j7200
                ./firmwareHeaderGen.sh j7200-hs
                ./firmwareHeaderGen.sh j7200_sr2-hs
                ./firmwareHeaderGen.sh j7200_sr2-hs-fs
                shift
                ;;
            "j721s2")
                ./firmwareHeaderGen.sh j721s2
                ./firmwareHeaderGen.sh j721s2-hs
                ./firmwareHeaderGen.sh j721s2-hs-fs
                shift
                ;;
            "j784s4")
                ./firmwareHeaderGen.sh j784s4
                ./firmwareHeaderGen.sh j784s4-hs
                ./firmwareHeaderGen.sh j784s4-hs-fs
                shift
                ;;
        esac
    done

fi

################################################################################
# Commit changes to PDK
if [ "$SKIP_COMMIT" != "YES" ]; then
    $ECHO "Commit changes to PDK"
    cd $SCRIPT_DIR
    git add $SCI_CLIENT_DIR/soc/sysfw/binaries/system-firmware-public-documentation/
    git add $SCI_CLIENT_DIR/soc/sysfw/binaries/sysfw-trace*
    git add $SCI_CLIENT_DIR/soc/sysfw/include/tisci

    for SOC in $SOC_LIST
    do
        case $SOC in
            "j721e")
                git add $SCI_CLIENT_DIR/soc/sysfw/binaries/*j721e*
                git add $SCI_CLIENT_DIR/soc/sysfw/include/j721e
                git add $SCI_CLIENT_DIR/soc/V1
                git add $SCI_CLIENT_DIR/tools/ccsLoadDmsc/j721e
                shift
                ;;
            "j7200")
                git add $SCI_CLIENT_DIR/soc/sysfw/binaries/*j7200*
                git add $SCI_CLIENT_DIR/soc/sysfw/include/j7200
                git add $SCI_CLIENT_DIR/soc/V2
                git add $SCI_CLIENT_DIR/tools/ccsLoadDmsc/j7200
                shift
                ;;
            "j721s2")
                git add $SCI_CLIENT_DIR/soc/sysfw/binaries/*j721s2*
                git add $SCI_CLIENT_DIR/soc/sysfw/include/j721s2
                git add $SCI_CLIENT_DIR/soc/V4
                git add $SCI_CLIENT_DIR/tools/ccsLoadDmsc/j721s2
                shift
                ;;
            "j784s4")
                git add $SCI_CLIENT_DIR/soc/sysfw/binaries/*j784s4*
                git add $SCI_CLIENT_DIR/soc/sysfw/include/j784s4
                git add $SCI_CLIENT_DIR/soc/V6
                git add $SCI_CLIENT_DIR/tools/ccsLoadDmsc/j784s4
                shift
                ;;
        esac
    done

    git commit -s -m "Migrating to TIFS version $RELEASE_TAG"
fi


################################################################################
# Generate DM and IPC firmwares
if [ "$GEN_DM_IPC" == "YES" ]; then
    $ECHO "Generating DM and IPC firmwares"

    ipc_corelist_j721e_evm="mcu1_1 mcu2_0 mcu2_1 mcu3_0 mcu3_1 c66xdsp_1 c66xdsp_2 c7x_1"
    ipc_corelist_j7200_evm="mcu1_1 mcu2_0 mcu2_1"
    ipc_corelist_j721s2_evm="mcu1_1 mcu2_0 mcu2_1 mcu3_0 mcu3_1 c7x_1 c7x_2"
    ipc_corelist_j784s4_evm="mcu1_1 mcu2_0 mcu2_1 mcu3_0 mcu3_1 mcu4_0 mcu4_1 c7x_1 c7x_2 c7x_3 c7x_4"
    ipc_corelist_j742s2_evm="mcu1_1 mcu2_0 mcu2_1 mcu3_0 mcu3_1 mcu4_0 mcu4_1 c7x_1 c7x_2 c7x_3"

    cd $ROOTDIR/ti/build
    mkdir -p $ROOTDIR/ti/binary/firmware/{ti-dm,ti-sysfw,ti-ipc}

    DMF_DIR=$ROOTDIR/ti/binary/firmware/ti-dm
    SYSFWF_DIR=$ROOTDIR/ti/binary/firmware/ti-sysfw
    IPCF_DIR=$ROOTDIR/ti/binary/firmware/ti-ipc

    cp $SCI_CLIENT_DIR/soc/sysfw/binaries/ti-fs*j7*gp.bin   ${SYSFWF_DIR}/
    cp $SCI_CLIENT_DIR/soc/sysfw/binaries/ti-fs*j7*cert.bin ${SYSFWF_DIR}/
    cp $SCI_CLIENT_DIR/soc/sysfw/binaries/ti-fs*j7*enc.bin  ${SYSFWF_DIR}/

    for SOC in $SOC_LIST
    do
        mkdir -p ${DMF_DIR}/${SOC}
        mkdir -p ${IPCF_DIR}/${SOC}

        make ipc_echo_testb_freertos -sj8 CORE=mcu1_0 BOARD=${SOC}_evm;
        cp $ROOTDIR/ti/binary/ipc_echo_testb_freertos/bin/${SOC}_evm/ipc_echo_testb_freertos_mcu1_0_release_strip.xer5f  \
            ${DMF_DIR}/${SOC}/ipc_echo_testb_mcu1_0_release_strip.xer5f

        corelist="ipc_corelist_${SOC}_evm"
        for core in ${!corelist}
        do
            case ${core} in
                mcu*)
                    ext=xer5f
                    shift
                    ;;
                c66x*)
                    ext=xe66
                    shift
                    ;;
                c7x*)
                    ext=xe71
                    shift
                    ;;
            esac
            make ipc_echo_test_freertos -sj8 CORE=${core} BOARD=${SOC}_evm;
            cp $ROOTDIR/ti/binary/ipc_echo_test_freertos/bin/${SOC}_evm/ipc_echo_test_freertos_${core}_release_strip.${ext}  \
            ${IPCF_DIR}/${SOC}/ipc_echo_test_${core}_release_strip.${ext}
        done
    done
    #There is only one common tifs.bin for all gp device for a device. Remove other tifs.bin for gp devices.
    cd $SYSFWF_DIR
    rm -rf ti-fs*j7*sr*gp.bin
    #Copy j784s4 hs-fs tifs as j742s2 hs-fs for ti-linux-firmware
    cp ti-fs-firmware-j784s4-hs-fs-enc.bin ti-fs-firmware-j742s2-hs-fs-enc.bin
    cp ti-fs-firmware-j784s4-hs-fs-cert.bin ti-fs-firmware-j742s2-hs-fs-cert.bin
fi

################################################################################
# Generate DM and IPC firmwares
if [ "$GEN_LPR_PATCH" == "YES" ]; then
    $ECHO "Generating LPR Patch"

    DMF_DIR=$ROOTDIR/ti/binary/firmware/ti-dm
    SYSFWF_DIR=$ROOTDIR/ti/binary/firmware/ti-sysfw
    IPCF_DIR=$ROOTDIR/ti/binary/firmware/ti-ipc

    cd $ROOTDIR/ti/binary/firmware/

    echo "" >> sysfw_commit_msg.txt
    echo "Update the System Firmware binaries to $RELEASE_TAG for Jacinto devices. " >> sysfw_commit_msg.txt
    echo "" >> sysfw_commit_msg.txt
    echo " < Add release highlights here >" >> sysfw_commit_msg.txt
    echo "" >> sysfw_commit_msg.txt
    echo "MD5 Checksums: " >> sysfw_commit_msg.txt

    for files in ti-sysfw/*;
    do
        md5sum $files >> sysfw_commit_msg.txt
    done

    echo "" >> dm_commit_msg.txt
    echo "Update the ti-dm firmware to $RELEASE_TAG for Jacinto devices. " >> dm_commit_msg.txt
    echo "" >> dm_commit_msg.txt
    echo "These were generated using SYSFW $RELEASE_TAG" >> dm_commit_msg.txt
    echo "" >> dm_commit_msg.txt
    echo " < Add release highlights here >" >> dm_commit_msg.txt
    echo "" >> dm_commit_msg.txt
    echo "MD5 Checksums: " >> dm_commit_msg.txt

    for files in ti-dm/*/*;
    do
        md5sum $files >> dm_commit_msg.txt
    done

    echo "" >> ipc_commit_msg.txt
    echo "Update the ti-ipc firmware to $RELEASE_TAG for Jacinto devices. " >> ipc_commit_msg.txt
    echo "" >> ipc_commit_msg.txt
    echo " < Add IPC release highlights here >" >> ipc_commit_msg.txt
    echo "" >> ipc_commit_msg.txt
    echo "MD5 Checksums: " >> ipc_commit_msg.txt

    for files in ti-ipc/*/*;
    do
        md5sum $files >> ipc_commit_msg.txt
    done

fi
################################################################################
$ECHO "Done."
