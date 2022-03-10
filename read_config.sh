#!/bin/bash

# Fail on any error.
set -e

read_config_value() {
    (grep -E "^${2}=" -m 1 "${1}" 2>/dev/null || echo "VAR= INVALID_KEY") | head -n 1 | cut -d '=' -f 2-;
}
value=""
get_value() {
    value="$(read_config_value deps.cfg "${1}")";
}
