#!/bin/bash
#
# Run a 'drush cc all' for a specified site.
# This is a simple wrapper script that can be added to sudo config
# so that the deploy user can run a cache clear as the Apache/web user.
# For d8 sites, this will call 'cache-rebuild' if you pass the -r flag.

usage() {
  echo "usage: $0 [-d @drush_alias] [-r]"
  echo "    -d          Specify drush alias (include leading @)"
  echo "    -r          Call cache-rebuild instead of cache-clear (use this for D8 sites)"
  echo ""
  echo "Drush alias is required."
  exit 1
}

# Default drush command is 'cc all'. Override if -r is specified.
COMMAND='cc all'

while getopts "d:r" opt; do
  case $opt in
    d)
      DRUSH_ALIAS=$OPTARG
      ;;
    r)
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

HOSTNAME=$(uname -n)

echo "On host ${HOSTNAME}"
echo "Going to clear all caches on site: $DRUSH_ALIAS"

/usr/bin/drush $DRUSH_ALIAS $COMMAND || { echo "Drush command exited with an error."; exit 1; }
