/* Copyright (C) 2022 John Crispin <john@phrozen.org> */

'use strict';

import * as ulog from 'ulog';

let handlers = [];

/* broadcast a event to all registered handlers */
function broadcast(event) {
	for (let handler in handlers)
		handler(event);
}

/* allow a module to register an event handler */
export function register(handler) {
	push(handlers, handler);
};

/* generate a device event */
export function device(serial, type, event, payload) {
	let msg = {
		type: 'device.' + type,
		serial,
		event,
		when: time(),
	};
	if (payload)
		msg.payload = payload;
	ulog.info(`${serial}: ${event}\n`);
	broadcast(msg);
};

/* generate an admin event */
export function admin(client, type, event, payload) {
	let msg = {
		type: 'admin.' + type,
		client,
		event,
		when: time(),
	};
	if (payload)
		msg.payload = payload;
	ulog.info(`${client}: ${event}\n`);
	broadcast(msg);
};

/* log a debug message */
export function debug(msg) {
	if (global.debug)
		ulog.info(msg);
};

