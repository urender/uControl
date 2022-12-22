/* Copyright (C) 2022 John Crispin <john@phrozen.org> */

'use strict';

/**
 * send the actual command after verifying it with the reader
 */
function jsonrpc(connection, method, params) {
	/* prepare the actual jsonrpc message */
	let rpc = {
		jsonrpc: '2.0',
		method,
		params,
	};

	/* send the reply */
	connection.send(`${rpc}`);
}

/**
 * Send an event to an admin session
 */
export function event(connection, event) {
	jsonrpc(connection, 'event', event);
};
