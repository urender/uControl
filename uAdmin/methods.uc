/* Copyright (C) 2022 John Crispin <john@phrozen.org> */

'use strict';

import * as uDevices from 'uDevice.devices';
import * as methods from 'uDevice.methods';

/**
 * send the actual command after verifying it with the reader
 */
function jsonrpc(connection, msg, params) {
	/* prepare the actual jsonrpc message */
	let rpc = {
		jsonrpc: '2.0',
		id: msg.id,
	};

	if (params.code)
		rpc.error = params;
	else
		rpc.result = params.message;

	/* send the reply */
	if (global.debug)
		warn(`${connection.data().ip}: sending ${rpc}\n`);
	connection.send(`${rpc}`);
}

/**
 * helper to lookup_device
 */
function device_lookup(connection, msg) {
	let device = uDevices.get(msg.params.serial);

	if (!device) {
		jsonrpc(connection, msg, { code: 1, message: "Unknown device" });
		return null;
	}

	if (!device.connected) {
		jsonrpc(connection, msg, { code: 1, message: "Device is not connected" });
		return null;
	}

	return device;
}

/**
 * The UI requested a list of devices
 */
export function devices(connection, msg) {
	/* get the device */
	jsonrpc(connection, msg, { code: 0, message: uDevices.get(msg.params?.serial) });
};

/**
 * The UI wants to make a device change its LED behaviour
 */
export function leds(connection, msg) {
	let device = device_lookup(connection, msg);

	if (!device)
		return;

	if (!methods.leds(device, msg.params.pattern, msg.params.duration))
		jsonrpc(connection, msg, { code: 0, message: "Sent command" });

};

/**
 * The UI wants the device to reboot
 */
export function reboot(connection, msg) {
	let device = device_lookup(connection, msg);

	if (!device)
		return;

	if (!methods.reboot(device))
		jsonrpc(connection, msg, { code: 0, message: "Sent command" });
};

/**
 * The UI wants the device to reboot
 */
export function factory(connection, msg) {
	let device = device_lookup(connection, msg);

	if (!device)
		return;

	if (!methods.factory(device))
		jsonrpc(connection, msg, { code: 0, message: "Sent command" });
};

/**
 * The UI wants the device to upgrade its FW
 */
export function upgrade(connection, msg) {
	let device = device_lookup(connection, msg);

	if (!device)
		return;

	if (!methods.upgrade(device, msg.params))
		jsonrpc(connection, msg, { code: 0, message: "Sent command" });
};
