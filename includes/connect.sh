

source ${CLI_DIR}/includes/logging.sh

function check_moonraker_port {
	# nc -z -G 5 192.168.0.96 7125
	nc -z -G ${MOONRAKER_TIMEOUT} ${MOONRAKER_HOST} ${MOONRAKER_PORT} &>/dev/null

	#nc -G 5 -z 192.168.0.96 7125
}


# echo -n "GET / HTTP/1.0\r\n\r\n" | nc host.example.com 80

function check_moonraker_http {
	#echo -n "GET / HTTP/1.0\r\n\r\n" | nc -w 1000 192.168.0.96 7125


	echo -n "GET / HTTP/1.0\r\n\r\n" | nc -w $((${MOONRAKER_TIMEOUT}*1000)) ${MOONRAKER_HOST} ${MOONRAKER_PORT}  &>/dev/null
}


function check_server_ping {
	ping -c 20 -i 5 -t 5 -W 1 -o ${MOONRAKER_HOST} | jc --ping
}

function get_ports_in_use {
	lsof -a -p ${CLI_PID}
}

function send_sighup_to_curl {
	#kill -HUP `lsof -t /tmp/socket`
	kill -HUP ${CLI_PID}
}

function require_moonraker_connect(){
	check_moonraker_port 
	test $? != 0 && _fatal "Unable to connect to moonraker" && exit 1
}

function require_moonraker_ping {
	ping -c 20 -i 5 -t 5 -W 1 -o ${MOONRAKER_HOST} 1>&2

	test $? != 0 && _fatal "Unable to connect to moonraker" && exit 1
}