/* Copyright (C) 2022 John Crispin <john@phrozen.org> */

'use strict';

import * as ulog from 'ulog';
import * as ubus from 'ubus';

/**
 * the published methods
 */
let methods = {};

/*
 * the ubus context
 */
let uctx;

/**
 * publish the ubus object
 */
export function publish() {
	/* create the context */
	uctx = ubus.connect();
	if (!uctx) {
		ulog.error('failed to connect to ubus\n');
		return;
	}

	/* publish the methods */
	uctx.publish("urender", methods);
};

/**
 * add a method
 */
export function add(name, call, args) {
	/* store the method inside the dictionary*/
	methods[name] = {
		call,
		args: args || {},
	};
};
