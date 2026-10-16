#!/usr/bin/env bash
# Bash Library - Logging Module
# Provides logging functions with different levels and formats

# Log levels
readonly LOG_LEVEL_DEBUG=0
readonly LOG_LEVEL_INFO=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_ERROR=3
readonly LOG_LEVEL_FATAL=4

# Default log level
LOG_LEVEL=${LOG_LEVEL:-$LOG_LEVEL_INFO}

# Log file (optional)
LOG_FILE=${LOG_FILE:-}

# Timestamp format
LOG_TIMESTAMP_FORMAT=${LOG_TIMESTAMP_FORMAT:-"%Y-%m-%d %H:%M:%S"}

# Get current timestamp
logging::timestamp() {
    date "+${LOG_TIMESTAMP_FORMAT}"
}

# Get log level name
logging::level_name() {
    local level="$1"
    case "$level" in
        $LOG_LEVEL_DEBUG) echo "DEBUG" ;;
        $LOG_LEVEL_INFO)  echo "INFO"  ;;
        $LOG_LEVEL_WARN)  echo "WARN"  ;;
        $LOG_LEVEL_ERROR) echo "ERROR" ;;
        $LOG_LEVEL_FATAL) echo "FATAL" ;;
        *)               echo "UNKNOWN" ;;
    esac
}

# Get log level color
logging::level_color() {
    local level="$1"
    case "$level" in
        $LOG_LEVEL_DEBUG) echo "$CYAN" ;;
        $LOG_LEVEL_INFO)  echo "$BLUE" ;;
        $LOG_LEVEL_WARN)  echo "$YELLOW" ;;
        $LOG_LEVEL_ERROR) echo "$RED" ;;
        $LOG_LEVEL_FATAL) echo "$BOLD_RED" ;;
        *)               echo "$NC" ;;
    esac
}

# Write log message
logging::write() {
    local level="$1"
    local message="$2"
    local timestamp=$(logging::timestamp)
    local level_name=$(logging::level_name "$level")
    local log_entry="[${timestamp}] [${level_name}] ${message}"
    
    # Check if we should log this level
    if [[ "$level" -ge "$LOG_LEVEL" ]]; then
        # Write to stderr with colors
        if colors::is_supported; then
            local color=$(logging::level_color "$level")
            echo -e "${color}${log_entry}${NC}" >&2
        else
            echo "$log_entry" >&2
        fi
        
        # Write to log file if specified
        if [[ -n "$LOG_FILE" ]]; then
            echo "$log_entry" >> "$LOG_FILE"
        fi
    fi
}

# Debug log
logging::debug() {
    logging::write $LOG_LEVEL_DEBUG "$1"
}

# Info log
logging::info() {
    logging::write $LOG_LEVEL_INFO "$1"
}

# Warning log
logging::warn() {
    logging::write $LOG_LEVEL_WARN "$1"
}

# Error log
logging::error() {
    logging::write $LOG_LEVEL_ERROR "$1"
}

# Fatal log (and exit)
logging::fatal() {
    logging::write $LOG_LEVEL_FATAL "$1"
    exit 1
}

# Set log level
logging::set_level() {
    local level="$1"
    case "$level" in
        debug|DEBUG) LOG_LEVEL=$LOG_LEVEL_DEBUG ;;
        info|INFO)   LOG_LEVEL=$LOG_LEVEL_INFO  ;;
        warn|WARN)   LOG_LEVEL=$LOG_LEVEL_WARN  ;;
        error|ERROR) LOG_LEVEL=$LOG_LEVEL_ERROR ;;
        fatal|FATAL) LOG_LEVEL=$LOG_LEVEL_FATAL ;;
        *)          logging::error "Invalid log level: $level" ;;
    esac
}

# Set log file
logging::set_file() {
    LOG_FILE="$1"
    # Create directory if it doesn't exist
    local dir=$(dirname "$LOG_FILE")
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
    fi
}

# Log function entry
logging::enter() {
    local func_name="$1"
    logging::debug "Entering function: $func_name"
}

# Log function exit
logging::exit() {
    local func_name="$1"
    local exit_code="${2:-0}"
    if [[ "$exit_code" -eq 0 ]]; then
        logging::debug "Exiting function: $func_name (success)"
    else
        logging::debug "Exiting function: $func_name (error: $exit_code)"
    fi
}

# Log command execution
logging::exec() {
    local cmd="$*"
    logging::debug "Executing: $cmd"
    "$@"
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        logging::error "Command failed (exit code: $exit_code): $cmd"
    fi
    return $exit_code
}

# Log with context
logging::with_context() {
    local context="$1"
    local level="$2"
    local message="$3"
    logging::write "$level" "[$context] $message"
}

# Initialize logging (call this after sourcing colors.sh)
logging::init() {
    # Source colors module if not already sourced
    if ! declare -F colors::is_supported >/dev/null; then
        if [[ -f "${BASH_SOURCE%/*}/colors.sh" ]]; then
            source "${BASH_SOURCE%/*}/colors.sh"
        fi
    fi
} 