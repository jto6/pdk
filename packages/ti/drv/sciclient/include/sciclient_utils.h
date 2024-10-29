/*
 *  Copyright (C) 2024 Texas Instruments Incorporated
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *
 *    Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 *    Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the
 *    distribution.
 *
 *    Neither the name of Texas Instruments Incorporated nor the names of
 *    its contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 *  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 *  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 *  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 *  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 *  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 *  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 *  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 *  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */
/**
 *  \file  sciclient_utils.h
 *
 *  \brief This file contains the definitions of the helper functions to the 
 *         critical section code in Sciclient_serviceSecureProxy().
 *
 */

#ifndef SCICLIENT_UTILS_H_
#define SCICLIENT_UTILS_H_

/* ========================================================================== */
/*                             Include Files                                  */
/* ========================================================================== */

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ========================================================================== */
/*                           Macros & Typedefs                                */
/* ========================================================================== */

/* None */

/* ========================================================================== */
/*                         Structure Declarations                             */
/* ========================================================================== */

/* None */

/* ========================================================================== */
/*                          Function Declarations                             */
/* ========================================================================== */

/**
 *  \brief  Sciclient_criticalSectionStart Locks the resource.
 *
 *  \param key                             [IN]  Return value from HwiP_disable
 *  \param timeout                         [IN]  Timeout for receiving response
 *  \param gSciclient_writeInProgress      [OUT] Variable to control the access to critical section
 *
 *  \return CSL_PASS on success, else failure
 *
 */
uint32_t Sciclient_criticalSectionStart(uintptr_t key,
                                        uint32_t timeout, 
                                        uint32_t* gSciclient_writeInProgress);

/**
 *  \brief  Sciclient_criticalSectionEnd Releases the resource.
 *
 *  \param key                           [IN]  Return value from HwiP_disable
 *  \param gSciclient_writeInProgress    [OUT] Variable to control the access to critical section
 *
 *  \return CSL_PASS on success, else failure
 *
 */
void Sciclient_criticalSectionEnd(uintptr_t key, 
                                  uint32_t* gSciclient_writeInProgress);

#ifdef __cplusplus
}
#endif

#endif /* #ifndef SCICLIENT_UTILS_H_ */

/* @} */
