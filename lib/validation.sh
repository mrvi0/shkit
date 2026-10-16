#!/usr/bin/env bash
# Bash Library - Validation Module
# Provides validation functions for various data types

# Validation result constants
readonly VALIDATION_SUCCESS=0
readonly VALIDATION_ERROR=1

# Email validation regex
readonly EMAIL_REGEX='^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'

# URL validation regex
readonly URL_REGEX='^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/.*)?$'

# IPv4 validation regex
readonly IPV4_REGEX='^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'

# Check if string is empty
validation::is_empty() {
    local value="$1"
    [[ -z "$value" ]]
}

# Check if string is not empty
validation::is_not_empty() {
    local value="$1"
    [[ -n "$value" ]]
}

# Check if string contains only alphanumeric characters
validation::is_alphanumeric() {
    local value="$1"
    [[ "$value" =~ ^[a-zA-Z0-9]+$ ]]
}

# Check if string contains only alphabetic characters
validation::is_alphabetic() {
    local value="$1"
    [[ "$value" =~ ^[a-zA-Z]+$ ]]
}

# Check if string contains only numeric characters
validation::is_numeric() {
    local value="$1"
    [[ "$value" =~ ^[0-9]+$ ]]
}

# Check if value is a valid integer
validation::is_integer() {
    local value="$1"
    [[ "$value" =~ ^-?[0-9]+$ ]]
}

# Check if value is a valid positive integer
validation::is_positive_integer() {
    local value="$1"
    [[ "$value" =~ ^[0-9]+$ ]] && [[ "$value" -gt 0 ]]
}

# Check if value is a valid non-negative integer
validation::is_non_negative_integer() {
    local value="$1"
    [[ "$value" =~ ^[0-9]+$ ]]
}

# Check if value is a valid float
validation::is_float() {
    local value="$1"
    [[ "$value" =~ ^-?[0-9]+\.?[0-9]*$ ]] || [[ "$value" =~ ^-?[0-9]*\.?[0-9]+$ ]]
}

# Check if value is a valid positive float
validation::is_positive_float() {
    local value="$1"
    validation::is_float "$value" && (( $(echo "$value > 0" | bc -l) ))
}

# Check if value is a valid email address
validation::is_email() {
    local email="$1"
    [[ "$email" =~ $EMAIL_REGEX ]]
}

# Check if value is a valid URL
validation::is_url() {
    local url="$1"
    [[ "$url" =~ $URL_REGEX ]]
}

# Check if value is a valid IPv4 address
validation::is_ipv4() {
    local ip="$1"
    [[ "$ip" =~ $IPV4_REGEX ]]
}

# Check if value is a valid port number (1-65535)
validation::is_port() {
    local port="$1"
    validation::is_integer "$port" && [[ "$port" -ge 1 ]] && [[ "$port" -le 65535 ]]
}

# Check if value is a valid filename
validation::is_filename() {
    local filename="$1"
    [[ "$filename" =~ ^[a-zA-Z0-9._-]+$ ]] && [[ "$filename" != "." ]] && [[ "$filename" != ".." ]]
}

# Check if value is a valid directory name
validation::is_dirname() {
    local dirname="$1"
    [[ "$dirname" =~ ^[a-zA-Z0-9._-]+$ ]] && [[ "$dirname" != "." ]] && [[ "$dirname" != ".." ]]
}

# Check if value is a valid path
validation::is_path() {
    local path="$1"
    [[ "$path" =~ ^[a-zA-Z0-9._/-]+$ ]]
}

# Check if value is in range (inclusive)
validation::is_in_range() {
    local value="$1"
    local min="$2"
    local max="$3"
    
    validation::is_numeric "$value" && validation::is_numeric "$min" && validation::is_numeric "$max" && \
    [[ "$value" -ge "$min" ]] && [[ "$value" -le "$max" ]]
}

# Check if value matches regex pattern
validation::matches_pattern() {
    local value="$1"
    local pattern="$2"
    [[ "$value" =~ $pattern ]]
}

# Check if value has minimum length
validation::has_min_length() {
    local value="$1"
    local min_length="$2"
    [[ ${#value} -ge "$min_length" ]]
}

# Check if value has maximum length
validation::has_max_length() {
    local value="$1"
    local max_length="$2"
    [[ ${#value} -le "$max_length" ]]
}

# Check if value has exact length
validation::has_exact_length() {
    local value="$1"
    local length="$2"
    [[ ${#value} -eq "$length" ]]
}

# Check if value is in list
validation::is_in_list() {
    local value="$1"
    shift
    local list=("$@")
    
    for item in "${list[@]}"; do
        if [[ "$value" == "$item" ]]; then
            return $VALIDATION_SUCCESS
        fi
    done
    return $VALIDATION_ERROR
}

# Check if file exists
validation::file_exists() {
    local file="$1"
    [[ -f "$file" ]]
}

# Check if directory exists
validation::dir_exists() {
    local dir="$1"
    [[ -d "$dir" ]]
}

# Check if file is readable
validation::is_readable() {
    local file="$1"
    [[ -r "$file" ]]
}

# Check if file is writable
validation::is_writable() {
    local file="$1"
    [[ -w "$file" ]]
}

# Check if file is executable
validation::is_executable() {
    local file="$1"
    [[ -x "$file" ]]
}

# Validate with custom function
validation::custom() {
    local value="$1"
    local validator_func="$2"
    
    if declare -F "$validator_func" >/dev/null; then
        "$validator_func" "$value"
    else
        return $VALIDATION_ERROR
    fi
}

# Validate multiple conditions (AND)
validation::all() {
    local value="$1"
    shift
    local validators=("$@")
    
    for validator in "${validators[@]}"; do
        if ! "$validator" "$value"; then
            return $VALIDATION_ERROR
        fi
    done
    return $VALIDATION_SUCCESS
}

# Validate multiple conditions (OR)
validation::any() {
    local value="$1"
    shift
    local validators=("$@")
    
    for validator in "${validators[@]}"; do
        if "$validator" "$value"; then
            return $VALIDATION_SUCCESS
        fi
    done
    return $VALIDATION_ERROR
}

# Validate and return error message
validation::validate_with_message() {
    local value="$1"
    local validator="$2"
    local error_message="$3"
    
    if ! "$validator" "$value"; then
        echo "$error_message"
        return $VALIDATION_ERROR
    fi
    return $VALIDATION_SUCCESS
} 