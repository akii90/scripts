#! /bin/bash

# Color define
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'

# Reset, no color
RESET='\033[0m'

# Color print function
color_print() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${RESET}"
}

# Test color print
color_print "${RED}" "Red content"
color_print "${GREEN}" "Green content"
color_print "${YELLOW}" "Yellow content"
color_print "${BLUE}" "Blue content"
color_print "${MAGENTA}" "Magenta content"
color_print "${CYAN}" "Cyan content"