/* Copyright (C) 2022 John Crispin <john@phrozen.org> */

'use strict';

import * as fs from 'fs';

/**
 * store a device's capabilities to the filesystem
 */
export function store(serial, capabilities) {
	/* open the capabilities file */
	let path = sprintf('/etc/urender/capabilities/%s', serial);
	let file = fs.open(path, 'w');

	/* check if we can write to the file (folder might be missing) */
	if (!file) {
		events.device(serial, 'error', 'Failed to store new capabilities.');
		return;
	}

	/* write the device's capabilities */
	file.write(capabilities);
	file.close();
};

/**
 * load a device config from the filesystem
 */
export function load(serial) {
	/* open the state file */
	let path = sprintf('/etc/urender/capabilities/%s', serial);
	let file = fs.open(path, 'r');

	if (!file)
		return { uuid: 0 };

	/* read the device config */
	let capabilities = json(file.read('all'));
	file.close();

	return capabilities;
};
