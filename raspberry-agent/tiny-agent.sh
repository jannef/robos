#!/bin/bash

# Function definitions
log() {
    echo "$1"
}

REPO_URL="https://github.com/jannef/robos"
REPO_DIR="/usr/local/bin/robos"
BRANCH="main"

# Critical section
log "Running critical section"
sleep 15

# Cleanup
log "Critical section completed"