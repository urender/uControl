/* Copyright (C) 2022 John Crispin <john@phrozen.org> */

'use strict';

import * as devices from 'uDevice.devices';
import { response_timer } from 'uDevice.methods';
import * as events from 'uControl.events';

/* handlers called upon command completion */
let handlers = {
	configure: function(device, msg) {
		device.uuid = device.config.uuid;
		events.device(device.serial, 'configure', `The device applied a new config (${device.uuid})`, msg.result?.rejected);
	},

	reboot: function(device, msg) {
		events.device(device.serial, 'reboot', 'The device is rebooting.');
	},

	factory: function(device, msg) {
		events.device(device.serial, 'factory', 'The device is performing a factory reset.');
	},

	leds: function(device, msg) {
		events.device(device.serial, 'leds', 'Applied LED pattern.');
	},
};

/**
 * callback gets triggered when a request did not result in a response
 */
function response_timer_cb(device, id) {
	/* make sure the request exists */
	let req = device.requests[id];
	if (!req)
		return;

	/* log the expiry of the command */
	delete device.requests[id];
	events.device(device.serial, 'error', `The device did not respond to a '${req.method}' command on time (${req.id})`);
}
response_timer(response_timer_cb);

/**
 * handle an incoming response
 */
export function handle(connection, msg) {
	/* try to find the matching device */
	let device = devices.get(connection.data().serial);
	if (!device)
		return;

	/* make sure the request exists */
	let req = device.requests[msg.id];
	if (!req) {
		events.device(connection.serial, 'error', 'Received a response for an unknown request.');
		return;
	}

	/* cancel the request timer */
	req.timeout.cancel();

	/* find the corresponding handler */
	let handler = handlers[req.method];
	if (!handler)
		return;

	/* execute the handler */
	handler(device, msg);

	/* stop tracking the request */
	delete device.requests[msg.id];
};
