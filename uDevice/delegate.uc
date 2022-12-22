/* Copyright (C) 2022 John Crispin <john@phrozen.org> */

'use strict';

import * as devices from 'uDevice.devices';
import * as notifications from 'uDevice.notifications';
import * as response from 'uDevice.response';
import * as reader from 'uReader.device_notification';
import * as events from 'uControl.events';

/**
 * handle an incoming RPC method call
 */
function handle_notification(connection, msg) {
	/* ignore all calls until we received a valid connect message */
	if (!connection.data().connected && msg.method != 'connect')
		return;

	/* check if a handler is available */
	let handler = notifications[msg.method];
	if (handler)
		/* call the handler */
		handler(connection, msg);
};

/**
 * handle an incoming RPC response call
 */
function handle_response(connection, msg) {
	/* ignore all calls until we received a valid connect message */
	if (!connection.data().connected)
		return;

	/* call the handler */
	response.handle(connection, msg);
};

/**
 * handle an incoming notification
 */
function handle(connection, msg) {
	/* its a notification */
	if (msg.method)
		return handle_notification(connection, msg);

	/* its a response */
	if (msg.result)
		return handle_response(connection, msg);
};

/**
 * a device sent a frame
 */
export function onData(connection, data, final)
{
	/* grab the connections context */
	let ctx = connection.data();

	try {
		/* we received a string, lets convert it to json */
		let rpc = json(data);
		events.debug(`received ${rpc}\n`);

		/* pipe the incoming data through the validation reader */
		let errors = [];
		let notification = reader.validate(rpc, errors);

		if (notification)
			/* the frame was sane, pass it on to the handler code */
			handle(connection, notification);
		else {
			/* somthing went wrong, log the error */
			events.device(ctx, serial, 'error', 'Received an invalid message.', errors);
			warn(`${errors}\n`);
		}
	} catch(e) {
		/* somthing went really wrong, log the exception*/
		events.device(ctx.serial, 'error', 'onData exception.', e);
		warn(`${e.stacktrace[0].context}\n`);
	}
};

export function onClose(connection, code, reason)
{
	/* mark the device as diconnected */
	devices.disconnect(connection);
};

export function onConnect(connection)
{
	/* no special handling */
	return connection.accept('urender');
};
