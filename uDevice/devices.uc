/* Copyright (C) 2022 John Crispin <john@phrozen.org> */

'use strict';

/**
 * list of all currently known device
 */
let devices = {};

import * as fs from 'fs';
import * as ubus from 'uControl.ubus';
import * as configurations from 'uDevice.configurations';
import * as capabilities from 'uDevice.capabilities';
import * as methods from 'uDevice.methods';
import * as events from 'uControl.events';

/**
 * load a device info from the filesystem
 */
export function load(serial) {
	if (devices[serial])
		return false;

	/* open the state file */
	let path = sprintf('/etc/urender/device/%s', serial);
	let file = fs.open(path, 'r');

	if (!file)
		return false;

	/* read the device info */
	events.device(serial, 'load', 'Loading info.');
	devices[serial] = {
		serial,
		base: json(file.read('all')),
		capabilities: capabilities.load(serial),
		config: configurations.load(serial),
		requests: {},
	};
	file.close();

	return true;
};

/**
 * load a devices config from the filesystem
 */
export function store(serial) {
	/* open the device file */
	let path = sprintf('/etc/urender/device/%s', serial);
	let file = fs.open(path, 'w');

	/* check if we can write to the file (folder might be missing) */
	if (!file)
		return;

	/* write the device file */
	file.write(devices[serial].base);
	file.close();
};

/**
 * check if a device is connected
 */
export function connected(serial) {
	return devices[serial]?.connected;
};

/**
 * a device has connected
 */
export function connect(connection, params) {
	let serial = params.serial;
	let device = devices[serial];

	/* check if the device is known */
	if (!device) {
		events.device(serial, 'error', 'Connect from unknown device.');
		return;
	}
	/* track the connections serial inside the connection resource */
	connection.data().serial = serial;

	/* mark the devics as connected */
	device.connected = 1;
	connection.data().connected = 1;
	device.connection = connection;

	/* set the initial request ID */
	devices[serial].id = 1;

	/* store the connect time and write the file to the fs */
	device.seen = time();

	/* store the currently applied config */
	device.uuid = params.uuid;

	/* check if the capabilities have changed */
	if (device.capabilities.uuid < params.capabilities.uuid) {
		/* update capabilities in state and filesystem */
		capabilities.store(serial, params.capabilities);
		device.capabilities = params.capabilities;
		events.device(serial, 'capabilities', 'Updating capabilities.');
	}

	/* check if we have a newer */
	if (device.config.uuid > device.uuid)
		methods.configure(device);
	events.device(serial, 'connect', 'The device connected to the controller');
};

/**
 * a device disconnected
 */
export function disconnect(connection) {
	let serial = connection.data().serial;

	/* check if the device is connected */
	if (!devices[serial])
		return;

	/* mark the device as offline */
	devices[serial].connected = 0;
	devices[serial].id = 0;
	devices[serial].seen = time();
	delete devices[serial].connection;

	events.device(serial, 'disconnect', 'The device disconnected from the controller');
};

/**
 * helper for getting a device based on a connection
 */
export function get(serial) {
	if (!serial)
		return devices;

	return devices[serial];
};

/* glob the folder and load all files */
for (let info in fs.glob('/etc/urender/device/*')) 
	load(fs.basename(info));

/* register the ubus methods */
ubus.add('devices', function(req) { return devices; }, { device: "" });
