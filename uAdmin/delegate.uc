/* Copyright (C) 2022 John Crispin <john@phrozen.org> */

'use strict';

import * as reader from 'uReader.admin_method';
import * as methods from 'uAdmin.methods';
import * as notifications from 'uAdmin.notifications';
import * as events from 'uControl.events';

/**
 * track active admin sessions
 */

let admins = {};

/**
 * handle an incoming RPC method call
 */
function handle_method(connection, msg) {
	/* ignore all calls until we received a valid connect message */
//	if (!connection.data().connected && msg.method != 'connect')
//		return;

	/* check if a handler is available */
	let handler = methods[msg.method];
	if (handler)
		/* call the handler */
		handler(connection, msg);
};

/**
 * handle an incoming notification
 */
function handle(connection, msg) {
	if (msg.method)
		return handle_method(connection, msg);
};

export function onData(connection, data, final) {
	let ctx = connection.data();

	try {
		let rpc = json(data);
		events.debug(`received ${rpc}\n`);

		let errors = [];
		let notification = reader.validate(rpc, errors);

		if (notification)
			handle(connection, notification);
		else {
			events.admin(ctx.ip, 'error', 'Received an invalid message.');
			warn(`${errors}\n`);
		}
	} catch(e) {
		events.admin(ctx.ip, 'error', ' onData exception.', e);
		warn(`${e.stacktrace[0].context}\n`);
		return;
	}
};

export function onClose(connection, code, reason) {
	/* stop tracking the connection */
	let peer = connection.peer();
	delete admins[`${peer.ip}:${peer.port}`];
};

export function onConnect(connection) {
	/* start tracking the connection */
	let peer = connection.peer();
	admins[`${peer.ip}:${peer.port}`] = connection;

	return connection.accept('uadmin');
};

/* broadcast an event to all connected admin sessions */
export function event(event) {
	for (let k, admin in admins)
		notifications.event(admin, event);
};

/* register the event handler */
events.register(event);
