#! /bin/bash

# Logs
info()
{
    echo '[INFO] ' "$@"
}
warn()
{
    echo '[WARN] ' "$@" >&2
}
fatal()
{
    echo '[ERROR] ' "$@" >&2
    exit 1
}

# Create dir and file 
create_dir() {
    if [[ ! -d "$1" ]]; then
        mkdir -p "$1" || echo "Could't create dir: $1"
    else
        echo "Dir alread exist: $1"
    fi
}
create_file() {
    if [[ ! -f "$1" ]]; then
        touch "$1" || echo "Could't create file: $1"
    else
        echo "File alread exist: $1"
    fi
}
