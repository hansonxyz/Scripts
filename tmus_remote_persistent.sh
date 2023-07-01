#!/bin/bash

# This script creates a new tmux session on a remote server and automatically
# reattaches to the session if the SSH connection is lost.

# Check the number of arguments.
if [ $# -lt 1 ]; then
    echo "Usage: $0 [--list|--restore [<session-name>]] <server> [<initial-command>]"
    echo "Example: $0 \"-p 2222 user@server\" \"cd /path/to/mydir; sudo bash\""
    exit 1
fi

# Check if the first argument is a flag.
if [[ "$1" =~ ^-- ]]; then
    FLAG=$1
    shift
fi

# Check if a session name is provided for the --restore flag.
if [[ "$FLAG" == "--restore" && -n "$1" ]]; then
    RESTORE_SESSION="persistent_$1"
    shift
fi

# Assign arguments to variables.
SERVER=$1

# If the initial command is not provided, use a default command.
if [ -z "$2" ]; then
    INITIAL_COMMAND="bash"
else
    INITIAL_COMMAND=$2
fi

# Check if a session name is provided for session creation, otherwise generate one.
if [ -z "$3" ]; then
    ID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
    SESSION="persistent_${ID}"
else
    SESSION="persistent_$3"
fi

# Handle flags.
if [ "$FLAG" == "--list" ]; then
    echo "Listing sessions:"
    ssh -o BatchMode=yes -o ConnectTimeout=15 -o ServerAliveInterval=15 -o ServerAliveCountMax=3 ${SERVER} "tmux list-sessions -F '#{session_name}' | grep '^persistent_' | sed 's/^persistent_//'"
    exit
elif [ "$FLAG" == "--restore" ]; then
    if [ -n "$RESTORE_SESSION" ]; then
        EXISTS=$(ssh -o BatchMode=yes -o ConnectTimeout=15 -o ServerAliveInterval=15 -o ServerAliveCountMax=3 ${SERVER} "tmux has-session -t ${RESTORE_SESSION} 2>/dev/null")
        if [ $? -eq 0 ]; then
            echo "Restoring session $RESTORE_SESSION"
            ssh -o ConnectTimeout=15 -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -t ${SERVER} "tmux attach-session -t ${RESTORE_SESSION}"
            exit
        else
            echo "Session $RESTORE_SESSION does not exist."
            # Continue to the rest of the script to create a new session.
        fi
    else
        DETACHED_SESSION=$(ssh -o BatchMode=yes -o ConnectTimeout=15 -o ServerAliveInterval=15 -o ServerAliveCountMax=3 ${SERVER} "tmux list-sessions -F '#{session_name} #{session_attached}' | awk '\$2 == 0 {print \$1; exit}'")
        if [ -n "$DETACHED_SESSION" ]; then
            echo "Restoring detached session $DETACHED_SESSION"
            ssh -o ConnectTimeout=15 -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -t ${SERVER} "tmux attach-session -t ${DETACHED_SESSION}"
            exit
        else
            echo "No detached sessions found."
            # Continue to the rest of the script to create a new session.
        fi
    fi
fi

# Check if the last command was 'cd'.  If it was, add bash.
# Get the array of commands
IFS=';' read -ra COMMANDS <<< "${INITIAL_COMMAND}"
LAST_COMMAND=${COMMANDS[-1]}

# Trim leading and trailing whitespaces in the last command
LAST_COMMAND="$(echo -e "${LAST_COMMAND}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

# If the last command starts with "cd "
if [[ "${LAST_COMMAND}" =~ ^cd\  ]]; then
    INITIAL_COMMAND="${INITIAL_COMMAND}; bash"
fi

# Turn off the tmux status bar.
INITIAL_COMMAND="tmux set status off; ${INITIAL_COMMAND}"

# Attempt to create watchdog shell.

# Function to base64 encode a command string
encode_command() {
    echo -n "$1" | base64 -w 0
}

# Check if the session exists on the server. If it does not, create it.
EXISTS=$(ssh -o BatchMode=yes -o ConnectTimeout=15 -o ServerAliveInterval=15 -o ServerAliveCountMax=3 ${SERVER} "tmux has-session -t ${SESSION} 2>/dev/null")

if [ $? != 0 ]; then
    ssh -o ConnectTimeout=15 -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -t ${SERVER} "echo -e 'setw -g mouse on\\nsetw -g status off' > ~/.tmux.conf; tmux new-session -d -s ${SESSION} '${INITIAL_COMMAND}' "
fi

ssh -o ConnectTimeout=15 -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -t ${SERVER} "tmux attach-session -t ${SESSION}"

# Loop until the session no longer exists on the server.
while true; do
    # Check if the session exists on the server.
    EXISTS=$(ssh -o ConnectTimeout=15 -o BatchMode=yes -o StrictHostKeyChecking=no ${SERVER} "tmux has-session -t ${SESSION} 2>/dev/null")

    # If the session doesn't exist, exit.
    if [ $? != 0 ]; then
        exit
    fi

    # Otherwise, connect to the session.
    echo "Reattaching to existing session."
    ssh -o ConnectTimeout=15 -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -t ${SERVER} "tmux attach-session -t ${SESSION}"
    SSH_EXIT_STATUS=$?

    # After disconnecting, if the exit status was 255 (SSH lost connection), wait 10 seconds before reconnecting.
    if [ $SSH_EXIT_STATUS -eq 255 ]; then
        echo "Disconnected from server. Reconnecting in 10 seconds..."
        sleep 10
    fi
done
