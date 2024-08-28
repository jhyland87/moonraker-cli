#!/usr/bin/env bash


# Simple confirmation prompt - Returns 0 if Y/y, and
# non-zero if anything other than Y/y.
confirm_action(){
  read -r -p "${1:-'Are you sure? [y/N]'}: " -n 1
  echo 
  [[ "$REPLY" =~ ^[Yy]$ ]]
}