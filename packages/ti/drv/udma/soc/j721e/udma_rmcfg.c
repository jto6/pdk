/*
 *  Copyright (c) Texas Instruments Incorporated 2018-2022
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
 */

/**
 *  \file udma_rmcfg.c
 *
 *  \brief File containing the UDMA driver default RM configuration used to
 *  initialize the RM init parameters passed during driver init.
 *
 */

/* ========================================================================== */
/*                             Include Files                                  */
/* ========================================================================== */

#include <ti/drv/udma/src/udma_priv.h>

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

/* None */

/* ========================================================================== */
/*                            Global Variables                                */
/* ========================================================================== */

/** \brief Main Navss defaultBoardCfg Params */
const Udma_RmDefBoardCfgPrms gUdmaRmDefBoardCfg_MainNavss[UDMA_RM_DEFAULT_BOARDCFG_NUM_RES] =
{
    /* resId,                     reqType,                            reqSubtype,                               secHost */
    {UDMA_RM_RES_ID_TX_UHC,       TISCI_DEV_NAVSS0_UDMAP_0,            TISCI_RESASG_SUBTYPE_UDMAP_TX_UHCHAN,      TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST},
    {UDMA_RM_RES_ID_TX_HC,        TISCI_DEV_NAVSS0_UDMAP_0,            TISCI_RESASG_SUBTYPE_UDMAP_TX_HCHAN,       TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST},
    {UDMA_RM_RES_ID_TX,           TISCI_DEV_NAVSS0_UDMAP_0,            TISCI_RESASG_SUBTYPE_UDMAP_TX_CHAN,        TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST},
    {UDMA_RM_RES_ID_RX_UHC,       TISCI_DEV_NAVSS0_UDMAP_0,            TISCI_RESASG_SUBTYPE_UDMAP_RX_UHCHAN,      TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST},
    {UDMA_RM_RES_ID_RX_HC,        TISCI_DEV_NAVSS0_UDMAP_0,            TISCI_RESASG_SUBTYPE_UDMAP_RX_HCHAN,       TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST},
    {UDMA_RM_RES_ID_RX,           TISCI_DEV_NAVSS0_UDMAP_0,            TISCI_RESASG_SUBTYPE_UDMAP_RX_CHAN,        TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST},
    {UDMA_RM_RES_ID_UTC,          TISCI_DEV_NAVSS0_UDMAP_0,            TISCI_RESASG_SUBTYPE_UDMAP_TX_ECHAN,       TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST},
    {UDMA_RM_RES_ID_RX_FLOW,      TISCI_DEV_NAVSS0_UDMAP_0,            TISCI_RESASG_SUBTYPE_UDMAP_RX_FLOW_COMMON, TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST},
    {UDMA_RM_RES_ID_RING,         TISCI_DEV_NAVSS0_RINGACC_0,          TISCI_RESASG_SUBTYPE_RA_GP,                TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST},
#if defined (BUILD_MCU1_0) || defined (BUILD_MCU1_1) /* Tied to cores and not split based on NAVSS instance */
    {UDMA_RM_RES_ID_GLOBAL_EVENT, TISCI_DEV_MCU_NAVSS0_UDMASS_INTA_0, TISCI_RESASG_SUBTYPE_GLOBAL_EVENT_SEVT,    TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST},
    {UDMA_RM_RES_ID_VINTR,        TISCI_DEV_MCU_NAVSS0_UDMASS_INTA_0, TISCI_RESASG_SUBTYPE_IA_VINT,              TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST},
    {UDMA_RM_RES_ID_IR_INTR,      TISCI_DEV_MCU_NAVSS0_INTR_0,        TISCI_RESASG_SUBTYPE_IR_OUTPUT,            TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST},
#else
    {UDMA_RM_RES_ID_GLOBAL_EVENT, TISCI_DEV_NAVSS0_UDMASS_INTAGGR_0,  TISCI_RESASG_SUBTYPE_GLOBAL_EVENT_SEVT,    TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST},
    {UDMA_RM_RES_ID_VINTR,        TISCI_DEV_NAVSS0_UDMASS_INTAGGR_0,  TISCI_RESASG_SUBTYPE_IA_VINT,              TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST},
    {UDMA_RM_RES_ID_IR_INTR,      TISCI_DEV_NAVSS0_INTR_ROUTER_0,     TISCI_RESASG_SUBTYPE_IR_OUTPUT,            TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST},
#endif
    {UDMA_RM_RES_ID_PROXY,        TISCI_DEV_NAVSS0_PROXY_0,           TISCI_RESASG_SUBTYPE_PROXY_PROXIES,        TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST},
    {UDMA_RM_RES_ID_RING_MON,     TISCI_DEV_NAVSS0_RINGACC_0,          TISCI_RESASG_SUBTYPE_RA_MONITORS,          TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST}
};

/** \brief MCU Navss defaultBoardCfg Params */
const Udma_RmDefBoardCfgPrms gUdmaRmDefBoardCfg_McuNavss[UDMA_RM_DEFAULT_BOARDCFG_NUM_RES] =
{
    /* resId,                     reqType,                            reqSubtype,                               secHost */
    {UDMA_RM_RES_ID_TX_UHC,       TISCI_DEV_MCU_NAVSS0_UDMAP_0,        TISCI_RESASG_SUBTYPE_UDMAP_TX_UHCHAN,      TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST},
    {UDMA_RM_RES_ID_TX_HC,        TISCI_DEV_MCU_NAVSS0_UDMAP_0,        TISCI_RESASG_SUBTYPE_UDMAP_TX_HCHAN,       TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST},
    {UDMA_RM_RES_ID_TX,           TISCI_DEV_MCU_NAVSS0_UDMAP_0,        TISCI_RESASG_SUBTYPE_UDMAP_TX_CHAN,        TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST},
    {UDMA_RM_RES_ID_RX_UHC,       TISCI_DEV_MCU_NAVSS0_UDMAP_0,        TISCI_RESASG_SUBTYPE_UDMAP_RX_UHCHAN,      TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST},
    {UDMA_RM_RES_ID_RX_HC,        TISCI_DEV_MCU_NAVSS0_UDMAP_0,        TISCI_RESASG_SUBTYPE_UDMAP_RX_HCHAN,       TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST},
    {UDMA_RM_RES_ID_RX,           TISCI_DEV_MCU_NAVSS0_UDMAP_0,        TISCI_RESASG_SUBTYPE_UDMAP_RX_CHAN,        TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST},
    {UDMA_RM_RES_ID_UTC,          TISCI_DEV_MCU_NAVSS0_UDMAP_0,        TISCI_RESASG_SUBTYPE_UDMAP_TX_ECHAN,       TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST},
    {UDMA_RM_RES_ID_RX_FLOW,      TISCI_DEV_MCU_NAVSS0_UDMAP_0,        TISCI_RESASG_SUBTYPE_UDMAP_RX_FLOW_COMMON, TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST},
    {UDMA_RM_RES_ID_RING,         TISCI_DEV_MCU_NAVSS0_RINGACC0,      TISCI_RESASG_SUBTYPE_RA_GP,                TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST},
#if defined (BUILD_MCU1_0) || defined (BUILD_MCU1_1) /* Tied to cores and not split based on NAVSS instance */
    {UDMA_RM_RES_ID_GLOBAL_EVENT, TISCI_DEV_MCU_NAVSS0_UDMASS_INTA_0, TISCI_RESASG_SUBTYPE_GLOBAL_EVENT_SEVT,    TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST},
    {UDMA_RM_RES_ID_VINTR,        TISCI_DEV_MCU_NAVSS0_UDMASS_INTA_0, TISCI_RESASG_SUBTYPE_IA_VINT,              TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST},
    {UDMA_RM_RES_ID_IR_INTR,      TISCI_DEV_MCU_NAVSS0_INTR_0,        TISCI_RESASG_SUBTYPE_IR_OUTPUT,            TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST},
#else
    {UDMA_RM_RES_ID_GLOBAL_EVENT, TISCI_DEV_NAVSS0_UDMASS_INTAGGR_0,  TISCI_RESASG_SUBTYPE_GLOBAL_EVENT_SEVT,    TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST},
    {UDMA_RM_RES_ID_VINTR,        TISCI_DEV_NAVSS0_UDMASS_INTAGGR_0,  TISCI_RESASG_SUBTYPE_IA_VINT,              TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST},
    {UDMA_RM_RES_ID_IR_INTR,      TISCI_DEV_NAVSS0_INTR_ROUTER_0,     TISCI_RESASG_SUBTYPE_IR_OUTPUT,            TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST},
#endif
    {UDMA_RM_RES_ID_PROXY,        TISCI_DEV_MCU_NAVSS0_PROXY0,        TISCI_RESASG_SUBTYPE_PROXY_PROXIES,        TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST},
    {UDMA_RM_RES_ID_RING_MON,     TISCI_DEV_MCU_NAVSS0_RINGACC0,      TISCI_RESASG_SUBTYPE_RA_MONITORS,          TISCI_MSG_VALUE_RM_UNUSED_SECONDARY_HOST}
};

/**
  * Static sharing policy to share flows between different hosts.
  * RM Board Config does not take ownership of sharing of flows among cores.
  * UDMA driver need to define the sharing policy of these flows among cores.
*/
uint32_t gFlowInstShare[UDMA_NUM_CORE] =
{
    0U,                            /* MPU1_0  - Reserved in BoardCfg*/
    UDMA_RM_SHARED_RES_CNT_REST,   /* MCU2_0 */
    10U,                           /* MCU2_1 */
    8U,                            /* MCU3_0 */
    0U,                            /* MCU3_1 */
    0U,                            /* C7X_1 */
    0U,                            /* C66X_1 */
    0U,                            /* C66X_2 */
    0U,                            /* MCU1_0 */
    0U                             /* MCU1_1 */
};

#if defined (BUILD_MPU1_0)
       /*          instShare[                    MAIN_NAVSS,                  MCU_NAVSS ] */
    uint32_t gEvtInstShare[UDMA_NUM_INST_ID]  = {UDMA_RM_SHARED_RES_CNT_REST, UDMA_RM_SHARED_RES_CNT_MIN};
    uint32_t gVintInstShare[UDMA_NUM_INST_ID] = {UDMA_RM_SHARED_RES_CNT_REST, UDMA_RM_SHARED_RES_CNT_MIN};
    uint32_t gIntrInstShare[UDMA_NUM_INST_ID] = {UDMA_RM_SHARED_RES_CNT_REST, UDMA_RM_SHARED_RES_CNT_MIN};
#endif
#if defined (BUILD_MCU2_0)
        /*          instShare[                    MAIN_NAVSS,                  MCU_NAVSS ] */
    uint32_t gEvtInstShare[UDMA_NUM_INST_ID]  = {UDMA_RM_SHARED_RES_CNT_REST, UDMA_RM_SHARED_RES_CNT_MIN};
    uint32_t gVintInstShare[UDMA_NUM_INST_ID] = {UDMA_RM_SHARED_RES_CNT_REST, UDMA_RM_SHARED_RES_CNT_MIN};
    uint32_t gIntrInstShare[UDMA_NUM_INST_ID] = {UDMA_RM_SHARED_RES_CNT_REST, UDMA_RM_SHARED_RES_CNT_MIN};
#endif
#if defined (BUILD_MCU2_1)
        /*          instShare[                    MAIN_NAVSS,                  MCU_NAVSS ] */
    uint32_t gEvtInstShare[UDMA_NUM_INST_ID]  = {UDMA_RM_SHARED_RES_CNT_REST, UDMA_RM_SHARED_RES_CNT_MIN};
    uint32_t gVintInstShare[UDMA_NUM_INST_ID] = {UDMA_RM_SHARED_RES_CNT_REST, UDMA_RM_SHARED_RES_CNT_MIN};
    uint32_t gIntrInstShare[UDMA_NUM_INST_ID] = {UDMA_RM_SHARED_RES_CNT_REST, UDMA_RM_SHARED_RES_CNT_MIN};
#endif
#if defined (BUILD_MCU3_0)
        /*          instShare[                    MAIN_NAVSS,                  MCU_NAVSS ] */
    uint32_t gEvtInstShare[UDMA_NUM_INST_ID]  = {UDMA_RM_SHARED_RES_CNT_REST, UDMA_RM_SHARED_RES_CNT_MIN};
    uint32_t gVintInstShare[UDMA_NUM_INST_ID] = {UDMA_RM_SHARED_RES_CNT_REST, UDMA_RM_SHARED_RES_CNT_MIN};
    uint32_t gIntrInstShare[UDMA_NUM_INST_ID] = {UDMA_RM_SHARED_RES_CNT_REST, UDMA_RM_SHARED_RES_CNT_MIN};
#endif
#if defined (BUILD_MCU3_1)
        /*          instShare[                    MAIN_NAVSS,                  MCU_NAVSS ] */
    uint32_t gEvtInstShare[UDMA_NUM_INST_ID]  = {UDMA_RM_SHARED_RES_CNT_REST, UDMA_RM_SHARED_RES_CNT_MIN};
    uint32_t gVintInstShare[UDMA_NUM_INST_ID] = {UDMA_RM_SHARED_RES_CNT_REST, UDMA_RM_SHARED_RES_CNT_MIN};
    uint32_t gIntrInstShare[UDMA_NUM_INST_ID] = {UDMA_RM_SHARED_RES_CNT_REST, UDMA_RM_SHARED_RES_CNT_MIN};
#endif
#if defined (BUILD_C7X_1)
        /*          instShare[                    MAIN_NAVSS,                  MCU_NAVSS ] */
    uint32_t gEvtInstShare[UDMA_NUM_INST_ID]  = {UDMA_RM_SHARED_RES_CNT_REST, UDMA_RM_SHARED_RES_CNT_MIN};
    uint32_t gVintInstShare[UDMA_NUM_INST_ID] = {UDMA_RM_SHARED_RES_CNT_REST, UDMA_RM_SHARED_RES_CNT_MIN};
    uint32_t gIntrInstShare[UDMA_NUM_INST_ID] = {8U, UDMA_RM_SHARED_RES_CNT_MIN};
#endif
#if defined (BUILD_C66X_1)
        /*          instShare[                    MAIN_NAVSS,                  MCU_NAVSS ] */
    uint32_t gEvtInstShare[UDMA_NUM_INST_ID]  = {UDMA_RM_SHARED_RES_CNT_REST, UDMA_RM_SHARED_RES_CNT_MIN};
    uint32_t gVintInstShare[UDMA_NUM_INST_ID] = {UDMA_RM_SHARED_RES_CNT_REST, UDMA_RM_SHARED_RES_CNT_MIN};
    uint32_t gIntrInstShare[UDMA_NUM_INST_ID] = {UDMA_RM_SHARED_RES_CNT_REST, UDMA_RM_SHARED_RES_CNT_MIN};
#endif
#if defined (BUILD_C66X_2)
        /*          instShare[                    MAIN_NAVSS,                  MCU_NAVSS ] */
    uint32_t gEvtInstShare[UDMA_NUM_INST_ID]  = {UDMA_RM_SHARED_RES_CNT_REST, UDMA_RM_SHARED_RES_CNT_MIN};
    uint32_t gVintInstShare[UDMA_NUM_INST_ID] = {UDMA_RM_SHARED_RES_CNT_REST, UDMA_RM_SHARED_RES_CNT_MIN};
    uint32_t gIntrInstShare[UDMA_NUM_INST_ID] = {UDMA_RM_SHARED_RES_CNT_REST, UDMA_RM_SHARED_RES_CNT_MIN};
#endif
#if defined (BUILD_MCU1_0)
        /*          instShare[                    MAIN_NAVSS,                  MCU_NAVSS ] */
    uint32_t gEvtInstShare[UDMA_NUM_INST_ID]  = {UDMA_RM_SHARED_RES_CNT_MIN, UDMA_RM_SHARED_RES_CNT_REST};
    uint32_t gVintInstShare[UDMA_NUM_INST_ID] = {UDMA_RM_SHARED_RES_CNT_MIN, UDMA_RM_SHARED_RES_CNT_REST};
    uint32_t gIntrInstShare[UDMA_NUM_INST_ID] = {UDMA_RM_SHARED_RES_CNT_MIN, UDMA_RM_SHARED_RES_CNT_REST};
#endif
#if defined (BUILD_MCU1_1)
        /*          instShare[                    MAIN_NAVSS,                  MCU_NAVSS ] */
    uint32_t gEvtInstShare[UDMA_NUM_INST_ID]  = {UDMA_RM_SHARED_RES_CNT_MIN, UDMA_RM_SHARED_RES_CNT_REST};
    uint32_t gVintInstShare[UDMA_NUM_INST_ID] = {UDMA_RM_SHARED_RES_CNT_MIN, UDMA_RM_SHARED_RES_CNT_REST};
    uint32_t gIntrInstShare[UDMA_NUM_INST_ID] = {UDMA_RM_SHARED_RES_CNT_MIN, UDMA_RM_SHARED_RES_CNT_REST};
#endif


/** \brief Shared resource Params */
Udma_RmSharedResPrms gUdmaRmSharedResPrms[UDMA_RM_NUM_SHARED_RES] =
{
    /* MAIN NAVSS RX Free Flows are assigned to HOST_ID_ALL and some cores dosen't have core specific reservation */
    /* resId,                     startResrvCnt, endResrvCnt, numInst,           minReq, instShare */
    {UDMA_RM_RES_ID_RX_FLOW,      0U,            0U,          UDMA_NUM_CORE,     0U,     gFlowInstShare},
    /* Global Events/VINTR/IN INTR must be used based on core and split across MCU and MAIN NAVSS instances */
#if defined (BUILD_MPU1_0)
    /* resId,                     startResrvCnt, endResrvCnt, numInst,           minReq, instShare */
    {UDMA_RM_RES_ID_GLOBAL_EVENT, 0U,            0U,          UDMA_NUM_INST_ID,  50U,    gEvtInstShare },
    {UDMA_RM_RES_ID_VINTR,        0U,            0U,          UDMA_NUM_INST_ID,  4U,     gVintInstShare},
    {UDMA_RM_RES_ID_IR_INTR,      0U,            5U,          UDMA_NUM_INST_ID,  4U,     gIntrInstShare},
#endif
#if defined (BUILD_MCU2_0)
    /* resId,                     startResrvCnt, endResrvCnt, numInst,           minReq, instShare */
    {UDMA_RM_RES_ID_GLOBAL_EVENT, 0U,            0U,          UDMA_NUM_INST_ID,  50U,    gEvtInstShare },
    {UDMA_RM_RES_ID_VINTR,        0U,            0U,          UDMA_NUM_INST_ID,  8U,     gVintInstShare},
    {UDMA_RM_RES_ID_IR_INTR,      0U,            5U,          UDMA_NUM_INST_ID,  8U,     gIntrInstShare},
#endif
#if defined (BUILD_MCU2_1)
    /* resId,                     startResrvCnt, endResrvCnt, numInst,           minReq, instShare */
    {UDMA_RM_RES_ID_GLOBAL_EVENT, 0U,            0U,          UDMA_NUM_INST_ID,  50U,    gEvtInstShare },
    {UDMA_RM_RES_ID_VINTR,        0U,            0U,          UDMA_NUM_INST_ID,  4U,     gVintInstShare},
    {UDMA_RM_RES_ID_IR_INTR,      0U,            5U,          UDMA_NUM_INST_ID,  4U,     gIntrInstShare},
#endif
#if defined (BUILD_MCU3_0)
    /* resId,                     startResrvCnt, endResrvCnt, numInst,           minReq, instShare */
    {UDMA_RM_RES_ID_GLOBAL_EVENT, 0U,            0U,          UDMA_NUM_INST_ID,  50U,    gEvtInstShare },
    {UDMA_RM_RES_ID_VINTR,        0U,            0U,          UDMA_NUM_INST_ID,  4U,     gVintInstShare},
    {UDMA_RM_RES_ID_IR_INTR,      0U,            5U,          UDMA_NUM_INST_ID,  8U,     gIntrInstShare},
#endif
#if defined (BUILD_MCU3_1)
    /* resId,                     startResrvCnt, endResrvCnt, numInst,           minReq, instShare*/
    {UDMA_RM_RES_ID_GLOBAL_EVENT, 0U,            0U,          UDMA_NUM_INST_ID,  50U,    gEvtInstShare },
    {UDMA_RM_RES_ID_VINTR,        0U,            0U,          UDMA_NUM_INST_ID,  4U,     gVintInstShare},
    {UDMA_RM_RES_ID_IR_INTR,      0U,            5U,          UDMA_NUM_INST_ID,  4U,     gIntrInstShare},
#endif
#if defined (BUILD_C7X_1)
    /* resId,                     startResrvCnt, endResrvCnt, numInst,           minReq, instShare*/
    {UDMA_RM_RES_ID_GLOBAL_EVENT, 0U,            0U,          UDMA_NUM_INST_ID,  50U,    gEvtInstShare },
    {UDMA_RM_RES_ID_VINTR,        0U,            0U,          UDMA_NUM_INST_ID,  4U,     gVintInstShare},
    {UDMA_RM_RES_ID_IR_INTR,      0U,            5U,          UDMA_NUM_INST_ID,  4U,     gIntrInstShare},
#endif
#if defined (BUILD_C66X_1)
    /* resId,                     startResrvCnt, endResrvCnt, numInst,           minReq, instShare*/
    {UDMA_RM_RES_ID_GLOBAL_EVENT, 0U,            0U,          UDMA_NUM_INST_ID,  50U,    gEvtInstShare },
    {UDMA_RM_RES_ID_VINTR,        0U,            0U,          UDMA_NUM_INST_ID,  4U,     gVintInstShare},
    {UDMA_RM_RES_ID_IR_INTR,      0U,            5U,          UDMA_NUM_INST_ID,  4U,     gIntrInstShare},
#endif
#if defined (BUILD_C66X_2)
    /* resId,                     startResrvCnt, endResrvCnt, numInst,           minReq, instShare */
    {UDMA_RM_RES_ID_GLOBAL_EVENT, 0U,            0U,          UDMA_NUM_INST_ID,  50U,    gEvtInstShare },
    {UDMA_RM_RES_ID_VINTR,        0U,            0U,          UDMA_NUM_INST_ID,  4U,     gVintInstShare},
    {UDMA_RM_RES_ID_IR_INTR,      0U,            5U,          UDMA_NUM_INST_ID,  4U,     gIntrInstShare},
#endif
#if defined (BUILD_MCU1_0)
    /* resId,                     startResrvCnt, endResrvCnt, numInst,           minReq, instShare */
    {UDMA_RM_RES_ID_GLOBAL_EVENT, 0U,            0U,          UDMA_NUM_INST_ID,  50U,    gEvtInstShare },
    {UDMA_RM_RES_ID_VINTR,        0U,            0U,          UDMA_NUM_INST_ID,  4U,     gVintInstShare},
    {UDMA_RM_RES_ID_IR_INTR,      0U,            5U,          UDMA_NUM_INST_ID,  4U,     gIntrInstShare},
#endif
#if defined (BUILD_MCU1_1)
    /* resId,                     startResrvCnt, endResrvCnt, numInst,           minReq, instShare */
    {UDMA_RM_RES_ID_GLOBAL_EVENT, 0U,            0U,          UDMA_NUM_INST_ID,  16U,    gEvtInstShare },
    {UDMA_RM_RES_ID_VINTR,        0U,            0U,          UDMA_NUM_INST_ID,  2U,     gVintInstShare},
    {UDMA_RM_RES_ID_IR_INTR,      0U,            5U,          UDMA_NUM_INST_ID,  4U,     gIntrInstShare},
#endif
};


/* ========================================================================== */
/*                          Function Definitions                              */
/* ========================================================================== */

const Udma_RmDefBoardCfgPrms *Udma_rmGetDefBoardCfgPrms(uint32_t instId)
{
    const Udma_RmDefBoardCfgPrms  *rmDefBoardCfgPrms;

    if(UDMA_INST_ID_MCU_0 == instId)
    {
        rmDefBoardCfgPrms = &gUdmaRmDefBoardCfg_McuNavss[0U];
    }
    else
    {
        rmDefBoardCfgPrms = &gUdmaRmDefBoardCfg_MainNavss[0U];
    }

    return (rmDefBoardCfgPrms);
}

Udma_RmSharedResPrms *Udma_rmGetSharedResPrms(uint32_t resId)
{
    Udma_RmSharedResPrms  *rmSharedResPrms = NULL;
    uint32_t    i;

    for (i = 0U; i < UDMA_RM_NUM_SHARED_RES; i++)
    {
        if(resId == gUdmaRmSharedResPrms[i].resId)
        {
            rmSharedResPrms = &gUdmaRmSharedResPrms[i];
            break;
        }
    }

    return (rmSharedResPrms);
}


