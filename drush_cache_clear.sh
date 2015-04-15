#!/usr/bin/env bash
#
# Run a 'drush cc all' for a specified site.
# This is a simple wrapper script that can be added to sudo config
# so that the deploy user can run a cache clear as the Apache/web user.
# For d8 sites, this will call 'cache-rebuild' if you pass the -8 flag.

# Change this if deploy_settings file is in a different location.
DEPLOY_SETTINGS=/usr/local/deploy/deploy_settings

usage() {
  echo "usage: $0 [-d @drush_alias] [-8]"
  echo "    -d          Specify drush alias (include leading @)"
  echo "    -8          Call cache-rebuild instead of cache-clear (use this for D8 sites)"
  echo ""
  echo "Drush alias is required."
  exit 1
}

# Default drush command is 'cc all'. Override if -r is specified.
COMMAND='cc all'

while getopts "d:8" opt; do
  case $opt in
    d)
      DRUSH_ALIAS=$OPTARG
      ;;
    8)
      COMMAND=cr
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
echo "Going to clear all caches on site: $DRUSH_ALIAS"

$DRUSH_CMD $DRUSH_ALIAS $COMMAND || { echo "Drush command exited with an error."; exit 1; }
