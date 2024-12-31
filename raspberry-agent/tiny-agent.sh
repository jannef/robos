#!/bin/bash

# Function definitions
log() {
    echo "$1"
}

REPO_URL="https://github.com/jannef/robos"
REPO_DIR="/usr/local/bin/robos"
BRANCH="main"
SCRIPT_TO_RUN="example.sh"

log "Start"

# Critical section
if [ -d "$REPO_DIR/.git" ]; then
    # Directory exists and is a git repo; check for updates
    log "Checking for updates on '$REPO_URL:$BRANCH'"
    git -C "$REPO_DIR" fetch origin
    
    # Compare local HEAD to remote
    LOCAL=$(git -C "$REPO_DIR" rev-parse HEAD)
    REMOTE=$(git -C "$REPO_DIR" rev-parse "origin/$BRANCH")
    
    if [ "$LOCAL" != "$REMOTE" ]; then
        git -C "$REPO_DIR" checkout "$BRANCH"    
        git -C "$REPO_DIR" pull origin "$BRANCH"
        
        # Run the specified script
        log "Running '$SCRIPT_TO_RUN'"
        bash "$REPO_DIR/$SCRIPT_TO_RUN"
    else
        log "No changes found in '$BRANCH' branch"
    fi
    
else
    # Not sure if this makes sense -- perhaps manual installation is
    # for the best? Need the systemd service from the repo anyhow.
    git clone "$REPO_URL" "$REPO_DIR"
    git -C "$REPO_DIR" checkout "$BRANCH"
    bash "$REPO_DIR/$SCRIPT_TO_RUN"
fi

# Cleanup
log "Done"