/* Copyright (C) 2022 John Crispin <john@phrozen.org> */

'use strict';

import * as device from 'uDevice.delegate';
import * as admin from 'uAdmin.delegate';
import * as ubus from 'uControl.ubus';
import * as ulog from 'ulog';

ulog.open('uControl', [ 'syslog', 'stderr' ]);

global.debug = 1;

ubus.publish();

export function onConnect(connection, protocols)
{
	let protocol;
	let delegate;

	if (('urender' in protocols)) {
		protocol = 'urender';
		delegate = device;
	} else if (('uadmin' in protocols)) {
		protocol = 'uadmin';
		delegate = admin;
	} else
		return connection.close(1003, 'Unsupported protocol requested');

	connection.data({
		counter: 0,
		n_messages: 0,
		n_fragments: 0,
		msg: '',
		delegate,
		... connection.peer(),
	});

	return delegate.onConnect(connection);
};

export function onData(connection, data, final)
{

	let ctx = connection.data();

	if (length(ctx.msg) + length(data) > 32 * 1024)
		return connection.close(1009, 'Message too big');

	ctx.msg = ctx.n_fragments ? ctx.msg + data : data;
	if (final) {
		ctx.n_messages++;
		ctx.n_fragments = 0;
	}
	else {
		ctx.n_fragments++;
		return;
	}

	return ctx.delegate.onData(connection, ctx.msg, final);
};

export function onClose(connection, code, reason)
{
	let ctx = connection.data();

	return ctx.delegate.onClose(connection, code, reason);
};


export function onRequest(request)
{
	request.data('');
};

export function onBody(request, data)
{
	request.data(request.data() + data);

	if (data == '') {
		request.reply({
			'Status': '200 OK',
			'Content-Type': 'text/plain',
		}, request.data() || 'no request data');
	}
};
