#!/bin/bash
#
# Run a 'drush updb' for a specified site.
# This is a simple wrapper script that can be added to sudo config
# so that the deploy user can run drush as the Apache/web user.

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

HOSTNAME=$(uname -n)

echo "On host ${HOSTNAME}"
echo "Going to run pending database updates on site: $DRUSH_ALIAS"

/usr/bin/drush $DRUSH_ALIAS updb -y || { echo "Drush command exited with an error."; exit 1; }
