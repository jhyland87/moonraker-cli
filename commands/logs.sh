#!/usr/bin/env bash

if [[ $1 == '--description' ]]; then
	echo "Log related commands"
	exit 
fi

# https://blog.kellybrazil.com/2020/01/15/silly-terminal-plotting-with-jc-jq-and-jp/



#echo "[print] CLI_DIR: ${CLI_DIR}"
source ${CLI_DIR}/includes/common.sh
source ${CLI_DIR}/includes/colors.sh
source ${CLI_DIR}/includes/logging.sh
source ${CLI_DIR}/includes/prompts.sh
source ${CLI_DIR}/includes/connect.sh

__module_path=$(realpath "${BASH_SOURCE[0]}") # /absolute/path/to/module/file.sh
__module_dir=$(dirname "${__module_path}") # /absolute/path/to/module
__module_file=$(basename ${__module_path}) # file.sh
__module_name=${__module_file%%.sh} # file
