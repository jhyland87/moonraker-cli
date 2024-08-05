#!/usr/bin/env bash

confirm_action(){
  read -r -p "${1:-'Are you sure? [y/N]'}" -n 1
  echo 
  [[ "$REPLY" =~ ^[Yy]$ ]]
}