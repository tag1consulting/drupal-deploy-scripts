#!/bin/bash

# Take a snapshot of a Drupal database for a given Drush alias.

usage() {
  echo "usage: $0 [-d @drush_alias]"
  echo "    -d          Specify drush alias (include leading @)"
  echo ""
  echo "Both arguments are required."
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

DB_SNAPSHOT_DIR=$(drush $DRUSH_ALIAS db-snapshot-dir 2>/dev/null)

if [ -z "${DB_SNAPSHOT_DIR}" ] || [ ! -d $DB_SNAPSHOT_DIR ]
then
  echo "Output directory (${DB_SNAPSHOT_DIR}) doesn't exist. Ensure ['shell-aliases']['db-snapshot-dir'] is set for this drush alias."
  exit
fi

DATE=$(date +"%Y%m%d%H%M")
OUTFILE=${DB_SNAPSHOT_DIR}/${DRUSH_ALIAS}-${DATE}.sql.gz

/usr/bin/drush @${DRUSH_ALIAS} sql-dump --gzip > ${OUTFILE}
ls -lh ${OUTFILE}
