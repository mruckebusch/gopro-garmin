#!/usr/bin/env bash

#Converts a UNIX timestamp to Garmin timestamp
#Globals:
#Arguments: $1 the UNIX timestamp
#Outputs: the Gamin timestamp
#Returns:
function __unix_to_garmin_ts {
    local unix_timestamp
    unix_timestamp="$1"
    if [[ -z "${SECONDS_BETWEEN_UNIX_AND_GARMIN_EPOCH}" ]] ; then
    __msg_error "unbound var SECONDS_BETWEEN_UNIX_AND_GARMIN_EPOCH"
    exit 1
    fi
    echo $((unix_timestamp - SECONDS_BETWEEN_UNIX_AND_GARMIN_EPOCH))
}

#Converts the date passed in arg into seconds since UNIX Epoch
#Globals:
#Arguments: $1 the date to convert, with following format: 2021-08-12T08:18:47.000000Z
#Outputs: STDOUT int number (should be positive)
#Returns:
function ___date_to_seconds {
    date --date "$1" '+%s'
}
