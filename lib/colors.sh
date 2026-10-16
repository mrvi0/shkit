#!/usr/bin/env bash
# Bash Library - Colors Module
# Provides color constants and functions for terminal output

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Bold colors
readonly BOLD_RED='\033[1;31m'
readonly BOLD_GREEN='\033[1;32m'
readonly BOLD_YELLOW='\033[1;33m'
readonly BOLD_BLUE='\033[1;34m'
readonly BOLD_PURPLE='\033[1;35m'
readonly BOLD_CYAN='\033[1;36m'

# Background colors
readonly BG_RED='\033[41m'
readonly BG_GREEN='\033[42m'
readonly BG_YELLOW='\033[43m'
readonly BG_BLUE='\033[44m'
readonly BG_PURPLE='\033[45m'
readonly BG_CYAN='\033[46m'

# Check if colors are supported
colors::is_supported() {
    [[ -t 1 ]] && [[ -n "$TERM" ]] && [[ "$TERM" != "dumb" ]]
}

# Print colored text
colors::print() {
    local color="$1"
    local text="$2"
    
    if colors::is_supported; then
        echo -e "${color}${text}${NC}"
    else
        echo "$text"
    fi
}

# Success message (green)
colors::success() {
    colors::print "$GREEN" "$1"
}

# Error message (red)
colors::error() {
    colors::print "$RED" "$1"
}

# Warning message (yellow)
colors::warning() {
    colors::print "$YELLOW" "$1"
}

# Info message (blue)
colors::info() {
    colors::print "$BLUE" "$1"
}

# Debug message (cyan)
colors::debug() {
    colors::print "$CYAN" "$1"
}

# Highlight text (bold)
colors::highlight() {
    colors::print "$WHITE" "$1"
}

# Print with background
colors::print_bg() {
    local bg_color="$1"
    local text="$2"
    
    if colors::is_supported; then
        echo -e "${bg_color}${text}${NC}"
    else
        echo "$text"
    fi
}

# Print colored text without newline
colors::print_n() {
    local color="$1"
    local text="$2"
    
    if colors::is_supported; then
        echo -ne "${color}${text}${NC}"
    else
        echo -n "$text"
    fi
}

# Progress bar
colors::progress_bar() {
    local current="$1"
    local total="$2"
    local width="${3:-50}"
    local label="${4:-Progress}"
    
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    local bar=""
    for ((i=0; i<filled; i++)); do
        bar+="█"
    done
    for ((i=0; i<empty; i++)); do
        bar+="░"
    done
    
    colors::print_n "$CYAN" "\r${label}: [${bar}] ${percentage}%"
    
    if [[ "$current" -eq "$total" ]]; then
        echo
    fi
} 