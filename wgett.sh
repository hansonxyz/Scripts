#!/bin/bash

# Help text
if [ $# -eq 0 ]; then
    echo "Usage: $0 <torrent_file> [aria2c additional options]"
    echo "Download a torrent file similar to how wget functions."
    echo "aria2c is required to be installed."
    exit 1
fi

TORRENT_FILE=$@

# Create a temporary log file
LOG_FILE=$(mktemp)

# Ensure the log file is removed on script exit
cleanup() {
    rm -f "$LOG_FILE"
}
trap cleanup EXIT

# Run aria2c with logging directed to the temporary file
aria2c --rpc-save-upload-metadata=false --listen-port=6921 --dht-listen-port=6922 --seed-time=0 $TORRENT_FILE --log="$LOG_FILE" --log-level=info

# Check the log file for specific output and act accordingly
while true; do
    if grep -q "Failed to bind a socket, cause: Address already in use" "$LOG_FILE"; then
        echo "Port in use, retrying without specific ports..."
        # Clear the log file for the next attempt
        rm "$LOG_FILE"
        LOG_FILE=$(mktemp) # Recreate the log file
        sleep 5
        # Retry the command without port specification
        aria2c --rpc-save-upload-metadata=false --seed-time=0 "$TORRENT_FILE" --log="$LOG_FILE" --log-level=info
    else
        echo "Download attempt completed."
        break
    fi
done

# Initialize a flag to track download success
download_success=1

# Check for "Download complete" to set the success flag
if grep -q "not complete" "$LOG_FILE"; then
    download_success=0
fi

# Always attempt to clean up .torrent and .aria2 files
grep -oP "(?<=Download complete: ).*(?<!\.torrent)$" "$LOG_FILE" | while read -r line; do
    FILENAME=$(basename "$line")
    rm -f "${FILENAME}."torrent
    rm -f "${FILENAME}."aria2
done

# Always attempt to clean up .torrent and .aria2 files
grep -oP "(?<=not complete: ).*(?<!\.torrent)$" "$LOG_FILE" | while read -r line; do
    FILENAME=$(basename "$line")
    rm -f "${FILENAME}."torrent
done

# Exit with success code if all files downloaded successfully, error otherwise
if [ "$download_success" -eq 1 ]; then
    echo "All files downloaded successfully."
    exit 0
else
    echo "One or more files failed to download."
    exit 1
fi
