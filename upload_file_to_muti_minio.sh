#!/bin/bash

# Upload a file to multiple minio servers for one client, and generate public access URL

# Usage: bash upload_file_to_muti_minio.sh <local-file-path> <bucket-name>/<path-in-bucket>

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

set -e

# Minio alias info, need to set alias firsly
MINIO_SERVER_NAMES=("env1" "env2" "env3")

# Environment variables
LOCAL_FILE="$1"
FILE_NAME=$(basename "$LOCAL_FILE")
BUCKET_PATH="$2"

# Check if the file exists on the Minio server
check_file_exists() {
    local server="$1"
    local bucket_path="$2"
    local file_name="$3"
    mc stat "$server/$bucket_path/$file_name" &>/dev/null
    return $?
}

# Upload file to Minio server
upload_file() {
    local server="$1"
    local local_file="$2"
    local bucket_path="$3"
    mc cp "$local_file" "$server/$bucket_path/" &>/dev/null
    return $?
}

# Check input parameters
if [ $# -ne 2 ]; then
    echo "Usage: $0 <local file path> <bucket or bucket/path (without '/' in the end)>"
    exit 1
fi

# Check if the local file exists
if [ ! -f "$LOCAL_FILE" ]; then
    echo "Error: Local file '$LOCAL_FILE' does not exist"
    exit 1
fi

# Check if the file exists on each Minio server
for server in "${MINIO_SERVER_NAMES[@]}"; do
    if check_file_exists "$server" "$BUCKET_PATH" "$FILE_NAME"; then
        echo "Error: File '$FILE_NAME' already exists in Minio '$server's '$BUCKET_PATH'"
        exit 1
    fi
done

# Upload file to each Minio server and generate public access URL
for server in "${MINIO_SERVER_NAMES[@]}"; do
    # Extract env information from server name for URL
    env=${server}
    url="http://minio.${env}.example.com"

    echo "Upload file to $server"
    
    # Upload file
    if upload_file "$server" "$LOCAL_FILE" "$BUCKET_PATH"; then
        # Check if the file is uploaded successfully
        if check_file_exists "$server" "$BUCKET_PATH" "$FILE_NAME"; then
            # Generate public URL
            public_url="${url}/${BUCKET_PATH}/${FILE_NAME}"
            
            echo "${server}:"
            echo "    File: ${FILE_NAME}"
            echo "    URL: ${public_url}"
        else
            echo "Error: Please check, the upload command executed successfully, but the file cannot be found in Minio '$server'"
        fi
    else
        echo "Error: The upload command executed failed, cannot upload file to Minio '$server'"
    fi
done

set +e
