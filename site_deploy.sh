#!/usr/bin/env bash
# site_deploy.sh:
# Clone a site's git repo if it doesn't already exist locally.
# Creates a 'releases' directory, and does the following within the git clone:
# 1. Symlink to external files/ directory.
# 2. Symlink to local settings file.
# 3. Symlink to local services.yml file if specified (for D8).
# Then deploys the specified git tag to the releases directory.

# Change this if deploy_settings file is in a different location.
DEPLOY_SETTINGS=/usr/local/deploy/deploy_settings

usage() {
  echo "usage: $0 [-d @drush_alias] [-t git tag] [-f]"
  echo "    -d          Specify drush alias (include leading @)"
  echo "    -t          Specify git tag to link to"
  echo "    -f          Force deploy even if the target release directory already exists."
  echo ""
  echo "-d and -t arguments are required."
  exit 1
}

FORCE=0

while getopts "d:ft:" opt; do
  case $opt in
    d)
      DRUSH_ALIAS=$OPTARG
      ;;
    f)
      FORCE=1
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

GIT_REPO_URL=$($DRUSH_CMD $DRUSH_ALIAS giturl 2>/dev/null)
if [ -z "${GIT_REPO_URL}" ]
then
  echo "Git repo URL is empty. Ensure ['shell-aliases']['giturl'] is set for this drush alias."
  exit 1
fi

ENVIRONMENT=$($DRUSH_CMD $DRUSH_ALIAS site-environment 2>/dev/null)
if [ -z "${ENVIRONMENT}" ]
then
  echo "Site environment is empty. Ensure ['shell-aliases']['site-environment'] is set for this drush alias. (e.g. "dev" or "prod")."
  exit 1
fi

# Get site dir (e.g. "sites/some.host.com") if set, otherwise set to default of "sites/default".
DRUPAL_SITE_DIR=$($DRUSH_CMD $DRUSH_ALIAS sitedir 2>/dev/null)

if [ -z "${DRUPAL_SITE_DIR}" ]
then
  DRUPAL_SITE_DIR=docroot/sites/default
fi

HOSTNAME=$(uname -n)

GIT_DIR=${BASEDIR}/${GIT_DIR_NAME}
RELEASE_DIR=${BASEDIR}/${RELEASE_DIR_NAME}
FILES_DIR=${BASEDIR}/${FILES_DIR_NAME}

echo "Going to deploy $GIT_TAG on $HOSTNAME"

TARGET_DIR=${RELEASE_DIR}/${GIT_TAG}

# In most cases we don't want to overwrite a release dir if it already exists.
# But on Dev sites where we may deploy a branch name (e.g. "dev"), we may want to replace an old release dir.
# Only do so if the force (-f) flag was passed.
if [ -d $TARGET_DIR ] && [ $FORCE != 1 ]
then
  echo "Target release directory (${TARGET_DIR}) already exists, won't overwrite without -f flag."
  exit 1
fi

# Create git directory if it doesn't exist.
if [ ! -d ${GIT_DIR} ]
then
  mkdir ${GIT_DIR}
fi

# Run git fetch in git directory if a clone already exits, otherwise clone from remote git URL.
if [ -d ${GIT_DIR}/.git ]
then
  echo "Found .git directory, looks like a clone already exists."
  cd $GIT_DIR
  echo "Running git fetch --all"
  /usr/bin/git fetch --all || { echo "Error with git fetch --all command."; exit 1; }
  echo "Running git fetch --tags"
  /usr/bin/git fetch --tags || { echo "Error with git fetch --tags command."; exit 1; }
  echo "Updating current clone with git pull"
  /usr/bin/git pull || { echo "Error with git pull command."; exit 1; }
else
  echo "Git directory doesn't exist, cloning from remote."
  cd ${GIT_DIR}
  git clone ${GIT_REPO_URL} . || { echo "Error with git clone command."; exit 1; }
fi

# Create the releases directory if it doesn't already exist
if [ ! -d ${RELEASE_DIR} ]
then
  mkdir ${RELEASE_DIR}
fi

# All symlinks are removed and re-created with each deploy
# To be sure all links match the current environment.

# We assume 'files' is a symlink, error out if not to prevent erasing site files.
if [ -f ${GIT_DIR}/${DRUPAL_SITE_DIR}/files ] && [ ! -L ${GIT_DIR}/${DRUPAL_SITE_DIR}/files ]
then
  echo "${GIT_DIR}/${DRUPAL_SITE_DIR}/files exists and is not a symlink, refusing to delete it."
  exit 1
fi

# Symlink to the files directory
cd ${GIT_DIR}/${DRUPAL_SITE_DIR}
rm -f files
ln -s ${FILES_DIR} files

echo "Creating symlink for settings.local.php."
cd ${GIT_DIR}/${DRUPAL_SITE_DIR}
rm -f settings.local.php
ln -s instances/${ENVIRONMENT}/settings.local.php settings.local.php

LINK_SERVICES_YML=$($DRUSH_CMD $DRUSH_ALIAS link-services-yml 2>/dev/null)
if [ "${LINK_SERVICES_YML}" == "true" ]
then
  echo "Creating symlink for services.yml"
  cd ${GIT_DIR}/${DRUPAL_SITE_DIR}
  rm -f services.yml
  ln -s instances/${ENVIRONMENT}/services.yml services.yml
fi

# Now, do the actual deploy of a git tag (or branch)

echo "Checking that target tag exists..."
# ideally would use --short flag for this, but not supported in our version of git
# so using cut instead.
CUR_BRANCH=$(/usr/bin/git symbolic-ref -q HEAD | cut -d / -f 3)
/usr/bin/git checkout $GIT_TAG 2>/dev/null
ret=$?
# Switch back to the old branch (usually master)
/usr/bin/git checkout ${CUR_BRANCH} 2>/dev/null

if [ $ret != 0 ]
then
  echo "Error with git checkout command, looks like target tag doesn't exist."
  exit 1
fi

# Remove target directory if it exists and -f was specified.
if [ -d $TARGET_DIR ] && [ $FORCE == 1 ]
then
  echo "Target release directory exists, but -f was specified. Removing old directory..."
  rm -fr $TARGET_DIR
fi

# Copy base git clone to target directory
cp -a $GIT_DIR $TARGET_DIR

# Touch target dir so it has a valid timestamp for the deployment.
touch $TARGET_DIR
cd $TARGET_DIR

echo "Running git checkout $GIT_TAG"
/usr/bin/git checkout $GIT_TAG 2>/dev/null || { echo "Error with git checkout command."; exit 1; }
