#!/usr/bin/env bash

#USAGE arg "[file]" help="YAML configuration file to read from."
#USAGE flag "-s --schema <schema_file>" help="Schema file to validate the YAML configuration."
#USAGE flag "--quiet" help="Suppress all output." default="false"
#USAGE flag "-c --color" negate="--no-color" help="Use color in output." default="true"
#USAGE flag "-e --show-emoji" negate="--no-show-emoji" help="Use emoji icons in output." default="true"
#USAGE flag "-v --verbose <verbose>" help="Increase verbosity of output." default="0" {
#USAGE   choices "0" "1" "2" "3" "4"
#USAGE }

##############################################################################################
# mise make:env [FLAGS] [OPTIONS] [<file>]
##############################################################################################
# Preamble: This script generates a .env file from a YAML configuration file. It uses the
#           `yq` command-line tool to parse the YAML file and extract key-value pairs. The
#            generated .env file is used for environment variable configuration in a project.
##############################################################################################

set -e

# Compute the log level based on usage input.
get_log_level() {
    local quiet="${usage_quiet:-false}"
    local verbose="${usage_verbose:-0}"

    # If verbose and quiet are both unset, default quiet to false and verbose to 3.
    if [[ -z $quiet && -z $verbose ]]; then
        quiet=false
        verbose=3
    fi

    # If verbose > 0, then quiet is set to false.
    # This allows $verbose to take precedence over $quiet.
    if [[ $verbose -gt 0 ]]; then
        quiet=false
    fi

    # If quiet is set to true, then return "silent".
    if [[ $quiet == true ]]; then
        echo "silent"
        return
    fi

    # Otherwise, return the following log levels based on these values:
    # verbose >= 4: "debug"
    # verbose >= 3: "info"
    # verbose >= 2: "warn"
    # verbose >= 1: "error"
    # verbose == 0: "silent"
    if [[ $verbose -ge 4 ]]; then
        echo "debug"
    elif [[ $verbose -ge 3 ]]; then
        echo "info"
    elif [[ $verbose -ge 2 ]]; then
        echo "warn"
    elif [[ $verbose -ge 1 ]]; then
        echo "error"
    else
        echo "silent"
    fi
}

# Function to cleanup temporary files:
cleanup_temp_dir() {
    rm -rf "${TEMP_DIR}"
}

# Function to create temporary directory, with optional parameter for
# subdirectories:
create_temp_dir() {
    local subdir="$1"

    if [[ -n "$subdir" ]]; then
        mkdir -p "${TEMP_DIR}/${subdir}"
    else
        mkdir -p "${TEMP_DIR}"
    fi
}

# Function prefix with emoji if `--show-emoji` is true:
prefix_with_emoji() {
    local message="$1"
    local emoji="$2"

    # Check if --show-emoji is true.
    if [[ "${usage_show_emoji:-true}" == true ]]; then
        echo -e "${emoji} ${message}"
    else
        echo "$message"
    fi
}

# Function wrap with color code if `--color` is true:
wrap_with_color() {
    local message="$1"
    local color_code="$2"

    # Check if --color is true.
    if [[ "${usage_color:-true}" == true ]]; then
        # The `-e` option enables interpretation of backslash escapes.
        # The `\e[${color_code}m` sets the text color, and `\e[0m` resets the color.
        echo -e "\e[${color_code}m${message}\e[0m"
    else
        echo "$message"
    fi
}

# Function to print debug message to stdout with emoji icon prefix:
print_debug() {
    local message="$1"
    local log_level
    local color="35"
    local emoji="🔍"

    # Return 0 if log level is not debug.
    log_level=$(get_log_level)
    if [[ $log_level != "debug" ]]; then
        return 0
    fi

    # Prefix message with DEBUG.
    message="[DEBUG] $message"

    # Wrap message with color, if `--color` is true.
    # The `\e[31m` sets the text color to green.
    message=$(wrap_with_color "$message" "$color")
    
    # Prefix message with emoji, if `--show-emoji` is true.
    message=$(prefix_with_emoji "$message" "$emoji")

    # Print message.
    echo -e "$message" >&2
}

# Function to print info message to stdout with no emoji icon prefix:
print_info() {
    local message="$1"
    local log_level
    local color="34"
    local emoji="ℹ️"

    # Return 0 if log level is not info or debug.
    log_level=$(get_log_level)
    if [[ $log_level != "info" &&
         $log_level != "debug" ]]; then
        return 0
    fi

    # Wrap message with color, if `--color` is true.
    # The `\e[31m` sets the text color to green.
    message=$(wrap_with_color "$message" "$color")
    
    # Prefix message with emoji, if `--show-emoji` is true.
    message=$(prefix_with_emoji "$message" "$emoji")

    # Print message.
    echo -e "$message" >&2
}

# Function to print warning message to stderr with emoji icon prefix:
print_warning() {
    local message="$1"
    local log_level
    local color="33"
    local emoji="⚠️"

    # Return 0 if log level is not warn, info, or debug.
    log_level=$(get_log_level)
    if [[ $log_level != "warn" &&
         $log_level != "info" &&
         $log_level != "debug" ]]; then
        return 0
    fi

    # Wrap message with color, if `--color` is true.
    # The `\e[31m` sets the text color to green.
    message=$(wrap_with_color "$message" "$color")
    
    # Prefix message with emoji, if `--show-emoji` is true.
    message=$(prefix_with_emoji "$message" "$emoji")

    # Print message.
    # The `>&2` redirects the output to stderr.
    echo -e "$message" >&2
}

# Function to print error message to stderr with emoji icon prefix:
print_error() {
    local message="$1"
    local log_level
    local color="31"
    local emoji="❌"

    # Return 0 if log level is not error, warn, info, or debug.
    log_level=$(get_log_level)
    if [[  $log_level != "error" && 
        $log_level != "warn" && 
        $log_level != "info" && 
        $log_level != "debug" ]]; then
        return 0
    fi

    # Wrap message with color, if `--color` is true.
    # The `\e[31m` sets the text color to green.
    message=$(wrap_with_color "$message" "$color")
    
    # Prefix message with emoji, if `--show-emoji` is true.
    message=$(prefix_with_emoji "$message" "$emoji")

    # Print message.
    # The `>&2` redirects the output to stderr.
    echo -e "$message" >&2
}

# Function to print success message to stdout with emoji icon prefix:
print_success() {
    local message="$1"
    local log_level
    local color="32"
    local emoji="✅"

    # Return 0 if log level is not info or debug.
    log_level=$(get_log_level)
    if [[ $log_level != "info" &&
         $log_level != "debug" ]]; then
        return 0
    fi

    # Wrap message with color, if `--color` is true.
    # The `\e[31m` sets the text color to green.
    message=$(wrap_with_color "$message" "$color")
    
    # Prefix message with emoji, if `--show-emoji` is true.
    message=$(prefix_with_emoji "$message" "$emoji")

    # Print message.
    echo -e "$message"
}

# Function to ensure `yq` command is available (on MacOS and Linux):
ensure_yq_installed() {
    if ! command -v yq &> /dev/null; then
        print_error "yq could not be found. Please install it to proceed."
        exit 1
    fi
}

# Function to ensure `ajv-cli` command is available (on MacOS and Linux):
ensure_ajv_installed() {
    if ! command -v ajv &> /dev/null; then
        print_error "ajv-cli could not be found. Please install it to proceed."
        exit 1
    fi
}

# Function to check if dependencies are installed:
check_dependencies() {
    # Ensure `yq` and `ajv-cli` are installed:
    ensure_yq_installed || print_error "yq is not installed."
    ensure_ajv_installed || print_error "ajv-cli is not installed."
}

# Function to compile ajv schema (to ensure the schema is valid):
compile_ajv_schema() {
    local source_schema_file="$1"
    local compiled_schema_file

    # Create a local compiled_schema_file variable set to a temp_dir env.schema_YYYYMMDDTHHMMSS.js file:
    compiled_schema_file="${TEMP_DIR}/env.schema_$(date +%Y%m%dT%H%M%S).js"

    ajv compile -s "${source_schema_file}" -o "${compiled_schema_file}" && 
        print_success "Schema compiled successfully." 
}

# Function to validate configuration file against schema:
validate_config() {
    local source_env_file="$1"
    local source_schema_file="$2"

    ajv validate -s "$source_schema_file" -d "$source_env_file" >&2
}

# Function to read configuration from YAML file or return error if not found:
read_config() {
    local source_env_file="$1"

    if [[ ! -f "$source_env_file" ]]; then
        print_error "Error: Configuration file not found: $source_env_file"
        exit 1 # Return a non-zero status (simulating Go exit code)
    fi

    cat "$source_env_file"
}

# Function for the main script execution:
build_dotenv_from_yaml() {
    local source_env_file="${1}"
    local schema_file="${2}"

    # TODO: Add logic to build dotenv file from YAML configuration.
    # This is a placeholder for the actual implementation.
    # For example, you can use `yq` to extract key-value pairs and write them to a .env file.
    # yq eval '...' "$source_env_file" > .env
    # print_success "Built dotenv file from YAML configuration: $source_env_file"
}

# Function for flag input parsing and main execution:
run() {
    # Define control variables:
    local source_env_file=${usage_file:-${SOURCE_ENV_FILE}}
    local source_schema_file=${usage_schema:-${SOURCE_SCHEMA_FILE}}

    # Resolve default values.
    source_env_file=${source_env_file:-${CONFIG_DIR}/env.yaml}
    source_schema_file=${source_schema_file:-${CONFIG_DIR}/env.schema.yaml}

    # Check dependencies are installed:
    check_dependencies || {
        print_error "Dependencies are not installed. Please install them to proceed."
        exit 1
    }

    # Create temporary directory:
    create_temp_dir "${TEMP_DIR}" || {
        print_error "Failed to create temporary directory: ${TEMP_DIR}"
        exit 1
    }

    # TODO Add trap to cleanup temporary directory on exit.
    # trap cleanup_temp_dir EXIT

    # Validate and compile the schema file:
    compile_ajv_schema "$source_schema_file" || {
        print_error "Failed to compile schema file: ${source_schema_file}"
        exit 1
    }

    # Validate the configuration file:
    validate_config "$source_env_file" "$schema_file" || {
        print_error "Failed to validate configuration file: $source_env_file"
        exit 1
    }

    # Build the dotenv file(s) from the YAML configuration:
    build_dotenv_from_yaml "$source_env_file" "$source_schema_file" || {
        print_error "Failed to build dotenv file from YAML configuration: $source_env_file"
        exit 1
    }
}

# Run the script.
run "$@"