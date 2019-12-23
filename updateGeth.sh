#!/bin/sh
# Enter the go-ethereum folder
# Change this to wherever you pulled the repo
cd /opt/go-ethereum

# Run a remote update to pull down latest information
git remote update

UPSTREAM=${1:-'@{u}'}
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse "$UPSTREAM")
BASE=$(git merge-base @ "$UPSTREAM")

# Upgrade if needed
if [ $LOCAL = $REMOTE ]; then
    echo "Geth is up to date"
elif [ $LOCAL = $BASE ]; then
    echo "Upgrading Geth"
    git pull
    supervisorctl stop geth
    make geth
    supervisorctl start geth
elif [ $REMOTE = $BASE ]; then
    echo "Need to push?"
else
    echo "Your go-ethereum repo has diverged"
fi
