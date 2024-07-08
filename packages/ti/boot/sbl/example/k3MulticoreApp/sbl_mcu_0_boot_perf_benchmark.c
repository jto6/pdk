/*
 * Copyright (c) 2018, Texas Instruments Incorporated
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * *  Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * *  Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * *  Neither the name of Texas Instruments Incorporated nor the names of
 *    its contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <ti/board/board.h>
#include <ti/csl/arch/csl_arch.h>
#include <ti/drv/uart/UART_stdio.h>
#include <ti/csl/arch/r5/csl_arm_r5.h>

#include "sbl_boot_perf_benchmark.h"
#include <string.h>

/**********************************************************************
 ************************** Global Variables **************************
 **********************************************************************/
struct tisci_boardcfg sblPerfTestBoardCfg __attribute((section(".sysfw_data_cfg_board")));
struct sblTest_local_rm_boardcfg sblPerfTestBoardCfg_rm __attribute((section(".sysfw_data_cfg_board_rm")));
struct tisci_boardcfg_sec sblPerfTestBoardCfg_sec __attribute((section(".sysfw_data_cfg_board_sec")));

/* For j721e SBL doesn't able to profile RBL boot time since it doesn't have mcu timer9 
        So SBL profile info for j721e is one index ahead of others */
#if !defined(SOC_J721E)
    #define SBL_BOOT_PERF_ARRAY_LENGTH 18
    #define SBL_BOOT_PERF_ARRAY_SKIP_INDX 7
    /* This time includes RBL execution time */
    float expCanRespTime = 48;
#else
    #define SBL_BOOT_PERF_ARRAY_LENGTH 17
    #define SBL_BOOT_PERF_ARRAY_SKIP_INDX 6
    /* This time does not include RBL execution time */
    float expCanRespTime = 39.5;
#endif

/**********************************************************************
 ************************** Internal functions ************************
 **********************************************************************/
static void  BOOT_PERF_TEST_CacheCleanInvalidateDcacheSetWay (void)
{
    uint32_t set = 0, way = 0;
    uint32_t numSets = CSL_armR5CacheGetNumSets();
    uint32_t numWays = CSL_armR5CacheGetNumWays();

    for (set = 0; set < numSets; set ++)
    {
        for (way = 0; way < numWays; way++)
        {
            CSL_armR5CacheCleanInvalidateDcacheSetWay(set, way);
        }
    }
}

static void BOOT_PERF_TEST_SYSFW_UartLogEnable(void)
{
    uint32_t WkupUart0TxDPinCfg =
        (0 << SBL_SYSFW_UART_PADCONFIG_PULLUDEN_SHIFT)    | \
        (1 << SBL_SYSFW_UART_PADCONFIG_PULLTYPESEL_SHIFT) | \
        (0 << SBL_SYSFW_UART_PADCONFIG_RXACTIVE_SHIFT)    | \
        (0 << SBL_SYSFW_UART_PADCONFIG_TX_DIS_SHIFT)      | \
        (0 << SBL_SYSFW_UART_PADCONFIG_MUXMODE_SHIFT);

    HW_WR_REG32(SBL_SYSFW_UART_PADCONFIG_ADDR, (WkupUart0TxDPinCfg));
}

static void BOOT_PERF_TEST_printSblProfileLog(sblProfileInfo_t *sblProfileLog, uint32_t sblProfileLogIndx, uint32_t sblProfileLogOvrFlw)
{
    uint64_t mcu_clk_freq = SBL_MCU1_CPU0_FREQ_HZ;
    uint32_t i = 0, prev_cycle_cnt = 0, cycles_per_usec;
    uint32_t lastlogIndx;
    char sbl_test_str[256];

    Sciclient_pmGetModuleClkFreq(SBL_DEV_ID_MCU1_CPU0, SBL_CLK_ID_MCU1_CPU0, &mcu_clk_freq, SCICLIENT_SERVICE_WAIT_FOREVER);
    cycles_per_usec = (mcu_clk_freq / 1000000);

    sbl_puts("\r\nProfiling info ....\r\n");
    sprintf(sbl_test_str,"MCU @ %uHz.\r\n", ((uint32_t)mcu_clk_freq));sbl_puts(sbl_test_str);
    sprintf(sbl_test_str,"cycles per usec  = %u\r\n", cycles_per_usec);sbl_puts(sbl_test_str);

    lastlogIndx = sblProfileLogIndx;

    if (sblProfileLogOvrFlw)
    {
        i = sblProfileLogIndx;
        prev_cycle_cnt = sblProfileLog[i].cycle_cnt;
        lastlogIndx = MAX_PROFILE_LOG_ENTRIES;
        sbl_puts("Detected overflow, some profile entries might be lost.\r\n");
        sbl_puts("Rebuild with a larger vlaue of MAX_PROFILE_LOG_ENTRIES ??\r\n");
    }

    while((i % MAX_PROFILE_LOG_ENTRIES) < lastlogIndx)
    {
        uint32_t cycles_to_us;

        if (sblProfileLog[i].cycle_cnt < prev_cycle_cnt)
        {
            sbl_puts("**");
        }
        else
        {
            sbl_puts("  ");
        }
        cycles_to_us = sblProfileLog[i].cycle_cnt/cycles_per_usec;
        sprintf(sbl_test_str,"fxn:%32s\t", sblProfileLog[i].fxn);sbl_puts(sbl_test_str);
        sprintf(sbl_test_str,"line:%4u\t", sblProfileLog[i].line);sbl_puts(sbl_test_str);
        sprintf(sbl_test_str,"cycle:%10u\t", sblProfileLog[i].cycle_cnt);sbl_puts(sbl_test_str);
        sprintf(sbl_test_str,"timestamp:%10uus\r\n", cycles_to_us);sbl_puts(sbl_test_str);
        prev_cycle_cnt = sblProfileLog[i].cycle_cnt;
        i++;
    }
}

static void sblBootPerfPrint(sblProfileInfo_t *sblBootPerfLog)
{
    char majorApis[14][100] = {"SBL : SBL_SciClientInit: ReadSysfwImage                 :", \
                                "Load/Start SYSFW                                        :", \
                                "Sciclient_init                                          :", \
                                "Board Config                                            :", \
                                "PM Config                                               :", \
                                "Security Config                                         :", \
                                "RM Config                                               :", \
                                "SBL: Board_init (pinmux)                                :", \
                                "SBL: Board_init (PLL)                                   :", \
                                "SBL: Board_init (CLOCKS)                                :", \
                                "SBL: OSPI init                                          :", \
                                "OSPI PHY tuning time                                    :", \
                                "SBL: Parsing appimage and copy to MCU SRAM & Jump to App:", \
                                "Misc                                                    :"};
    uint64_t mcu_clk_freq = SBL_MCU1_CPU0_FREQ_HZ;
    uint32_t majorApisIndx = 0, cycles_per_usec;

    /* For j721e SBL doesn't able to profile RBL boot time since it doesn't have mcu timer9 
        So SBL profile info for j721e is one index ahead of others */
    #if !defined(SOC_J721E)
        uint32_t indx = 3;
    #else
        uint32_t indx = 2;
    #endif

    float convertMicroToMilli = 1000;
    float totalTime = 0;
    char sbl_test_str[256];

    Sciclient_pmGetModuleClkFreq(SBL_DEV_ID_MCU1_CPU0, SBL_CLK_ID_MCU1_CPU0, &mcu_clk_freq, SCICLIENT_SERVICE_WAIT_FOREVER);
    cycles_per_usec = (mcu_clk_freq / 1000000);

    sbl_puts("\r\n NOTE : Below numbers will be corrupted if SBL_ADD_PROFILE_POINT is added anywhere \n");
    sbl_puts("\r\n           ------- SBL Boot Performance Info overview -------  \r\n\n");
    #if !defined(SOC_J721E)
        float convertToMilli = 250000;
        float rblExecutionTime = (float)sblBootPerfLog[0].line;
        sprintf(sbl_test_str, "RBL Execution time                                      : %.3fms \r\n", rblExecutionTime/convertToMilli);
        sbl_puts(sbl_test_str);
        totalTime += rblExecutionTime/convertToMilli;
    #endif

    while(indx < SBL_BOOT_PERF_ARRAY_LENGTH)
    {
        /* Skipping this index as timer is being reset at this particular index */ 
        if(indx == SBL_BOOT_PERF_ARRAY_SKIP_INDX){
            indx++;
            continue;
        }
        uint32_t currentCycleCount;
        uint32_t previousCycleCount;
        float timeTaken;
        
        currentCycleCount = sblBootPerfLog[indx].cycle_cnt/cycles_per_usec;
        previousCycleCount = sblBootPerfLog[indx-1].cycle_cnt/cycles_per_usec;
        timeTaken = (currentCycleCount-previousCycleCount)/convertMicroToMilli;
        /* For Misc - add the time after copying appimage to MCU SRAM till core 
        boots and from start of SBL main to before reading sysfw */
        if(indx == (SBL_BOOT_PERF_ARRAY_LENGTH-1))
        {
            #if !defined(SOC_J721E)
                timeTaken += (sblBootPerfLog[2].cycle_cnt/cycles_per_usec - sblBootPerfLog[1].cycle_cnt/cycles_per_usec)/convertMicroToMilli;
            #else
                timeTaken += (sblBootPerfLog[1].cycle_cnt/cycles_per_usec - sblBootPerfLog[0].cycle_cnt/cycles_per_usec)/convertMicroToMilli;
            #endif
        }
        totalTime += timeTaken;
        sprintf(sbl_test_str,"%s %.3fms\r\n", majorApis[majorApisIndx], timeTaken);
        sbl_puts(sbl_test_str);
        indx++;
        majorApisIndx++;
    }
    
    sprintf(sbl_test_str, "Time taken to boot CAN application from SBL main : %.3fms \r\n", totalTime);
    sbl_puts(sbl_test_str);
    if(totalTime < expCanRespTime)
    {
        sprintf(sbl_test_str, "Boot Performance test has passed");
        sbl_puts(sbl_test_str);
    }
    else
    {
        sprintf(sbl_test_str, "Boot Performance test has failed");
        sbl_puts(sbl_test_str);
    }

}

static void sblCombinedBootPerfPrint(sblProfileInfo_t *sblBootPerfLog)
{
    char majorApis[14][100] = {"Sciclient Boot Notification                             :", \
                                "Sciclient_init                                          :", \
                                "Board Config                                            :", \
                                "PM Config                                               :", \
                                "Security Config                                         :", \
                                "RM Config                                               :", \
                                "SBL: Board_init (pinmux)                                :", \
                                "SBL: Board_init (PLL)                                   :", \
                                "SBL: Board_init (CLOCKS)                                :", \
                                "SBL: OSPI init                                          :", \
                                "OSPI PHY tuning time                                    :", \
                                "SBL: Parsing appimage and copy to MCU SRAM & Jump to App:", \
                                "Misc                                                    :"};
    uint64_t mcuClkFreq = SBL_MCU1_CPU0_FREQ_HZ;
    uint32_t majorApisIndx = 0, cyclesPerUsec;
    uint32_t indx = 3;
    uint32_t arrayLen = 16;
    uint32_t skipIndex = 6;

    float convertMicroToMilli = 1000;
    float totalTime = 0;
    char sbl_test_str[256];

    Sciclient_pmGetModuleClkFreq(SBL_DEV_ID_MCU1_CPU0, SBL_CLK_ID_MCU1_CPU0, &mcuClkFreq, SCICLIENT_SERVICE_WAIT_FOREVER);
    cyclesPerUsec = (mcuClkFreq / 1000000);

    sbl_puts("\r\n NOTE : Below numbers will be corrupted if SBL_ADD_PROFILE_POINT is added anywhere \n");
    sbl_puts("\r\n           ------- SBL Combined Boot Performance Info overview -------  \r\n\n");
    float convertToMilli = 250000;
    float rblExecutionTime = (float)sblBootPerfLog[0].line;
    sprintf(sbl_test_str, "RBL Execution time                                      : %.3fms \r\n", rblExecutionTime/convertToMilli);
    sbl_puts(sbl_test_str);
    totalTime += rblExecutionTime/convertToMilli;

    while(indx < arrayLen)
    {
        /* Skipping this index as timer is being reset at this particular index */ 
        if(indx == skipIndex){
            indx++;
            continue;
        }
        uint32_t currentCycleCount;
        uint32_t previousCycleCount;
        float timeTaken;
        
        currentCycleCount = sblBootPerfLog[indx].cycle_cnt/cyclesPerUsec;
        previousCycleCount = sblBootPerfLog[indx-1].cycle_cnt/cyclesPerUsec;
        timeTaken = (currentCycleCount-previousCycleCount)/convertMicroToMilli;
        totalTime += timeTaken;
        /* For Misc - add the time after copying appimage to MCU SRAM till core 
        boots and from start of SBL main to before reading sysfw */
        if(indx == (arrayLen-1))
        {
            timeTaken += (sblBootPerfLog[2].cycle_cnt/cyclesPerUsec - sblBootPerfLog[1].cycle_cnt/cyclesPerUsec)/convertMicroToMilli;
        }
        sprintf(sbl_test_str,"%s %.3fms\r\n", majorApis[majorApisIndx], timeTaken);
        sbl_puts(sbl_test_str);
        indx++;
        majorApisIndx++;
    }
    
    sprintf(sbl_test_str, "Approximated time to come to main of an application : %.3fms \r\n", totalTime);
    sbl_puts(sbl_test_str);
    if(totalTime < expCanRespTime)
    {
        sbl_puts("All tests have passed\r\n");
        sprintf(sbl_test_str, "Boot Performance test has passed");
        sbl_puts(sbl_test_str);
    }
    else
    {
        sprintf(sbl_test_str, "Boot Performance test has failed");
        sbl_puts(sbl_test_str);
    }

}

static int32_t BOOT_PERF_TEST_sysfwInit(void)
{
    int32_t status = CSL_PASS;
    			   
    Sciclient_DefaultBoardCfgInfo_t boardCfgInfo;

    Sciclient_BoardCfgPrms_t sblPerfTestBoardCfgPrms;
    Sciclient_BoardCfgPrms_t sblPerfTestBoardCfgPmPrms =
    {
        .boardConfigLow = (uint32_t)NULL,
        .boardConfigHigh = 0U,
        .boardConfigSize = 0,
        .devGrp = DEVGRP_01
    };
    Sciclient_BoardCfgPrms_t sblPerfTestBoardCfgRmPrms;
    Sciclient_BoardCfgPrms_t sblPerfTestBoardCfgSecPrms;

    BOOT_PERF_TEST_CacheCleanInvalidateDcacheSetWay();

    BOOT_PERF_TEST_SYSFW_UartLogEnable();

    status = Sciclient_getDefaultBoardCfgInfo(&boardCfgInfo);
    if (status != CSL_PASS)
    {
        return CSL_EFAIL;
    }

    sblPerfTestBoardCfgPrms.boardConfigLow = (uint32_t)&sblPerfTestBoardCfg;
    sblPerfTestBoardCfgPrms.boardConfigHigh = 0U;
    sblPerfTestBoardCfgPrms.boardConfigSize = boardCfgInfo.boardCfgLowSize;
    sblPerfTestBoardCfgPrms.devGrp = DEVGRP_01;
    memcpy((void *)&sblPerfTestBoardCfg,
        (const void *)boardCfgInfo.boardCfgLow,
        sblPerfTestBoardCfgPrms.boardConfigSize);

    /* Redirect DMSC logs to UART 0 */
    sblPerfTestBoardCfg.debug_cfg.trace_dst_enables = TISCI_BOARDCFG_TRACE_DST_UART0;
    /* Enable full logs */
    sblPerfTestBoardCfg.debug_cfg.trace_src_enables = TISCI_BOARDCFG_TRACE_SRC_PM   |
                                                      TISCI_BOARDCFG_TRACE_SRC_RM   |
                                                      TISCI_BOARDCFG_TRACE_SRC_SEC  |
                                                      TISCI_BOARDCFG_TRACE_SRC_BASE |
                                                      TISCI_BOARDCFG_TRACE_SRC_USER |
                                                      TISCI_BOARDCFG_TRACE_SRC_SUPR ;
    BOOT_PERF_TEST_CacheCleanInvalidateDcacheSetWay();

    status = Sciclient_boardCfg(&sblPerfTestBoardCfgPrms);
    if (status != CSL_PASS)
    {
        return CSL_EFAIL;
    }

    status = Sciclient_boardCfgPm(&sblPerfTestBoardCfgPmPrms);
    if (status != CSL_PASS)
    {
        return CSL_EFAIL;
    }

    sblPerfTestBoardCfgRmPrms.boardConfigLow = (uint32_t)&sblPerfTestBoardCfg_rm;
    sblPerfTestBoardCfgRmPrms.boardConfigHigh = 0U;
    sblPerfTestBoardCfgRmPrms.boardConfigSize = boardCfgInfo.boardCfgLowRmSize;
    sblPerfTestBoardCfgRmPrms.devGrp = DEVGRP_01;
    memcpy((void *)&sblPerfTestBoardCfg_rm,
        (const void *)boardCfgInfo.boardCfgLowRm,
        sblPerfTestBoardCfgRmPrms.boardConfigSize);

    BOOT_PERF_TEST_CacheCleanInvalidateDcacheSetWay();
    status = Sciclient_boardCfgRm(&sblPerfTestBoardCfgRmPrms);
    if (status != CSL_PASS)
    {
        return CSL_EFAIL;
    }

    if (SBL_LOG_LEVEL == SBL_LOG_NONE)
    {
        Board_init(BOARD_INIT_UART_STDIO);
    }

    sblPerfTestBoardCfgSecPrms.boardConfigLow = (uint32_t)&sblPerfTestBoardCfg_sec;
    sblPerfTestBoardCfgSecPrms.boardConfigHigh = 0U;
    sblPerfTestBoardCfgSecPrms.boardConfigSize = boardCfgInfo.boardCfgLowSecSize;
    sblPerfTestBoardCfgSecPrms.devGrp = DEVGRP_01;
    memcpy((void *)&sblPerfTestBoardCfg_sec,
        (const void *)boardCfgInfo.boardCfgLowSec,
        sblPerfTestBoardCfgSecPrms.boardConfigSize);

    BOOT_PERF_TEST_CacheCleanInvalidateDcacheSetWay();
    status = Sciclient_boardCfgSec(&sblPerfTestBoardCfgSecPrms);
    if (status != CSL_PASS)
    {
        return CSL_EFAIL;
    }

    return status;
}

int32_t main()
{
    volatile uint32_t pmuCntrVal = CSL_armR5PmuReadCntr(0x1F);
    char sbl_test_str[256];
    uint64_t mcu_clk_freq = SBL_MCU1_CPU0_FREQ_HZ;
    uint32_t cycles_per_usec;
    char *comp_mk = "sbl_component.mk";

    /* Perform the sysfw init here that was skipped */
    /* by the SBL to speed up boot times            */
    BOOT_PERF_TEST_sysfwInit();

    sbl_puts("\r\n");
    sprintf(sbl_test_str, "Time elapsed since start of SBL:");sbl_puts(sbl_test_str);
    cycles_per_usec = ((uint32_t)mcu_clk_freq) / 1000000;
    sprintf(sbl_test_str, "%10uus\r\n", pmuCntrVal/cycles_per_usec);sbl_puts(sbl_test_str);

    sprintf(sbl_test_str, "fxn:%16s\t", "boot_perf_test_main");sbl_puts(sbl_test_str);
    sprintf(sbl_test_str, "cycles:%10u\t\r\n", pmuCntrVal);sbl_puts(sbl_test_str);
    sbl_puts("\r\n");

    sbl_puts("Attempting board config ...");

    /* Only MCU PLLs were enabled in SBL, enable Main Domain */
    sbl_puts("BOARD_INIT_PLL_MAIN ...");
    Board_init(BOARD_INIT_PLL_MAIN);
    sbl_puts("passed\r\n");

    /* Only MCU PLLs were enabled in SBL, enable Main Domain */
    sbl_puts("BOARD_INIT_MODULE_CLOCK_MAIN...");
    Board_init(BOARD_INIT_MODULE_CLOCK_MAIN);
    sbl_puts("passed\r\n");

    sbl_puts("BOARD_INIT_DDR...");
    Board_init(BOARD_INIT_DDR);
    sbl_puts("passed\r\n");

    sbl_puts("\r\nAnalyzing run results .... \r\n");

    if (pmuCntrVal == 0)
    {
        sprintf(sbl_test_str,"Do this first: Enable SBL_SKIP_MCU_RESET and set SBL_LOG_LEVEL=1 in %s.\r\n", comp_mk);sbl_puts(sbl_test_str);
        sbl_puts("If the regular mpu_init is good for you, then save some time by skipping/configuring only delta in mpu_init in the app.\r\n");
        sbl_puts("Refer sbl_smp_r5.asm to see how to overrride the default mpu_init with a custom one.\r\n");
        return 0;
    }
    else
    {
        if (pmuCntrVal > 50000000)
        {
            sprintf(sbl_test_str,"Do this next: Disable SBL_DISPLAY_PROFILE_INFO in %s to drastically reduce boot time.\r\n", comp_mk);sbl_puts(sbl_test_str);
            sbl_puts("Also recheck SBL_LOG_LEVEL=1 and no log messages are displayed form the SBL\r\n");
        }
        else
        {
            if (pmuCntrVal < 20000000)
            {
                sbl_puts("Boot time is now optimized....\r\n");
            }
            else
            {
                sprintf(sbl_test_str,"Now Try disabling the following one by one in %s to reduce a little more boot time.\r\n", comp_mk);sbl_puts(sbl_test_str);
                sbl_puts("SBL_ENABLE_PLL (big impact to boot time), SBL_ENABLE_DDR (must be disabled if SBL_ENABLE_PLL is disable), SBL_ENABLE_CLOCKS(least imapct).\r\n");
                sbl_puts("Please remember to assess impact of removing PLL init, DDR init (does your app need DDR?) and clock init (does your app use PHYs\?\?) on your app. \r\n");
                sbl_puts("As a last resort, enable (uncomment) SBL_SKIP_BRD_CFG_PM\r\n");
                sbl_puts("Once enabled, all SBL UART logs will be garbled. Remember to call Sciclient_boardCfgPm from the app to get Uart_printf to work.\r\n");
            }
        }
    }

    BOOT_PERF_TEST_printSblProfileLog(sblProfileLogAddr, *sblProfileLogIndxAddr, *sblProfileLogOvrFlwAddr);
#if defined(COMBINED_BOOT_PERF)
    sblCombinedBootPerfPrint(sblProfileLogAddr);
#else
    sblBootPerfPrint(sblProfileLogAddr);
#endif
    return 0;
}
