#!/usr/bin/env bats

@test "Moonraker printer status" {
  result="$(moonraker printer test 1>/dev/null)"
  [ -z "$result" ]
}

@test "Moonraker bed mesh" {
  result="$(moonraker bed mesh 1>/dev/null)"
  [ -z "$result" ]
}

@test "Moonraker file list" {
  result="$(moonraker file list 1>/dev/null)"
  [ -z "$result" ]
}

@test "Moonraker status temps" {
  result="$(moonraker status temps 1>/dev/null)"
  [ -z "$result" ]
}