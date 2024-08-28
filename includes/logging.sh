#!/usr/bin/env bash


#cwd=$(dirname "${BASH_SOURCE[0]}")


#source "${cwd}/common.sh"


source ${CLI_DIR}/includes/common.sh

declare _LOG_FORMAT='%b%-25s%b  %b%8s%b: %b%s%b\n'


#declare -r _LOG_FORMAT='%b%-25s%b  %b%8s%b: %b%s%b\n'
#declare -r _TIMESTAMP_FORMAT="%FT%R:%S.%3NZ"

# Just a simple timestamp function, used by log entries
#_ts(){
#	date +%s
#}

# Output an ISOTime style date string (taken from JS new Date().toISOString())
# eg: 2024-08-12T15:31:24.069Z
#_toISOtime() {
#	if test ! -t 0; then
#		parseDate=$(cat < /dev/stdin);
#	elif test -n "${1}"; then
#		parseDate="${1}";
#	else
#		gdate +"%FT%R:%S.%3NZ";
#		return 0;
#	fi;
#
#	gdate -d "${parseDate}" +"%FT%R:%S.%3NZ"
#}

#printf "%b%-12s%b  |  %b%12s%b\n" "\e[34;1m" "First col" "\e[0m" "\e[31;1m" "Second col" "\e[0m" 

# _error will only output if LOG_LEVEL is 1 or higher (or undefined)
# This can take an exit code as an optional 2nd parameter. If set,
# then `exit` will be called with that exit code
_error() {
	[[ ! ${LOG_LEVEL} || ${LOG_LEVEL} -ge ${CONST_LOGLVL_ERROR} ]] &&
		printf "${LOG_FORMAT:-${_LOG_FORMAT}}" "${_dim_}" $(_toISOtime) "${_xdim_}" "${_red_}" "ERROR" "${_none_}" "${_white_}" "$*" "${_none_}" 1>&2
		#printf "${LOG_FORMAT}" $(_ts) "${_yel_}ERROR${_none_}" "${1}" 1>&2

	[[ ${2} ]] && exit ${2}

	return 0
}

# _warn will only output if LOG_LEVEL is 2 or higher
_warn(){
	[[ ${LOG_LEVEL} && ${LOG_LEVEL} -ge ${CONST_LOGLVL_WARN} ]] &&
		printf "${LOG_FORMAT:-${_LOG_FORMAT}}" "${_dim_}" $(_toISOtime) "${_xdim_}" "${_dyel_}" "WARN" "${_none_}" "${_white_}" "$*" "${_none_}" 1>&2
	
	return 0
}

# _info will only output if LOG_LEVEL is 3 or higher
_info(){
	[[ ${LOG_LEVEL} && ${LOG_LEVEL} -ge ${CONST_LOGLVL_INFO} ]] &&
	printf "${LOG_FORMAT:-${_LOG_FORMAT}}" "${_dim_}" $(_toISOtime) "${_xdim_}" "${_blu_}" "INFO" "${_none_}" "${_white_}" "$*" "${_none_}" 1>&2

		#printf "${LOG_FORMAT}" $(_ts) "${_yel_}INFO${_none_}" "$@" 1>&2
	
	return 0
}

# _debug will only output if LOG_LEVEL is 4 or higher
_debug(){
	[[ ${LOG_LEVEL} && ${LOG_LEVEL} -ge ${CONST_LOGLVL_DEBUG} ]] && 
	printf "${LOG_FORMAT:-${_LOG_FORMAT}}" "${_dim_}" $(_toISOtime) "${_xdim_}" "${_orange_}" "DEBUG" "${_none_}" "${_white_}" "$*" "${_none_}" 1>&2
		#printf "${LOG_FORMAT}" $(_ts) "${_yel_}DEBUG${_none_}" "${1}" 1>&2

	return 0
}

_fatal() {
	#echo "Log format: ${LOG_FORMAT:-${_LOG_FORMAT}}"
	printf "${LOG_FORMAT:-${_LOG_FORMAT}}" "${_dim_}" $(_toISOtime) "${_xdim_}" "${_redb_}" "FATAL ERROR" "${_none_}" "${_white_}" "$*" "${_none_}" 1>&2
		#printf "${LOG_FORMAT}" $(_ts) "${_yel_}ERROR${_none_}" "${1}" 1>&2

	exit 1
}

declare -xg _error _warn _info _debug _fatal _ts _toISOtime