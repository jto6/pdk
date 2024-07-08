/*
 * Copyright (C) 2024 Texas Instruments Incorporated - http://www.ti.com/
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the
 * distribution.
 *
 * Neither the name of Texas Instruments Incorporated nor the names of
 * its contributors may be used to endorse or promote products derived
 * from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

/**
 *  \file   osal_extended_testapp_registerinterrupt.c
 *
 *  \brief  OSAL Register Interrupt Sub Module testcases file.
 *
 */

/* ========================================================================== */
/*                             Include Files                                  */
/* ========================================================================== */

#include "osal_extended_test.h"

/* ========================================================================== */
/*                           Macros & Typedefs                                */
/* ========================================================================== */


/* ========================================================================== */
/*                            Global Variables                                */
/* ========================================================================== */

volatile bool gOsalAppRegISRisExecuted = BFALSE;

/* ========================================================================== */
/*                           Function Declarations                            */
/* ========================================================================== */

/*
 * Description : Register interrupt Callback Function
 */
static void OsalApp_regIntrISR(void *arg);

#if defined(BUILD_MCU)
/*
 * Description : Testing Null check for Register Interrupt APIs
 */
static int32_t OsalApp_regIntrNullTest(void);

/*
 * Description : Testing positive cases for Register Interrupt APIs
 */
static int32_t OsalApp_regIntrPositiveTest(void);

#elif defined(BUILD_C7X)
/*
 * Description : Testing Negative cases for Register Interrupt APIs
 */
static int32_t OsalApp_regIntrNegativeTest(void);
#endif
/* ========================================================================== */
/*                       Internal Function Definitions                        */
/* ========================================================================== */

static void OsalApp_regIntrISR(void *arg)
{
    gOsalAppRegISRisExecuted = BTRUE;
}

#if defined(BUILD_MCU)

static int32_t OsalApp_regIntrNullTest(void)
{
    OsalRegisterIntrParams_t    *intrPrms = NULL_PTR;
    HwiP_Handle                 hwiPHandlePtr, hwiPDirectHandlePtr;
    int32_t                     result = osal_OK;

    Osal_RegisterInterrupt_initParams(intrPrms);

    intrPrms->corepacConfig.isrRoutine      = NULL_PTR;
    intrPrms->corepacConfig.corepacEventNum = CSL_INVALID_EVENT_ID;

    if(OSAL_INT_SUCCESS == Osal_RegisterInterrupt(intrPrms, &hwiPHandlePtr))
    {
        result = osal_FAILURE;
    }
    if((osal_OK != result) || (OSAL_INT_SUCCESS == Osal_RegisterInterruptDirect(intrPrms, NULL_PTR, &hwiPDirectHandlePtr)))
    {
        result = osal_FAILURE;
    }
    if((osal_OK == result) || (NULL_PTR != hwiPHandlePtr))
    {
        if(OSAL_INT_SUCCESS != Osal_DeleteInterrupt(hwiPHandlePtr,intrPrms->corepacConfig.corepacEventNum))
        {
            result = osal_FAILURE;
        }
        if(OSAL_INT_SUCCESS != Osal_DeleteInterrupt(hwiPDirectHandlePtr,intrPrms->corepacConfig.corepacEventNum))
        {
            result = osal_FAILURE;
        }
        if(OSAL_INT_SUCCESS == Osal_DeleteInterrupt(NULL_PTR,intrPrms->corepacConfig.corepacEventNum))
        {
            result = osal_FAILURE;
        }
    }

    if(osal_OK != result)
    {
        OSAL_log("\n Register Interrupt Null check Test Failed!! \n");
    }

    return result;
}

static int32_t OsalApp_regIntrPositiveTest(void)
{
    OsalRegisterIntrParams_t    *intrPrms = NULL_PTR;
    HwiP_Handle                 hwiPHandlePtr, hwiPDirectHandlePtr;
    int32_t                     result = osal_OK;

    Osal_RegisterInterrupt_initParams(intrPrms);

    intrPrms->corepacConfig.isrRoutine      = (Osal_IsrRoutine)OsalApp_regIntrISR;
    intrPrms->corepacConfig.corepacEventNum = EventP_ID_00;

    if(OSAL_INT_SUCCESS != Osal_RegisterInterrupt(intrPrms, &hwiPHandlePtr))
    {
        result = osal_FAILURE;
    }
    if(OSAL_INT_SUCCESS != Osal_RegisterInterruptDirect(intrPrms, (HwiP_DirectFxn)OsalApp_regIntrISR, &hwiPDirectHandlePtr))
    {
        result = osal_FAILURE;
    }
    if(osal_OK == result)
    {
        if(OSAL_INT_SUCCESS != Osal_DeleteInterrupt(hwiPHandlePtr,intrPrms->corepacConfig.corepacEventNum))
        {
            result = osal_FAILURE;
        }
        if(OSAL_INT_SUCCESS != Osal_DeleteInterrupt(hwiPDirectHandlePtr,intrPrms->corepacConfig.corepacEventNum))
        {
            result = osal_FAILURE;
        }
    }

    if(osal_OK != result)
    {
        OSAL_log("\n Register Interrupt positive Testcase Failed!! \n");
    }

    return result;
}

#elif defined(BUILD_C7X)

static int32_t OsalApp_regIntrNegativeTest(void)
{
    OsalRegisterIntrParams_t    *intrPrms = NULL_PTR;
    HwiP_Handle                 hwiPHandlePtr, hwiPDirectHandlePtr;
    int32_t                     result = osal_OK;

    Osal_RegisterInterrupt_initParams(intrPrms);

    intrPrms->corepacConfig.isrRoutine      = NULL_PTR;
    intrPrms->corepacConfig.corepacEventNum = 1U;
    intrPrms->corepacConfig.intVecNum       = 64U;
    intrPrms->corepacConfig.priority        = 0U;
    intrPrms->corepacConfig.enableIntr      = 0U;

    if(OSAL_INT_SUCCESS == Osal_RegisterInterrupt(intrPrms, &hwiPHandlePtr))
    {
        result = osal_FAILURE;
    }
    if(OSAL_INT_SUCCESS == Osal_RegisterInterruptDirect(intrPrms, (HwiP_DirectFxn)OsalApp_regIntrISR, &hwiPDirectHandlePtr))
    {
        result = osal_FAILURE;
    }
    if(osal_OK == result)
    {
        if(NULL_PTR != hwiPHandlePtr)
        {
            if(OSAL_INT_SUCCESS != Osal_DeleteInterrupt(hwiPHandlePtr,intrPrms->corepacConfig.corepacEventNum))
            {
                result = osal_FAILURE;
            }
        }
        if(NULL_PTR != hwiPDirectHandlePtr)
        {
            if(OSAL_INT_SUCCESS != Osal_DeleteInterrupt(hwiPDirectHandlePtr,intrPrms->corepacConfig.corepacEventNum))
            {
                result = osal_FAILURE;
            }
        }
    }

    if(osal_OK != result)
    {
        OSAL_log("\n Register Interrupt Negative check Test Failed!! \n");
    }

    return result;
}

#endif

/* ========================================================================== */
/*                          Function Definitions                              */
/* ========================================================================== */

int32_t OsalApp_registerIntrTests(void)
{
    int32_t result = osal_OK;
#if defined(BUILD_MCU)
    result += OsalApp_regIntrNullTest();
    result += OsalApp_regIntrPositiveTest();
#elif defined(BUILD_C7X)
    result += OsalApp_regIntrNegativeTest();
#endif
    if(osal_OK == result)
    {
        OSAL_log("\n All Register Interrupt tests have passed!!\n");
    }
    else
    {
        OSAL_log("\n All or some Register Interrupt tests have failed!!\n");
    }

    return result;
}

