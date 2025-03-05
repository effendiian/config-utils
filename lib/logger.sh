#!/usr/bin/env bash

##############################################################################################
# . lib/logger.sh
##############################################################################################
# Preamble: This is a library of functions that can be used to log messages to the console.
#           The functions are designed to be used in other scripts.
##############################################################################################

# Function for defining ANSI color codes.
__define_log_colors() {
    # Define ANSI color codes.
    export ANSI_RED='\033[0;31m'
    export ANSI_GREEN='\033[0;32m'
    export ANSI_YELLOW='\033[0;33m'
    export ANSI_BLUE='\033[0;34m'
    export ANSI_PURPLE='\033[0;35m'
    export ANSI_CYAN='\033[0;36m'
    export ANSI_WHITE='\033[0;37m'
    export ANSI_NC='\033[0m' # No Color
}

# Function for defining recognized log emojis.
# Defines emojis for INFO, SUCCESS, QUESTION, WARN, ERROR, DEBUG.
__define_log_emojis() {
    # Define log emojis.
    export LOG_EMOJI_INFO="📗"
    export LOG_EMOJI_SUCCESS="🟢"
    export LOG_EMOJI_QUESTION="❓"
    export LOG_EMOJI_WARN="🟡"
    export LOG_EMOJI_ERROR="🔴"
    export LOG_EMOJI_DEBUG="📘"
}

# Function for defining log configuration variables.
__define_log_configuration() {
    # Define the log level.
    export LOG_LEVEL=${LOG_LEVEL:-"INFO"}
    export LOG_SHOW_EMOJI=${LOG_SHOW_EMOJI:-"true"}
    export LOG_SHOW_TIMESTAMP=${LOG_SHOW_TIMESTAMP:-"true"}
    export LOG_SHOW_COLORS=${LOG_SHOW_COLORS:-"true"}
}

# Function for resolving the passed message based on the log configuration.
__resolve_message() {
    # Define the message.
    local message="$1"
    # Define the log level.
    local log_level="$2"
    # Define the log emoji.
    local log_emoji="$3"
    # Define the log color.
    local log_color="$4"

    # Define local variables.
    local current_date_time

    # Add the log emoji to the message.
    if [[ "${LOG_SHOW_EMOJI}" == "true" ]]; then 
        # If log_emoji is empty, then set the log emoji based on the log level.
        if [[ -z "${log_emoji}" ]]; then
            case $log_level in
            INFO)
                log_emoji="${LOG_EMOJI_INFO}"
                ;;
            WARN)
                log_emoji="${LOG_EMOJI_WARN}"
                ;;
            ERROR)
                log_emoji="${LOG_EMOJI_ERROR}"
                ;;
            DEBUG)
                log_emoji="${LOG_EMOJI_DEBUG}"
                ;;
            *)
                log_emoji=""
                ;;
            esac
        fi
        
        # Add the log emoji to the message.
        message="${log_emoji} ${message}"
    fi

    # Add the timestamp to the message.
    if [[ "${LOG_SHOW_TIMESTAMP}" == "true" ]]; then
        # Define the current date and time.
        current_date_time=$(date +"%Y-%m-%d %H:%M:%S")

        # Add the timestamp to the message.
        message="[${current_date_time}] ${message}"
    fi

    # Add the log color to the message.
    if [[ "${LOG_SHOW_COLORS}" == "true" ]]; then
        # If `log_color` is empty, set the log color based on the log level.
        if [[ -z "${log_color}" ]]; then
            case $log_level in
            INFO)
                log_color="${ANSI_GREEN}"
                ;;
            WARN)
                log_color="${ANSI_YELLOW}"
                ;;
            ERROR)
                log_color="${ANSI_RED}"
                ;;
            DEBUG)
                log_color="${ANSI_PURPLE}"
                ;;
            *)
                log_color=""
                ;;
            esac
        fi

        # If the `log_color` is not empty, then add the color to the message.
        if [[ ! -z "${log_color}" ]]; then
            message="${log_color}${message}${ASNI_NC}"
        fi
    fi

    # Return the resolved message.
    echo "${message}"
}

## PUBLIC INTERFACE

# Function for initializing the logger.
create_logger() {
    # Define ANSI color codes.
    __define_colors
    # Define log configuration variables.
    __define_log_configuration
    # Define log emojis.
    __define_log_emojis
}

get_log_level() {
    echo "${LOG_LEVEL}"
}

set_log_level() {
    local log_level="$1"

    # Validate the log level.
    if [[ ! "${log_level}" =~ ^(INFO|WARN|ERROR|DEBUG)$ ]]; then
        log "Invalid log level: ${log_level}. Valid log levels are INFO, WARN, ERROR, DEBUG." "ERROR"
        return 1
    fi

    # Define the log level.
    export LOG_LEVEL="${log_level}"
}

set_log_colors_enabled() {
    local log_colors_enabled="$1"

    # Validate the log colors enabled.
    if [[ ! "${log_colors_enabled}" =~ ^(true|false)$ ]]; then
        log "Invalid log colors enabled: ${log_colors_enabled}. Valid values are true or false." "ERROR"
        return 1
    fi

    # Define the log colors enabled.
    export LOG_SHOW_COLORS="${log_colors_enabled}"
}

set_log_emoji_enabled() {
    local log_emoji_enabled="$1"

    # Validate the log emoji enabled.
    if [[ ! "${log_emoji_enabled}" =~ ^(true|false)$ ]]; then
        log "Invalid log emoji enabled: ${log_emoji_enabled}. Valid values are true or false." "ERROR"
        return 1
    fi

    # Define the log emoji enabled.
    export LOG_SHOW_EMOJI="${log_emoji_enabled}"
}

select_log_emoji() {
    local log_emoji="$1"

    # Validate the log emoji.
    if [[ ! "${log_emoji}" =~ ^(INFO|SUCCESS|QUESTION|WARN|ERROR|DEBUG)$ ]]; then
        log "Invalid log emoji: ${log_emoji}. Valid log emojis are INFO, SUCCESS, QUESTION, WARN, ERROR, DEBUG." "ERROR"
        return 1
    fi

    # Define the log emoji.
    case $log_emoji in
    INFO)
        echo "${LOG_EMOJI_INFO}"
        ;;
    SUCCESS)
        echo "${LOG_EMOJI_SUCCESS}"
        ;;
    QUESTION)
        echo "${LOG_EMOJI_QUESTION}"
        ;;
    WARN)
        echo "${LOG_EMOJI_WARN}"
        ;;
    ERROR)
        echo "${LOG_EMOJI_ERROR}"
        ;;
    DEBUG)
        echo "${LOG_EMOJI_DEBUG}"
        ;;
    esac

    # No emoji found.
    return 0
}

# Function for logging a message to the console.
# Usage: log "message" "${LOG_LEVEL}" "${LOG_EMOJI_<EMOJI>}" "${ANSI_<COLOR>}"
log() {
    # Define the message.
    local message=$1
    # Define the log level.
    local log_level="${2:-${LOG_LEVEL}}"
    # Define the log emoji.
    local log_emoji="$3"
    # Define the log color.
    local log_color="$4"
    
    # Resolve the message based on the log configuration.
    message=$(__resolve_message "${message}" "${log_level}")

    # Route to stderr if the log level is ERROR.
    if [[ "${log_level}" == "ERROR" ]]; then
        echo "${message}" 1>&2
    else
        echo "${message}"
    fi
}
