#!/usr/bin/env bats
# tests/parse_usbipd_state.bats - Tests for parse_usbipd_state function

load test_helper

@test "parse_usbipd_state: detects Attached state" {
    local line="2-16   24a9:205a  USB Mass Storage Device                                       Attached"
    result=$(parse_usbipd_state "$line")
    [ "$result" = "Attached" ]
}

@test "parse_usbipd_state: detects Shared state" {
    local line="2-15   058f:6387  USB Mass Storage Device                                       Shared"
    result=$(parse_usbipd_state "$line")
    [ "$result" = "Shared" ]
}

@test "parse_usbipd_state: detects Shared (forced) as Shared" {
    local line="2-15   058f:6387  USB Mass Storage Device                                       Shared (forced)"
    result=$(parse_usbipd_state "$line")
    [ "$result" = "Shared" ]
}

@test "parse_usbipd_state: detects Not shared state" {
    local line="2-6    0bda:555b  Integrated Webcam                                             Not shared"
    result=$(parse_usbipd_state "$line")
    [ "$result" = "NotShared" ]
}

@test "parse_usbipd_state: returns last word for unknown state" {
    local line="2-99   1234:5678  Unknown Device                                                 SomeState"
    result=$(parse_usbipd_state "$line")
    [ "$result" = "SomeState" ]
}
