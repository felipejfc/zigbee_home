/*
 * Copyright (c) 2022 Nordic Semiconductor ASA
 *
 * SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
 */

 // Generated by zigbee_home on {{ .GeneratedOn }}, version {{ .Version }}

#include <zephyr/device.h>
#include <dk_buttons_and_leds.h>
// #include <zephyr/drivers/uart.h>
#include <zephyr/logging/log.h>
#include <ram_pwrdn.h>
#include <zb_nrf_platform.h>
#include <zboss_api.h>
#include <zboss_api_addons.h>
#include <zephyr/kernel.h>
#include <zigbee/zigbee_app_utils.h>
#include <zigbee/zigbee_error_handler.h>

// Header only, why not?
#include "device.h"

// Extender includes
{{- range .Extenders}}
{{- range .Includes}}
#include "{{.}}"
{{- end}}
{{- end}}
// Extender includes end

// Extender top levels
{{- range .Extenders}}
{{- maybeRenderExtender .Template "top_level" (sensorCtx 0 $.Device nil .)}}
{{- end}}
// Extender top levels end

// Sensor templates top level
{{- range $i, $sensor := .Device.Sensors}}
{{ $endpoint := (sum $i 1)}}
// -- {{$sensor}}, for endpoint {{$i}}
{{- with maybeRenderExtender $sensor.Template "top_level" (sensorCtx $endpoint $.Device $sensor nil)}}
{{.}}
{{- else }}
{{- /* Assume that generating device is all that necessary */}}
static const struct device *{{$sensor.Label}}_{{$endpoint}} = DEVICE_DT_GET(DT_NODELABEL({{$sensor.Label}}));
{{- end}}
// -- {{$sensor}}, for endpoint {{$i}} end
{{- end}}
// Sensor templates top end

LOG_MODULE_REGISTER(app, LOG_LEVEL_DBG);

#define DEVICE_INITIAL_DELAY_MSEC 10000

static void button_changed(uint32_t button_state, uint32_t has_changed)
{
	if (IDENTIFY_MODE_BUTTON & has_changed) {
		if (IDENTIFY_MODE_BUTTON & button_state) {
			/* Button changed its state to pressed */
		} else {
			/* Button changed its state to released */
			if (was_factory_reset_done()) {
				/* The long press was for Factory Reset */
				LOG_DBG("After Factory Reset - ignore button release");
			} else   {
				/* Button released before Factory Reset */

				#if CONFIG_ZIGBEE_ROLE_END_DEVICE
				/* Inform default signal handler about user input at the device */
				user_input_indicate();
				#endif
			}
		}
	}

	check_factory_reset_button(button_state, has_changed);
}

static void gpio_init(void)
{
	int err = dk_buttons_init(button_changed);

	if (err) {
		LOG_ERR("Cannot init buttons (err: %d)", err);
	}

	err = dk_leds_init();
	if (err) {
		LOG_ERR("Cannot init LEDs (err: %d)", err);
	}
}

#ifdef CONFIG_USB_DEVICE_STACK
static void wait_for_console(void)
{
	const struct device *console = DEVICE_DT_GET(DT_CHOSEN(zephyr_console));
	uint32_t dtr = 0;
	uint32_t time = 0;

	/* Enable the USB subsystem and associated HW */
	if (usb_enable(NULL)) {
		LOG_ERR("Failed to enable USB");
	} else {
		/* Wait for DTR flag or deadline (e.g. when USB is not connected) */
		while (!dtr && time < WAIT_FOR_CONSOLE_DEADLINE_MSEC) {
			uart_line_ctrl_get(console, UART_LINE_CTRL_DTR, &dtr);
			/* Give CPU resources to low priority threads */
			k_sleep(K_MSEC(WAIT_FOR_CONSOLE_MSEC));
			time += WAIT_FOR_CONSOLE_MSEC;
		}
	}
}
#endif /* CONFIG_USB_DEVICE_STACK */

/**@brief Callback function for handling ZCL commands.
 *
 * @param[in]   bufid   Reference to Zigbee stack buffer
 *                      used to pass received data.
 */
static void zcl_device_cb(zb_bufid_t bufid)
{
	zb_zcl_device_callback_param_t  *device_cb_param =
		ZB_BUF_GET_PARAM(bufid, zb_zcl_device_callback_param_t);

	LOG_INF("%s id %hd", __func__, device_cb_param->device_cb_id);

	/* Set default response value. */
	device_cb_param->status = RET_OK;

	zb_uint8_t cluster_id;
	zb_uint8_t attr_id;
	zb_uint8_t endpoint_id = device_cb_param->endpoint;

	switch (device_cb_param->device_cb_id) {
	case ZB_ZCL_SET_ATTR_VALUE_CB_ID:
		cluster_id = device_cb_param->cb_param.
			     set_attr_value_param.cluster_id;
		attr_id = device_cb_param->cb_param.
			  set_attr_value_param.attr_id;

		ZB_ZCL_SET_ATTRIBUTE(
			endpoint_id,
			cluster_id,
			ZB_ZCL_CLUSTER_SERVER_ROLE,
			attr_id,
			// This will not work for all types, but good enough for now, until it will not be.
			(zb_uint8_t *)&device_cb_param->cb_param.set_attr_value_param.values.data8,
			ZB_FALSE);

		switch (cluster_id) {
		case ZB_ZCL_CLUSTER_ID_ON_OFF:
			uint8_t value =
				device_cb_param->cb_param.set_attr_value_param
				.values.data8;

			if (attr_id == ZB_ZCL_ATTR_ON_OFF_ON_OFF_ID) {
				// on_off_set_value((zb_bool_t)value);
				int state = (zb_bool_t)value ? 1 : 0;
				{{- range $sensorIdx, $sensor := .Device.Sensors}}
				{{- range $sensor.Clusters}}
				{{- if eq .ID 6}}
				if (endpoint_id == {{sum $sensorIdx 1}}) {
					gpio_pin_set_dt(&{{.PinLabel}}, state);
				}
				{{- end}}
				{{- end}}
				{{- end}}
			}
			break;
		default:
			/* Other clusters can be processed here */
			LOG_INF("Unhandled cluster attribute id: %d",
				cluster_id);
			device_cb_param->status = RET_NOT_IMPLEMENTED;
			break;
		}

		break;

	default:
		// if (zcl_scenes_cb(bufid) == ZB_FALSE) {
		// 	device_cb_param->status = RET_NOT_IMPLEMENTED;
		// }
		break;
	}

	LOG_INF("%s status: %hd", __func__, device_cb_param->status);
}

static void loop(zb_bufid_t bufid) 
{
	ZVUNUSED(bufid);

	// -- Extenders start
	{{- range .Extenders}}
	{{- maybeRenderExtender .Template "loop" (sensorCtx 0 $.Device nil .)}}
	{{- end}}
	// -- Extenders end

	{{- range $i, $sensor := .Device.Sensors}}
	{{ $endpointID := (sum $i 1)}}
	// -- {{$sensor}}, for endpoint {{$i}}
	{{- with maybeRenderExtender $sensor.Template "loop" (sensorCtx $endpointID $.Device $sensor nil)}}
	{
		{{.}}
	}
	{{- else }}
	{
		sensor_sample_fetch({{$sensor.Label}}_{{$endpointID}});

		{{- range $sensor.Clusters }}
		zbhome_sensor_fetch_and_update_{{.CVarName}}({{$sensor.Label}}_{{$endpointID}}, {{$endpointID}});
		{{- end}}
	}
	{{- end}}
	// -- {{$sensor}}, for endpoint {{$i}} end
	{{- end}}

	zb_ret_t zb_err = ZB_SCHEDULE_APP_ALARM(loop,
					0,
					ZB_MILLISECONDS_TO_BEACON_INTERVAL({{.Device.General.RunEvery.Milliseconds}}));
	if (zb_err) {
		LOG_ERR("Failed to schedule app alarm: %d", zb_err);
	}
}

void zboss_signal_handler(zb_bufid_t bufid)
{
	zb_zdo_app_signal_hdr_t *signal_header = NULL;
	zb_zdo_app_signal_type_t signal = zb_get_app_signal(bufid, &signal_header);
	zb_ret_t err = RET_OK;

	/* Update network status LED but only for debug configuration */
	#ifdef CONFIG_ZBHOME_DEBUG_LEDS
	zigbee_led_status_update(bufid, ZIGBEE_NETWORK_STATE_LED);
	#endif /* CONFIG_ZBHOME_DEBUG_LEDS */

	/* Detect ZBOSS startup */
	switch (signal) {
	case ZB_ZDO_SIGNAL_SKIP_STARTUP:
		/* ZBOSS framework has started - schedule first weather check */
		err = ZB_SCHEDULE_APP_ALARM(loop,
					    0,
					    ZB_MILLISECONDS_TO_BEACON_INTERVAL(
						    DEVICE_INITIAL_DELAY_MSEC));
		if (err) {
			LOG_ERR("Failed to schedule app alarm: %d", err);
		}
		break;
	default:
		break;
	}

	/* Let default signal handler process the signal*/
	ZB_ERROR_CHECK(zigbee_default_signal_handler(bufid));

	/*
	 * All callbacks should either reuse or free passed buffers.
	 * If bufid == 0, the buffer is invalid (not passed).
	 */
	if (bufid) {
		zb_buf_free(bufid);
	}
}

int init_templates() {
	// --- Extenders start
	{{- range .Extenders}}
	{{- with (maybeRenderExtender .Template "main" (sensorCtx 0 $.Device nil .))}}
	{
		{{.}}
	}
	{{- end}}
	{{- end}}
	// --- Extenders end

	// --- Sensors start
	{{- range $i, $sensor := .Device.Sensors}}
	{{ $endpoint := (sum $i 1)}}
	{{- with (maybeRenderExtender $sensor.Template "main" (sensorCtx $endpoint $.Device $sensor nil))}}
	{
		{{.}}
	}
	{{- else }}
	{
		if (!{{$sensor.Label}}_{{$endpoint}}) {
			LOG_ERR("Failed to get {{$sensor.Label}}");
			return ENODEV;
		}
	}
	{{- end}}
	{{- end}}
	// --- Sensors end

	return 0;
}

int main(void)
{
	#ifdef CONFIG_USB_DEVICE_STACK
	wait_for_console();
	#endif /* CONFIG_USB_DEVICE_STACK */

	register_factory_reset_button(FACTORY_RESET_BUTTON);
	gpio_init();

	/* Register device context (endpoint) */
	ZB_AF_REGISTER_DEVICE_CTX(&device_ctx);

	/* Register callback for handling ZCL commands. */
	ZB_ZCL_REGISTER_DEVICE_CB(zcl_device_cb);

	/* Init Basic and Identify attributes */
	mandatory_clusters_attr_init();

	/* Init measurements-related attributes */
	measurements_clusters_attr_init();

	int init_result = 0;
	init_result = init_templates();
	if (init_result != 0) {
		return init_result;
	}

	/* Register callback to identify notifications */
	// ZB_AF_SET_IDENTIFY_NOTIFICATION_HANDLER(DEVICE_ENDPOINT_NB, identify_callback);

	#if CONFIG_ZIGBEE_ROLE_END_DEVICE
	/* Enable Sleepy End Device behavior */
	zb_set_rx_on_when_idle(ZB_FALSE);
	#endif

	if (IS_ENABLED(CONFIG_RAM_POWER_DOWN_LIBRARY)) {
		power_down_unused_ram();
	}

	/* Start Zigbee stack */
	zigbee_enable();

	#if CONFIG_ZBHOME_DEBUG_LEDS
	gpio_pin_set_dt({{ if .Device.Board.Debug.Enabled}}&{{.Device.Board.Debug.LEDs.Power}}{{else}}none{{end}}, 1);
	#endif /* CONFIG_ZBHOME_DEBUG_LEDS */

	return 0;
}
