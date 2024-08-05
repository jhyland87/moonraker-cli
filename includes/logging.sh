#!/usr/bin/env bash

# Just a simple timestamp function, used by log entries
_ts(){
	date +%s
}

#printf "%b%-12s%b  |  %b%12s%b\n" "\e[34;1m" "First col" "\e[0m" "\e[31;1m" "Second col" "\e[0m" 

# _error will only output if LOG_LEVEL is 1 or higher (or undefined)
# This can take an exit code as an optional 2nd parameter. If set,
# then `exit` will be called with that exit code
_error() {
	[[ ! ${LOG_LEVEL} || ${LOG_LEVEL} -ge ${CONST_LOGLVL_ERROR} ]] &&
		printf "${LOG_FORMAT}" "${_dim_}" $(_ts) "${_xdim_}" "${_red_}" "ERROR" "${_none_}" "${_white_}" "$*" "${_none_}" 1>&2
		#printf "${LOG_FORMAT}" $(_ts) "${_yel_}ERROR${_none_}" "${1}" 1>&2

	[[ ${2} ]] && exit ${2}

	return 0
}

# _warn will only output if LOG_LEVEL is 2 or higher
_warn(){
	[[ ${LOG_LEVEL} && ${LOG_LEVEL} -ge ${CONST_LOGLVL_WARN} ]] &&
		printf "${LOG_FORMAT}" "${_dim_}" $(_ts) "${_xdim_}" "${_dyel_}" "WARN" "${_none_}" "${_white_}" "$*" "${_none_}" 1>&2
	
	return 0
}

# _info will only output if LOG_LEVEL is 3 or higher
_info(){
	[[ ${LOG_LEVEL} && ${LOG_LEVEL} -ge ${CONST_LOGLVL_INFO} ]] &&
	printf "${LOG_FORMAT}" "${_dim_}" $(_ts) "${_xdim_}" "${_blu_}" "INFO" "${_none_}" "${_white_}" "$*" "${_none_}" 1>&2

		#printf "${LOG_FORMAT}" $(_ts) "${_yel_}INFO${_none_}" "$@" 1>&2
	
	return 0
}

# _debug will only output if LOG_LEVEL is 4 or higher
_debug(){
	[[ ${LOG_LEVEL} && ${LOG_LEVEL} -ge ${CONST_LOGLVL_DEBUG} ]] && 
	printf "${LOG_FORMAT}" "${_dim_}" $(_ts) "${_xdim_}" "${_orange_}" "DEBUG" "${_none_}" "${_white_}" "$*" "${_none_}" 1>&2
		#printf "${LOG_FORMAT}" $(_ts) "${_yel_}DEBUG${_none_}" "${1}" 1>&2

	return 0
}
