// Parts of this file can come from ZBOSS nRF SDK v2.5.0:
// <nrf_sdk_path>/v2.5.0/nrfxlib/zboss/production/include/zcl/zb_zcl_common.h
/*
 * ZBOSS Zigbee 3.0
 *
 * Copyright (c) 2012-2022 DSR Corporation, Denver CO, USA.
 * www.dsr-zboss.com
 * www.dsr-corporation.com
 * All rights reserved.
 *
 *
 * Use in source and binary forms, redistribution in binary form only, with
 * or without modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions in binary form, except as embedded into a Nordic
 *    Semiconductor ASA integrated circuit in a product or a software update for
 *    such product, must reproduce the above copyright notice, this list of
 *    conditions and the following disclaimer in the documentation and/or other
 *    materials provided with the distribution.
 *
 * 2. Neither the name of Nordic Semiconductor ASA nor the names of its
 *    contributors may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * 3. This software, with or without modification, must only be used with a Nordic
 *    Semiconductor ASA integrated circuit.
 *
 * 4. Any software provided in binary form under this license must not be reverse
 *    engineered, decompiled, modified and/or disassembled.
 *
 * THIS SOFTWARE IS PROVIDED BY NORDIC SEMICONDUCTOR ASA "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY, NONINFRINGEMENT, AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL NORDIC SEMICONDUCTOR ASA OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package cluster

type ID int

func (id ID) String() string {
	switch id {
	case 0:
		return "ZB_ZCL_CLUSTER_ID_BASIC"
	case 3:
		return "ZB_ZCL_CLUSTER_ID_IDENTIFY"
	case 6:
		return "ZB_ZCL_CLUSTER_ID_ON_OFF"
	case 1026:
		return "ZB_ZCL_CLUSTER_ID_TEMP_MEASUREMENT"
	case 1027:
		return "ZB_ZCL_CLUSTER_ID_PRESSURE_MEASUREMENT"
	case 1029:
		return "ZB_ZCL_CLUSTER_ID_REL_HUMIDITY_MEASUREMENT"
	}

	return "<unknown>"
}

const ID_BASIC ID = 0    // Basic cluster identifier.
const ID_IDENTIFY ID = 3 // Identify cluster identifier.
const ID_ON_OFF ID = 6   // On/Off cluster identifier.

/* Measurement and Sensing */
const ID_TEMP_MEASUREMENT ID = 1026         // Temperature measurement
const ID_PRESSURE_MEASUREMENT ID = 1027     // Pressure measurement
const ID_REL_HUMIDITY_MEASUREMENT ID = 1029 // Relative humidity measurement
