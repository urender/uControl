/* Copyright (C) 2022 John Crispin <john@phrozen.org> */

'use strict';

import * as devices from 'uDevice.devices';
import * as events from 'uControl.events';

/**
 * handle a connect notification sent by a device
 */
export function connect(connection, msg) {
	/* basic sanity check */
	let params = msg.params;

	/* validate that the serial matches the CN */
	/*if (params.serial != connection.CN) {
		ulog_info('%s: received a connect message with an invalid CN:%s\n', params.serial, connection.CN);
		return false;
	}*/

	/* do not allow duplicate connections from same serial */
	if (devices.connected(params.serial)) {
		events.device(params.serial, 'error', 'Received a connect message, but device is already connected');
		return;
	}

	/* try to load the device state from a previous connection */
	devices.connect(connection, params);
};

/**
 * handle a periodic state event
 */
export function state(connection, msg) {
	let serial = connection.data().serial;

	/* get the device */
	let device = devices.get(serial);

	/* TODO: push to sqlite3 backend */
	device.state = msg.params;

	//ulog.info(`${device.serial}: received a state message\n`);
};

/**
 * handle a periodic state event
 */
export function crashlog(connection, msg) {
	let serial = connection.data().serial;

	/* get the device */
	let device = devices.get(serial);

	events.device(serial, 'error', 'Received a crashlog', msg.params.crashlog);
};


