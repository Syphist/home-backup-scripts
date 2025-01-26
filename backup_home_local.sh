#!/bin/bash

# Set environment
set -o errexit
set -o nounset
set -o pipefail

## Load config file vars
# Local backup directory
readonly LOCAL_DIR="$(cat ./config.conf | grep 'local_dir' | cut -d '=' -f 2)"

# Variables
readonly SOURCE_DIR="${HOME}"
readonly DATETIME="$(date '+%Y-%m-%d_%H:%M:%S')"
readonly BACKUP_PATH="${LOCAL_DIR}/${DATETIME}"
readonly LATEST_LINK="${LOCAL_DIR}/latest"

# Make directory for backup
mkdir -p "${BACKUP_PATH}"

# rsync command
rsync -av --delete \
  "${SOURCE_DIR}/" \
  --link-dest "${LATEST_LINK}" \
  --exclude-from="./exclude.list" \
  "${BACKUP_PATH}"

# Remove the latest link dir if it exists
if [ -d "${LATEST_LINK}" ]; then
  rm -rf "${LATEST_LINK}"
fi

# Create latest link for the latest backup
ln -s "${BACKUP_PATH}" "${LATEST_LINK}"
