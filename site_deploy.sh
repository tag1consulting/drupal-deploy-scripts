#!/bin/bash
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

GIT_REPO_URL=$(drush $DRUSH_ALIAS giturl 2>/dev/null)
if [ -z "${GIT_REPO_URL}" ]
then
  echo "Git repo URL is empty. Ensure ['shell-aliases']['giturl'] is set for this drush alias."
  exit 1
fi

ENVIRONMENT=$(drush $DRUSH_ALIAS site-environment 2>/dev/null)
if [ -z "${ENVIRONMENT}" ]
then
  echo "Site environment is empty. Ensure ['shell-aliases']['site-environment'] is set for this drush alias. (e.g. "dev" or "prod")."
  exit 1
fi

# Get site dir (e.g. "sites/some.host.com") if set, otherwise set to default of "sites/default".
DRUPAL_SITE_DIR=$(drush $DRUSH_ALIAS sitedir 2>/dev/null)

if [ -z "${DRUPAL_SITE_DIR}" ]
then
  DRUPAL_SITE_DIR=sites/default
fi

HOSTNAME=$(uname -n)

GIT_DIR=${BASEDIR}/${GIT_DIR_NAME}
RELEASE_DIR=${BASEDIR}/${RELEASE_DIR_NAME}
FILES_DIR=${BASEDIR}/${FILES_DIR_NAME}

echo "Going to deploy $GIT_TAG on $HOSTNAME"

if [ ! -d ${GIT_DIR} ]
then
  mkdir ${GIT_DIR}
fi

if [ -d ${GIT_DIR}/.git ]
then
  echo "Found .git directory, looks like a clone already exists."
  cd $GIT_DIR
  echo "Running git fetch --all"
  /usr/bin/git fetch --all || { echo "Error with git fetch command."; exit 1; }
  echo "Running git fetch --tags"
  /usr/bin/git fetch --tags || { echo "Error with git fetch command."; exit 1; }
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

# Symlink to the files directory
cd ${GIT_DIR}/${DRUPAL_SITE_DIR}
ln -s ${FILES_DIR} files

echo "Creating symlink for settings.local.php."
cd ${GIT_DIR}/${DRUPAL_SITE_DIR}
ln -s instances/${ENVIRONMENT}/settings.local.php settings.local.php

LINK_SERVICES_YML=$(drush $DRUSH_ALIAS link-services-yml 2>/dev/null)
if [ ! -z "${LINK_SERVICES_YML}" ]
then
  echo "Creating symlink for services.yml"
  cd ${GIT_DIR}/${DRUPAL_SITE_DIR}
  ln -s instances/${ENVIRONMENT}/services.yml services.yml
fi

# Now, do the actual deploy of a git tag (or branch)

echo "Checking that target tag exists..."
# ideally would use --short flag for this, but not supported in our version of git
# so using cut instead.
CUR_BRANCH=$(/usr/bin/git symbolic-ref -q HEAD | cut -d / -f 3)
/usr/bin/git checkout $GIT_TAG
ret=$?
# Switch back to the old branch (usually master)
/usr/bin/git checkout ${CUR_BRANCH}

if [ $ret != 0 ]
then
  echo "Error with git checkout command, looks like target tag doesn't exist."
  exit 1
fi

TARGET_DIR=${RELEASE_DIR}/${GIT_TAG}

# Copy base git clone to target directory
cp -a $GIT_DIR $TARGET_DIR

# Touch target dir so it has a valid timestamp for the deployment.
touch $TARGET_DIR
cd $TARGET_DIR

echo "Running git checkout $GIT_TAG"
/usr/bin/git checkout $GIT_TAG || { echo "Error with git checkout command."; exit 1; }
