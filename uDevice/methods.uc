/* Copyright (C) 2022 John Crispin <john@phrozen.org> */

'use strict';

import { timer } from 'uloop';
import * as reader from 'uReader.device_method';

let response_timer_cb;

/**
 * allow the response module to register the timer_cb
 */
export function response_timer(func) {
	response_timer_cb = func;
};

/**
 * The intermediate timer_cb
 */
function timer_cb(device, id) {
	if (response_timer_cb)
		response_timer_cb(device, id);
}

/**
 * add a command to the pending queue
 */
function request_add(device, method, id, timeout) {
	let request = {
		method,
		id,
		timeout: timer((timeout || 10) * 1000, () => timer_cb(device, id)),
	};
	device.requests[id] = request;
}

/**
 * send the actual command after verifying it with the reader
 */
function jsonrpc(device, method, params, timeout) {
	/* prepare the actual jsonrpc message */
	let rpc = {
		jsonrpc: '2.0',
		id: device.id,
		method,
	};
	if (params)
		rpc.params = params;
	let errors = [];

	/* validate the message */
	rpc = reader.validate(rpc, errors);
	if (!rpc) {
		events.device(device.serial, 'error', 'Failed to send request: ${method}.');
		return 1;
	}

	/* track the request */
	request_add(device, method, device.id, timeout);

	/* send the request */
	if (global.debug)
		warn(`${device.serial}: sending ${rpc}\n`);
	device.connection.send(`${rpc}`);

	/* increment the connections request id */
	device.id++;

	return 0;
}

/**
 * controller sends this command when it wants the device to load a new configuration
 */
export function configure(device) {
	jsonrpc(device, 'configure', device.config, 10);
};

/**
 * controller sends this command when it wants the device to change the LED behaviour
 */
export function leds(device, pattern, duration) {
	jsonrpc(device, 'leds', { pattern, duration }, duration ? duration * 2 : 10);
};

/**
 * controller sends this command when it wants the device to reboot
 */
export function reboot(device) {
	jsonrpc(device, 'reboot');
};

/**
 * controller sends this command when it wants the device to perform a factory reset
 */
export function factory(device) {
	jsonrpc(device, 'factory');
};

/**
 * controller sends this command when it wants the device to perform a sysupgrade
 */
export function upgrade(device, params) {
	jsonrpc(device, 'upgrade', params);
};
