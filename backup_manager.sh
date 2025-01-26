#!/bin/bash

# Figure out where the script is relatively located to find subscripts and config
readonly SCRIPT_DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)"
cd $SCRIPT_DIR

## Load config file vars ##
## Commented out ones are not used in this script, however I want to show what to do
##   to load in all the possible variables:
# Intranet server ip
readonly INTRANET_IP="$(cat ./config.conf | grep 'intranet_ip' | cut -d '=' -f 2)"

# Intranet user to ssh with
#readonly INTRANET_USER="$(cat ./config.conf | grep 'intranet_user' | cut -d '=' -f 2)"

# Intranet remote directory
#readonly INTRANET_DIR="$(cat ./config.conf | grep 'intranet_dir' | cut -d '=' -f 2)"

# Time to wait in seconds between intranet backups
readonly INTRANET_INCR="$(cat ./config.conf | grep 'intranet_incr' | cut -d '=' -f 2)"

# Intranet keyfile name
#readonly INTRANET_KEY="$(cat ./config.conf | grep 'intranet_key' | cut -d '=' -f 2)"

# Directory the logs are stored
readonly LOG_DIR="$(cat ./config.conf | grep 'log_dir' | cut -d '=' -f 2)"

# Local backup directory
#readonly LOCAL_DIR="$(cat ./config.conf | grep 'local_dir' | cut -d '=' -f 2)"

# Time to wait in seconds between local backups
readonly LOCAL_INCR="$(cat ./config.conf | grep 'local_incr' | cut -d '=' -f 2)"
## End of config file vars ##

# Define date format #
readonly DATE_FORMAT="+%Y-%m-%d_%H:%M:%S"

# Define current date #
readonly DATETIME="$(date ${DATE_FORMAT})"
readonly TODAY="$(date '+%s')"

# If these file doesn't exist define it to the unix epoch to force them to run #
# Intranet Last Backup:
if [ ! -f "${LOG_DIR}/intranetday.log" ]; then
  echo "$(date -d 'January 1, 1970' '${DATE_FORMAT}' | tr '_' ' ')" > "${LOG_DIR}/intranetday.log"
fi
# Local Last Backup:
if [ ! -f "${LOG_DIR}/localday.log" ]; then
  echo "$(date -d 'January 1, 1970' '${DATE_FORMAT}' | tr '_' ' ')" > "${LOG_DIR}/localday.log"
fi

# Read last local day and 1 day ago in unix timestamps #
readonly LAST_LOCAL="$(date -f ${LOG_DIR}/localday.log '+%s')"
readonly TEST_LOCAL="$(($TODAY - $LOCAL_INCR))"

# Read last intranet day and 1 week ago in unix timestamps #
readonly LAST_INTRANET="$(date -f ${LOG_DIR}/intranetday.log '+%s')"
readonly TEST_INTRANET="$(($TODAY - $INTRANET_INCR))"

# Check if a local backup was done more than the seconds specified ago, if so run it #
if [[ $LAST_LOCAL < $TEST_LOCAL ]]; then
  # Local Backup #
  echo "Running local backup..." >> "${LOG_DIR}/${DATETIME}.log"
  bash ./backup_home_local.sh >> "${LOG_DIR}/${DATETIME}.log"

  echo "Job Done!" >> "${LOG_DIR}/${DATETIME}.log"
else
  # Else echo out that it is too soon #
  echo -e "Too soon to run local backup, list time was: $(cat ${LOG_DIR}/localday.log)" >> "${LOG_DIR}/${DATETIME}.log"
fi

# Add seperator #
echo "########################################" >> "${LOG_DIR}/${DATETIME}.log"

# Check if a intranet backup was done more than the seconds specified ago, if so run it #
if [[ $LAST_INTRANET < $TEST_INTRANET ]]; then

  # Check if remote server can be reached
  if ping -c 1 $INTRANET_IP &> /dev/null
  then
    # Do intranet backup #
    echo "Running intranet backup..." >> "${LOG_DIR}/${DATETIME}.log"
    bash ./backup_home_intranet.sh >> "${LOG_DIR}/${DATETIME}.log"

    # Save Today as last intranet backup day #
    echo "${DATETIME}" | tr "_" " " > "${LOG_DIR}/intranetday.log"

    echo "Job Done!" >> "${LOG_DIR}/${DATETIME}.log"
  else
    echo "Remote server $INTRANET_IP is unreachable :(" >> "${LOG_DIR}/${DATETIME}.log"
  fi
else
  # Else echo out that it is too soon #
  echo -e "Too soon to run intranet backup, list time was: $(cat ${LOG_DIR}/intranetday.log)" >> "${LOG_DIR}/${DATETIME}.log"
fi

## TODO: backup to a datacenter or something, IDK ##

# End of Log #
echo "END OF LOG" >> "${LOG_DIR}/${DATETIME}.log"
