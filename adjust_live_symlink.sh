#!/bin/bash
#
# Update the webroot symlink to point at a new release tag.
# Use with care, this updates the LIVE website symlink.
# If passed the -c flag, it will also update symlinks to the Drupal config directory.

# Change this if deploy_settings file is in a different location.
DEPLOY_SETTINGS=/usr/local/deploy/deploy_settings

usage() {
  echo "usage: $0 [-d @drush_alias] [-t git tag]"
  echo "    -d          Specify drush alias (include leading @)"
  echo "    -t          Specify git tag to link to"
  echo "    -c          Also create symlink for the Drupal config directory"
  echo ""
  echo "-d and -t arguments are required."
  exit 1
}

CONFIG_SYMLINK=false

while getopts "d:t:c" opt; do
  case $opt in
    c)
      CONFIG_SYMLINK=true
      ;;
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

BASEDIR=$($DRUSH_CMD $DRUSH_ALIAS basedir 2>/dev/null)

if [ -z "${BASEDIR}" ] || [ ! -d $BASEDIR ]
then
  echo "Base directory (${BASEDIR}) doesn't exist. Ensure ['shell-aliases']['basedir'] is set for this drush alias."
  exit 1
fi

HOSTNAME=$(uname -n)

RELEASE_DIR=${BASEDIR}/${RELEASE_DIR_NAME}
WEBROOT_SYMLINK=${BASEDIR}/${WEBROOT_SYMLINK_NAME}
TARGET_DIR=${RELEASE_DIR}/${GIT_TAG}/${DOCROOT_DIR_NAME}

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

if [ "$CONFIG_SYMLINK" == "true" ]
then
  echo "Updating symlink to Drupal config directory."
  CONFIG_DIR=$($DRUSH_CMD $DRUSH_ALIAS config-dir 2>/dev/null)
  if [ -z "${CONFIG_DIR}" ] || [ ! -d ${RELEASE_DIR}/${GIT_TAG}/${CONFIG_DIR} ]
  then
    echo "Config directory (${RELEASE_DIR}/${GIT_TAG}/${CONFIG_DIR}}) doesn't exist. Ensure ['shell-aliases']['config-dir'] is set for this drush alias."
    exit 1
  fi
  # Error out if our config symlink already exists but isn't a symlink.
  if [ -f ${BASEDIR}/${CONFIG_DIR} ] && [ ! -L ${BASEDIR}/${CONFIG_DIR} ]
  then
    echo "${BASEDIR}/${CONFIG_DIR} exists and is not a symlink, refusing to delete it."
    exit 1
  fi
  rm -f ${BASEDIR}/${CONFIG_DIR}
  ln -s ${RELEASE_DIR}/${GIT_TAG}/${CONFIG_DIR} ${BASEDIR}/${CONFIG_DIR}
  echo "Outputting ls of new config symlink:"
  ls -l ${BASEDIR}/${CONFIG_DIR}
fi
