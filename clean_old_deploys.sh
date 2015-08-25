#!/usr/bin/env bash
#
# This script will clean up old release directories.
# Usage: ./clean_old_deploys.sh -d <@drush_alias> -s <save_releases>
# Will keep <save_releases> number of code deploys
# based on modification date of the release directories in e.g.
# /var/www/<sitename>/releases/
#
# It also performs a check so that the currently running tag won't be removed.
#
# This script should be run periodically (daily or weekly) to keep the code deploys
# from growing out of control.

DEPLOY_SETTINGS=/usr/local/deploy/deploy_settings
SAVE_RELEASES=10
NOOP=false

usage() {
  echo "usage: $0 [-d @drush_alias]"
  echo "    -d          Specify drush alias (include leading @)"
  echo "    -s          Number of releases to save (defaults to 10)"
  echo "    -n          Don't actually remove directories, just output what would have been removed"
  echo ""
  echo "Drush alias is required."
  exit 1
}

while getopts "d:s:n" opt; do
  case $opt in
    d)
      DRUSH_ALIAS=$OPTARG
      ;;
    s)
      SAVE_RELEASES=$OPTARG
      ;;
    n)
      NOOP=true
      ;;
    *)
      usage
  esac
done

if [ -z "${DRUSH_ALIAS}" ]
then
  usage
fi

if [ -f  $DEPLOY_SETTINGS ]
then
  . $DEPLOY_SETTINGS
else
  echo "Deploy settings file (${DEPLOY_SETTINGS}) is missing."
  exit 1
fi

# Check that number of releases to save is valid (and at least 1).
if ! [[ $SAVE_RELEASES =~ ^[0-9]+ ]]
then
  echo "Invalid argument for releases to save -- must save at least one release."
  exit 1
fi

if [ $SAVE_RELEASES -eq 0 ]
then
  echo "Must save at least one release."
  exit 1
fi

# Increment $SAVE_RELEASES by one so that it works with the tail command below.
((SAVE_RELEASES++))

BASEDIR=$($DRUSH_CMD $DRUSH_ALIAS basedir 2>/dev/null)
if [ -z "${BASEDIR}" ] || [ ! -d $BASEDIR ]
then
  echo "Base directory (${BASEDIR}) doesn't exist. Ensure ['shell-aliases']['basedir'] is set for this drush alias."
  exit 1
fi

RELEASE_DIR=${BASEDIR}/${RELEASE_DIR_NAME}

# Get list of releases to remove.
TO_REMOVE=$(ls -1t $RELEASE_DIR | tail -n +${SAVE_RELEASES})
CUR_TAG=$(readlink -f ${BASEDIR}/${WEBROOT_SYMLINK_NAME} | awk -F'/' '{print $(NF-1)}')

echo "Current running tag is: ${CUR_TAG}"

if [ "$TO_REMOVE" == "" ]
then
  echo "There is currently nothing to clean up."
  exit 0
fi

for tag in ${TO_REMOVE}
do
  if [ "$tag" != "$CUR_TAG" ]
  then
    if [ "$NOOP" == "true" ]
    then
      echo "Would have removed deploy: ${RELEASE_DIR}/${tag}"
    else
      echo "Removing deploy: ${RELEASE_DIR}/${tag}"
      rm -fr ${RELEASE_DIR}/${tag}
    fi
  else
    echo "Not removing $tag because it's currently in use."
  fi
  echo "----------"
done
