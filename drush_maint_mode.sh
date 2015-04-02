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
  echo "    -8          For Drupal 8 sites: calls 'sset' instead of 'vset'"
  echo ""
  echo "-d and -m arguments are required."
  exit 1
}

# Default for Drupal <8, "vset", this is overridden with the -8 flag.
COMMAND='vset maintenance_mode'

while getopts "d:m:8" opt; do
  case $opt in
    d)
      DRUSH_ALIAS=$OPTARG
      ;;
    m)
      MODE=$OPTARG
      ;;
    8)
      COMMAND='sset system.maintenance_mode'
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

$DRUSH_CMD $DRUSH_ALIAS $COMMAND $MODE || { echo "Drush command exited with an error."; exit 1; }
