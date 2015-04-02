#!/bin/bash
#
# Run a 'drush updb' for a specified site.
# This is a simple wrapper script that can be added to sudo config
# so that the deploy user can run drush as the Apache/web user.

# Change this if deploy_settings file is in a different location.
DEPLOY_SETTINGS=/usr/local/deploy/deploy_settings

usage() {
  echo "usage: $0 [-d @drush_alias]"
  echo "    -d          Specify drush alias (include leading @)"
  echo ""
  echo "Drush alias is required."
  exit 1
}

while getopts "d:" opt; do
  case $opt in
    d)
      DRUSH_ALIAS=$OPTARG
      ;;
    *)
      usage
  esac
done

if [ -z "${DRUSH_ALIAS}" ]
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
echo "Going to run pending database updates on site: $DRUSH_ALIAS"

$DRUSH_CMD $DRUSH_ALIAS updb -y || { echo "Drush command exited with an error."; exit 1; }
