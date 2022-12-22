/* Copyright (C) 2022 John Crispin <john@phrozen.org> */

'use strict';

import * as fs from 'fs';

/**
 * load a devices config from the filesystem
 */
export function store(serial, config) {
	/* open the config file */
	let path = sprintf('/etc/urender/configs/%s', serial);
	let file = fs.open(path, 'w');

	/* check if we can write to the file (folder might be missing) */
	if (!file) {
		events.device(serial, 'error', 'Failed to store new configuration.');
		return false;
	}

	/* write the device config */
	events.device(serial, 'info', 'Stored new configuration.');
	file.write(config);
	file.close();

	return true;
};

/**
 * load a devices config from the filesystem
 */
export function load(serial, def) {
	/* open the state file */
	let path = sprintf('/etc/urender/configs/%s', def ? 'default' : serial);
	let file = fs.open(path, 'r');

	/* if load failed, then try loading the default config */
	if (!file && def) {
		return { uuid: 1 };

	/* if loading the config failed, try loading the default config */
	} else if (!file)
		return load(serial, 1);

	/* read the device config */
	let config = json(file.read('all'));
	file.close();

	/* if we loaded a default config store it to the fs */
	if (def) {
		/* make sure to set the uuid */
		config.uuid = time();
		store(serial, config);
	}

	config.uuid = time();

	return config;
};
