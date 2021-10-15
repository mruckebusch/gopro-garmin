#!/usr/bin/env bash

#Description: prints a message, only if constant ERROR is set to 1
#Globals:
#Arguments: $* the strings to print
#Outputs: the message is shown to STDERR
#Returns:
function __msg_error {
    [[ "${ERROR}" == "1" ]] && echo -e "$(date '+%F %T.%3N') [ERROR] $*" 1>&2
}

#Description: prints a message, only if constant DEBUG is set to 1
#Globals:
#Arguments: $* the strings to print
#Outputs: the message is shown to STDERR
#Returns:
function __msg_debug {
    [[ "${DEBUG}" == "1" ]] && echo -e "$(date '+%F %T.%3N') [DEBUG] $*" 1>&2
}

#Description: prints message, only if constant WARN is set to 1
#Globals:
#Arguments: $* the strings to print
#Outputs: the message is shown to STDERR
#Returns:
function __msg_warn {
    [[ "${DEBUG}" == "1" ]] && echo -e "$(date '+%F %T.%3N') [WARN] $*" 1>&2
}

#Sets a nicer output for Bash set -o xtrace (a.k.a set -x)
#doc here https://wiki.bash-hackers.org/scripting/debuggingtips
# : information separator
# + the character repeated for multiple levels of expansion
# ${BASH_SOURCE[0]} the name of current script file file being sourced
# ${FUNCNAME[0]} the current function name
# ${LINENO} the line number
#Globals:
#Arguments:
#Outputs: $PS4 is written to STDOUT if xtrace mode is enabled
#Returns:
function _set_xtrace_ps4 {
    #PS4="+$(date '+%F %T.%3N'):${BASH_SOURCE[0]}:${LINENO}:${FUNCNAME[0]} "
    export PS4='+(${BASH_SOURCE}:${LINENO}):${FUNCNAME[0]:+${FUNCNAME[0]}():}'
}
