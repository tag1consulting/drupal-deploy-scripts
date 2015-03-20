#!/bin/bash
#
# Update the webroot symlink to point at a new release tag.
# Use with care, this updates the LIVE website symlink.

# Change this if deploy_settings file is in a different location.
DEPLOY_SETTINGS=/usr/local/deploy/deploy_settings

usage() {
  echo "usage: $0 [-d @drush_alias] [-t git tag]"
  echo "    -d          Specify drush alias (include leading @)"
  echo "    -t          Specify git tag to link to"
  echo ""
  echo "Both arguments are required."
  exit 1
}

while getopts "d:t:" opt; do
  case $opt in
    d)
      DRUSH_ALIAS=$OPTARG
      ;;
    t)
      GIT_TAG=$OPTARG
      ;;
    *)
      usage
  esac
done

if [ -z "${DRUSH_ALIAS}" ] || [ -z "${GIT_TAG}" ]
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

BASEDIR=$(drush $DRUSH_ALIAS basedir 2>/dev/null)

if [ -z "${BASEDIR}" ] || [ ! -d $BASEDIR ]
then
  echo "Base directory (${BASEDIR}) doesn't exist. Ensure ['shell-aliases']['basedir'] is set for this drush alias."
  exit 1
fi

HOSTNAME=$(uname -n)

RELEASE_DIR=${BASEDIR}/${RELEASE_DIR_NAME}
WEBROOT_SYMLINK=${BASEDIR}/${WEBROOT_SYMLINK_NAME}
TARGET_DIR=${RELEASE_DIR}/${GIT_TAG}

if [ ! -d $TARGET_DIR ]
then
  echo "Target release directory $TARGET_DIR does not exist."
  exit 1
fi

echo "On host $HOSTNAME"
echo "Going to update web symlink to point to $TARGET_DIR"

rm -f $WEBROOT_SYMLINK || { echo "Error removing old symlink."; exit 1; }
ln -s $TARGET_DIR $WEBROOT_SYMLINK || { echo "Error creating new symlink."; exit 1; }

echo "Outputting ls of new symlink:"
ls -l $WEBROOT_SYMLINK
