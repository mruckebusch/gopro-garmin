#!/usr/bin/env bash

# displays the sorted-list of days (time of last modification)
#of files in a directory
function _list_days_files_in_dir {
    local directory
    directory="$1"
    stat --format=%y "${directory}"/* | cut -d ' ' -f1 | sort | uniq
}


#Converts a decimal number into a base36 number (alphabet 0-9A-Z)
#$1 decimal number to convert
#Output on STDOUT its base36 equivalent
function __decimal_to_base36 {
    local base36
    #shellcheck disable=SC2207
    base36=($(echo {0..9} {A..Z}))
    for i in $(bc <<< "obase=36; $1"); do
        echo -n "${base36[$(( 10#$i ))]}"
    done && echo
}


#displays fit filenames with names that match date
# follows this logic:
# https://zerobin.net/?b2bfb1be32a4dc12#5bHF9ub81tJK1bDCifGJJvGHjd2uM0/A/efXEouWzyo=
# $1 directory of fit files
# $2 the date with format yyyy-MM-dd
function _get_fit_files_with_date {
    local directory
    directory="$1"
    local date
    date="$2"
    local char1_year
    char1_year="${date:2:2}"
    char1_year=$((char1_year-10))
    char1_year=$(__decimal_to_base36 "${char1_year}")
    local char2_month
    char2_month=$(__decimal_to_base36 "${date:5:2}")
    local char3_daynr
    char3_daynr=$(__decimal_to_base36 "${date:8:2}")
    local pattern
    pattern="${char1_year}${char2_month}${char3_daynr}*"
    find "${directory}" -name "${pattern}"
}

#Displays the list of files ordered by modification_date ascending
# $1 the directory in which files are located
#Output STDOUT one line per file path
function __get_files_modified_asc {
    local directory
    directory="$1"
    #option --format=%y,%n generates a CSV with modification date,filename (with dir)
    stat --format='%y,%n' "${directory}"/*   \
    | sort                               \
    | cut -d ',' -f2 #suppress dates from the output, only show filenames
}



#Displays clip filenames with dates that match the input date
# $1 directory of clip files
# $2 the date with format yyyy-MM-dd
function _get_clip_files_with_date {
    local directory
    directory="$1"
    local date
    date="$2"

    local ret
    ret=""

    for clip in $(__get_files_modified_asc "$directory"); do
        local start_day
        start_day=$(__get_clip_start_date_iso "${clip}")

        if [ "${start_day}" = "${date}" ]; then
            ret+="${clip} "
        fi
    done
    echo "${ret}"
}


function _verify_dependencies {
    for dependency in ${DEPENDENCIES}; do
    if ! command -v "${dependency}" &> /dev/null
    then
        __msg_error "dependency ${dependency} could not be found"; exit 1
    fi
    done
}



function _is_garmin_mounted {
    if ! [[ -d ${GPS_LOGS_FOLDER} ]]; then
    __msg_debug "unable to find garmin directory"
    return 1
    else
    return 0
    fi
}

#Removes BOM character from a UTF-8 file
# BOM means Byte order mark
# see doc here https://en.wikipedia.org/wiki/Byte_order_mark
#
#$1 the input file from which BOM must be removed
#Output to STDOUT the content of the file, BOM removed
function ___remove_BOM {
    sed -i '1s/^\xEF\xBB\xBF//' "$1"
}

#Removes the 1st line of a file and write it to a new file named $1_noheader
#Globals:
#Arguments: $1 the input file
#Outputs:
#Returns: the return value of tail
function __remove_header {
    tail -n +2 "$1" >| "${1}_noheader"
}

#Traps any exit signals SIGHUP SIGINT SIGQUIT SIGABRT SIGTERM
#and cleans up temporary files
# SIGHUP (“hang-up”) is used to report that the user’s terminal is disconnected,
# SIGINT (“program interrupt”) is sent when the user types the INTR character (normally C-c)
# SIGQUIT is similar to SIGINT, except that it’s controlled by a different key
#  the QUIT character, usually C-\—
#  and produces a core dump when it terminates the process
# SIGABRT is commonly used by libc and other libraries to abort the program in case of
# critical errors.
# SIGTERM is a generic signal used to cause program termination.
#  Unlike SIGKILL, this signal can be blocked, handled, and ignored.
#  It is the normal way to politely ask a program to terminate.
#  The shell command kill generates SIGTERM by default.
#Globals:
#Arguments:
#Outputs:
#Returns:
function exit_trap {
#TODO uncomment exit_trap rm -rf "${WORKING_FOLDER}"
#    rm -rf "${WORKING_FOLDER}"
    exit
}

#Traps ERR fake signal (A command returning a non-zero exit status)
# and display the command name and exit status
#Globals:
#Arguments:
#Outputs: on STDERR the command name and exit code
#Returns true (echo return code)
function err_trap {
    #TODO test err_trap
    local exit_status="$?"
    echo "ERROR: Command exited with status ${exit_status}."
    exit "${exit_status}"
}
