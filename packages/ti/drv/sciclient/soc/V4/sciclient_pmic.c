/*
 * Copyright (c) 2024, Texas Instruments Incorporated
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

/**
 * \file sciclient_pmic.c
 *
 * \brief PMIC control for J721S2 device
 *
 */

/* ========================================================================== */
/*                             Include Files                                  */
/* ========================================================================== */

#include <stdint.h>
#include <ti/csl/soc.h>
#include <ti/csl/csl_gpio.h>
#include <ti/drv/sciclient/sciclient.h>

/* ========================================================================== */
/*                           Macros & Typedefs                                */
/* ========================================================================== */

/** \brief Resistor disable */
#define PIN_PULL_DISABLE                (0x1U << 16U)
/** \brief Receiver enable */
#define PIN_INPUT_ENABLE                (0x1U << 18U)
/** \brief Pin mux mode */
#define GPIO_PADCONFIG_MUX_MODE         (7U)

/* ========================================================================== */
/*                          Function Definitions                              */
/* ========================================================================== */

void Sciclient_pmicShutdown(void)
{
    /* WKUP_GPIO0_55 */
    uint32_t sys_pwr_gpio_pin     = 55U;
    uint32_t gpio_pin_reg_offset  = sys_pwr_gpio_pin / 32U;
    uint32_t gpio_pin_reg_bit_pos = sys_pwr_gpio_pin % 32U;
    uint32_t regVal;

    /* Sets the pinmux mode to 7 for using the gpio pin(WKUP_GPIO0_55) corresponding to SYS_MCU_PWRDN */
    CSL_REG32_WR(CSL_WKUP_CTRL_MMR0_CFG0_BASE + CSL_WKUP_CTRL_MMR_CFG0_PADCONFIG41, (PIN_PULL_DISABLE | PIN_INPUT_ENABLE) | GPIO_PADCONFIG_MUX_MODE);

    /* Sets the gpio pin to an output pin */
    regVal = CSL_REG32_RD((uint32_t *)(CSL_WKUP_GPIO0_BASE + CSL_GPIO_DIR(gpio_pin_reg_offset)));
    regVal = regVal & ~(1U << (gpio_pin_reg_bit_pos));
    CSL_REG32_WR(CSL_WKUP_GPIO0_BASE + CSL_GPIO_DIR(gpio_pin_reg_offset), regVal);

    /* Toggles the gpio to poweroff the pmic */
    regVal = CSL_REG32_RD((uint32_t *)(CSL_WKUP_GPIO0_BASE + CSL_GPIO_OUT_DATA(gpio_pin_reg_offset)));
    regVal = regVal | (1U << (gpio_pin_reg_bit_pos));
    CSL_REG32_WR(CSL_WKUP_GPIO0_BASE + CSL_GPIO_OUT_DATA(gpio_pin_reg_offset), regVal);
}
