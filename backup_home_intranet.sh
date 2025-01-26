#!/bin/bash

# Set environment
set -o errexit
set -o nounset
set -o pipefail

## Load config file vars ##
# Intranet server ip
readonly INTRANET_IP="$(cat ./config.conf | grep 'intranet_ip' | cut -d '=' -f 2)"

# Intranet user to ssh with
readonly INTRANET_USER="$(cat ./config.conf | grep 'intranet_user' | cut -d '=' -f 2)"

# Intranet remote directory
readonly INTRANET_DIR="$(cat ./config.conf | grep 'intranet_dir' | cut -d '=' -f 2)"

# Intranet keyfile name
readonly INTRANET_KEY="$(cat ./config.conf | grep 'intranet_key' | cut -d '=' -f 2)"
## End of config file vars ##

# Variables
readonly SOURCE_DIR="${HOME}"
readonly DATETIME="$(date '+%Y-%m-%d_%H:%M:%S')"
readonly BACKUP_PATH="${INTRANET_DIR}/${DATETIME}"
readonly LATEST_LINK="${INTRANET_DIR}/latest"

# rsync command
rsync -av -e "ssh -i $HOME/.ssh/$INTRANET_KEY" --delete \
  "${SOURCE_DIR}/" \
  --link-dest "${LATEST_LINK}" \
  --exclude-from="./exclude.list" \
  "${INTRANET_USER}@{INTRANET_IP}:${BACKUP_PATH}"

ssh -i $HOME/.ssh/$INTRANET_KEY ${INTRANET_USER}@{INTRANET_IP} "rm -rf '${LATEST_LINK}'; ln -s '${BACKUP_PATH}' '${LATEST_LINK}'"
