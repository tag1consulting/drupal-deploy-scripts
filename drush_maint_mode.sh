#!/bin/bash
#
# Enable or disable maintenance mode on a given site.
# This is a simple wrapper script that can be added to sudo config
# so that the deploy user can run drush as the Apache/web user.

# Change this if deploy_settings file is in a different location.
DEPLOY_SETTINGS=/usr/local/deploy/deploy_settings

usage() {
  echo "usage: $0 [-d @drush_alias] [-m [0|1]]"
  echo "    -d          Specify drush alias (include leading @)"
  echo "    -m          Mode to set: 0 disables maintenance mode, 1 enables maintenance mode."
  echo ""
  echo "Both arguments are required."
  exit 1
}

while getopts "d:m:" opt; do
  case $opt in
    d)
      DRUSH_ALIAS=$OPTARG
      ;;
    m)
      MODE=$OPTARG
      ;;
    *)
      usage
  esac
done

if [ -z "${DRUSH_ALIAS}" ] || [ -z "${MODE}" ]
then
  usage
fi

# Ensure mode is valid.
if [ "$MODE" != "0" ] && [ "$MODE" != "1" ]
then
  usage
fi

# Get shared settings for deploy scripts.
if [ -f  $DEPLOY_SETTINGS ]
then
  . $DEPLOY_SETTINGS
else
  echo "Deploy settings file (${DEPLOY_SETTINGS}) is missing."
  exit 1
fi

HOSTNAME=$(uname -n)

echo "On host ${HOSTNAME}"
echo "Going to set maintenance_mode: $MODE on site: $DRUSH_ALIAS"

$DRUSH_CMD $DRUSH_ALIAS vset maintenance_mode $MODE || { echo "Drush command exited with an error."; exit 1; }
