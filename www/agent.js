
function get_appropriate_ws_url(extra_url)
{
	var pcol;
	var u = document.URL;

	/*
	 * We open the websocket encrypted if this page came on an
	 * https:// url itself, otherwise unencrypted
	 */

	if (u.substring(0, 5) === "https") {
		pcol = "wss://";
		u = u.substr(8);
	} else {
		pcol = "ws://";
		if (u.substring(0, 4) === "http")
			u = u.substr(7);
	}

	u = u.split("/");

	/* + "/xxx" bit is for IE10 workaround */

	return pcol + u[0] + "/" + extra_url;
}

function new_ws(urlpath, protocol)
{
	return new WebSocket(urlpath, protocol);
}

function trace_add(msg)
{
	document.getElementById("trace").value =
		document.getElementById("trace").value + msg + '\n';
	document.getElementById("trace").scrollTop =
		document.getElementById("trace").scrollHeight;
}

document.addEventListener("DOMContentLoaded", function() {

	var ws = new_ws(get_appropriate_ws_url("urender"), "urender");
	try {
		ws.onmessage = function(msg) {
			trace_add(msg.data);

			var j = JSON.parse(msg.data);
			if (j?.event?.log)
				log_add(j.event.log[0], j.event.log[1]);
			if (j?.logdump) {
				for (var i in j.logdump) {
					var log = j.logdump[i];
					log_add(log[0], log[1]);
				}
			}
		};

		ws.onopen = function() {
		},

		ws.onclose = function(){
		};
	} catch(exception) {
		alert("<p>Error " + exception);
	}

	function sendmsg(msg) {
		msg = JSON.stringify(msg);
		trace_add(msg);
		ws.send(msg);
	}

	function sendconnect()
	{
		sendmsg({
			jsonrpc: '2.0',
			method: 'connect',
			params: {
				serial: document.getElementById("serial").value,
				uuid: 1,
				firmware: 'urender 1.0',
				capabilities: { uuid: 123 }
			}
		});
	}
	document.getElementById("connect").addEventListener("click", sendconnect);

function sendstate()
	{
		sendmsg({
			jsonrpc: '2.0',
			method: 'state',
			params: {
				online: true
			}
		});
	}
	document.getElementById("state").addEventListener("click", sendstate);

	document.getElementById("trace").value = '';
}, false);
