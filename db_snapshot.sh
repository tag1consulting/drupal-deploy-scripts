#!/usr/bin/env bash
#
# Take a snapshot of a Drupal database for a given Drush alias.

# Change this if deploy_settings file is in a different location.
DEPLOY_SETTINGS=/usr/local/deploy/deploy_settings

usage() {
  echo "usage: $0 [-d @drush_alias]"
  echo "    -d          Specify drush alias (include leading @)"
  echo ""
  echo "-d argument is required."
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

DB_SNAPSHOT_DIR=$($DRUSH_CMD $DRUSH_ALIAS db-snapshot-dir 2>/dev/null)
DB_SNAPSHOT_DIR="/data/db_snapshots"

if [ -z "${DB_SNAPSHOT_DIR}" ] || [ ! -d $DB_SNAPSHOT_DIR ]
then
  echo "Output directory (${DB_SNAPSHOT_DIR}) doesn't exist. Ensure ['shell-aliases']['db-snapshot-dir'] is set for this drush alias."
  exit
fi

DATE=$(date +"%Y%m%d%H%M")
# Strip leading '@' from drush alias for output filename.
SITE_NAME=${DRUSH_ALIAS:1}
OUTFILE=${DB_SNAPSHOT_DIR}/${SITE_NAME}-${DATE}.sql.gz

$DRUSH_CMD $DRUSH_ALIAS sql-dump --gzip > ${OUTFILE}
ls -lh ${OUTFILE}
