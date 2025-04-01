#! /bin/bash

log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error_then_exit() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" && exit 1
}

create_dir_safe() {
    if [[ ! -d "$1" ]]; then
        mkdir -p "$1" || echo "Could't create dir: $1"
    else
        echo "Dir alread exist: $1"
    fi
}

create_file_safe() {
    if [[ ! -f "$1" ]]; then
        touch "$1" || echo "Could't create file: $1"
    else
        echo "File alread exist: $1"
    fi
}
