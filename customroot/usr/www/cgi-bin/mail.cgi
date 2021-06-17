#!/bin/sh

. common.sh
check_cookie

write_header "Mail Setup"

check_https

CONFF=/etc/msmtprc
CONFM=/etc/misc.conf

parse() {
	while read -r key value; do
		if test -n "$key" -a -n "$value" -a "${key###}" = "$key"; then
			if test "$key" = "password"; then
				password=$(httpd -e "$value")
			else
				eval "$key=\"$value\""
			fi
		fi
	done < $1
}

parse $CONFF

. $CONFM

if test -z "$MAILTO"; then MAILTO=$from; fi
if test -z "$from"; then distest="disabled"; fi

if test "$tls" = "on"; then tlsf=checked; fi
if test -z "$tls_starttls"; then tls_starttls="on"; fi
if test "$tls" = "on" -a "$tls_starttls" = "on"; then starttlsf=checked; fi

case "$auth" in
	on) auth_sel=selected;;
	off) anon_sel=selected; sipf=disabled;;
	plain) plain_sel=selected;;
	login) login_sel=selected;;
esac

cat<<-EOF
	<script type="text/javascript">
	function authh() {
		obj = document.getElementById("auth_id")
		opi = obj.selectedIndex
		opt = obj.options[opi].value
		value = false
		if (opt == "off")
			value = true
		document.getElementById("sip1").disabled = value
		document.getElementById("sip2").disabled = value
	}
	function startdis() {
		st = document.getElementById("tls_id").checked
		document.getElementById("start_id").disabled = ! st
	}
	</script>

	<form name=authf action=mail_proc.cgi method="post" >
	<fieldset>
	<legend>Mail Server</legend>
	
	<table>
	<tr><td>Server Name</td>
		<td><input type=text size=20 id=host name=host value="$host"></td></tr>
	<tr><td>Server Port</td>
		<td><input type=text size=5 id=port name=port value="$port"></td></tr>
	<tr><td>TLS/SSL</td><td><input type=checkbox $tlsf name=tls id="tls_id" value="on" onclick="startdis()"></td>
		 <td>startTLS</-td><td><input type=checkbox $starttlsf name=starttls id="start_id" value="on" onclick="startdis()"></td>
	</tr>
	
	<tr><td>Authentication</td><td>
	<select id="auth_id" name=auth onchange="authh()">
	<option $auth_sel value=on>On</option>
	<option $plain_sel value=plain>Plain</option>
	<option $login_sel value=login>Login</option>
	<option $anon_sel value=off>Anonymous</option>
	</select></td></tr>

	<tr><td>Username</td>
		<td><input type=text size=20 id=sip1 $sipf name=user value="$user"></td></tr>
	<tr><td>Password</td>
		<td><input type=password size=20 id=sip2 $sipf name=password value="$password"></td></tr>
	</table>
	</fieldset>
	
	<fieldset>
	<legend>Mail addresses</legend>
	<table>
	<tr><td>From</td>
		<td><input type=text size=20 name=from value="$from">
		Must be a valid e-mail</td><td></td></tr>

	<tr><td>To</td>
		<td><input type=text size=20 name=to value="$MAILTO">
		Must be a valid e-mail</td><td><input type=submit $distest name=submit value=Test></td></tr>
	</table>
	</fieldset>
	<p><input type=submit name=submit value=Submit>
	</form></body></html>
EOF
