

source ${CLI_DIR}/includes/logging.sh
source ${CLI_DIR}/includes/common.sh


function check_moonraker_http {
	echo -n "GET / HTTP/1.0\r\n\r\n" | nc -w $((${MOONRAKER_TIMEOUT}*1000)) ${MOONRAKER_HOST} ${MOONRAKER_PORT}
}

function check_moonraker_api {
	nc -z -G ${MOONRAKER_TIMEOUT} ${MOONRAKER_HOST} ${MOONRAKER_PORT}
}

function check_server_ping {
	ping -c 20 -i 5 -t 5 -W 1 -o ${MOONRAKER_HOST}
}

function require_moonraker_http {
	check_moonraker_http &>/dev/null &
	local _pid=$!
	loader --pid $_pid --label "Checking moonraker HTTP response" --timeout 10 --hide
	wait $_pid
	local _ret=$?
	test $_ret != 0 && _fatal "Unable to connect to moonraker HTTP server" && exit $_ret
}

function require_moonraker_api {
	check_moonraker_api &>/dev/null &
	local _pid=$!
	loader --pid $_pid --label "Checking moonraker API port" --timeout 10 --hide 
	wait $_pid
	local _ret=$?
	test $_ret != 0 && _fatal "Unable to connect to moonraker API port" && exit $_ret
}

function require_moonraker_ping {
	check_server_ping &>/dev/null &
	local _pid=$!
	loader --pid $_pid --label "Checking moonraker ping" --timeout 10 --hide
	wait $_pid
	local _ret=$?
	test $_ret != 0 && _fatal "Unable to ping moonraker server" && exit $_ret
}

function get_ports_in_use {
	lsof -a -p ${CLI_PID}
}

function send_sighup_to_curl {
	#kill -HUP `lsof -t /tmp/socket`
	kill -HUP ${CLI_PID}
}