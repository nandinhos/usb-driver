#!/usr/bin/env bats
# tests/security_and_json.bats - Security validation and JSON contract tests

load test_helper

@test "validate_busid accepts standard BUSIDs" {
    run validate_busid "2-16"
    [ "$status" -eq 0 ]
    run validate_busid "1-2.3"
    [ "$status" -eq 0 ]
}

@test "validate_busid rejects command injection payloads" {
    run validate_busid "1-1; calc.exe"
    [ "$status" -ne 0 ]
    run validate_busid '2-4$(whoami)'
    [ "$status" -ne 0 ]
    run validate_busid ""
    [ "$status" -ne 0 ]
}

@test "sanitize_mount_name strips slashes and rejects dot-dot" {
    result=$(sanitize_mount_name "../../etc" "fallback")
    [[ "$result" != *"/"* ]]
    result_dot=$(sanitize_mount_name ".." "usb-2-4")
    [ "$result_dot" = "usb-2-4" ]
}

@test "load_safe_config ignores arbitrary shell execution" {
    local tmp_cfg marker
    tmp_cfg=$(mktemp)
    marker="/tmp/usb_driver_test_pwn_$$"
    rm -f "$marker"
    printf 'MOUNT_POINT="/mnt/usb-driver"\n$(touch %s)\n' "$marker" > "$tmp_cfg"
    load_safe_config "$tmp_cfg"
    rm -f "$tmp_cfg"
    [ ! -e "$marker" ]
    [ "$MOUNT_POINT" = "/mnt/usb-driver" ]
}

@test "json_escape escapes quotes and backslashes" {
    result=$(json_escape 'a"b\c')
    [ "$result" = 'a\"b\\c' ]
}

@test "CLI --simulate --json endpoints return valid JSON" {
    for cmd in check list status up down; do
        out=$("$PROJECT_ROOT/bin/usb-driver" --simulate --json "$cmd")
        node -e 'JSON.parse(process.argv[1])' "$out"
    done
}

@test "CLI --json attach rejects invalid BUSID" {
    run "$PROJECT_ROOT/bin/usb-driver" --json attach "1-1; calc.exe"
    [ "$status" -ne 0 ]
    [[ "$output" == *'"ok":false'* ]]
}
