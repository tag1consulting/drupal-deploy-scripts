# Drupal Deployment Scripts
These scripts are used to deploy Drupal sites. They expect the site code is in a git repo and will be deployed by specifying a git tag or a git branch name.  Generally tags are used for Staging and Production deployments, while a branch name (e.g. "dev") might be used for deploying to a dev site.

The scripts rely on a number of variables being stored in the "shell-aliases" array within a drush alias defined for the site you want to deploy to. ```example.aliases.drushrc.php``` gives an example of the expected settings. By "hacking" these into a Drush alias, we are able to keep all the deployment settings in the same place as the site's Drush definition instead of maintaining separate settings only for deployments.

The ```deploy_settings``` file contains some default settings (mostly directory names at this point) used by the deployment scripts. Generally you shouldn't have to edit this file.

## Scripts
* ```adjust_live_symlink.sh``` is used to update a site's symlink to point to a given release directory. This is generally called after deploying a tag in order to adjust the ```current``` symlink to point to the newly-deployed version of the site.
* ```db_snapshot.sh``` is used to create an SQL dump of a site's database using ```drush sql-dump --gzip```. The output directory is taken from the ```['shell-aliases']['db-snapshot-dir']``` setting within a site's Drush alias definition.
* ```drush_cache_clear.sh``` is a wrapper script around ```drush cc all``` for a given Drush alias.
* ```drush_db_update.sh``` is a wrapper script around ```drush updb``` for a given Drush alias.
* ```drush_maint_mode.sh``` is a wrapper script to enable or disable Drupal maintenance mode for a given Drush alias.
* ```site_deploy.sh``` is the main script used to deploy code. It accepts a Drush alias and a git tag (or branch name) as an argument, and will deploy the given git tag to the specified site's webroot. For more information, see the "Deployment" section below.

## Deployments
In order to not overwrite the code on a currently-running site, the ```site_deploy.sh``` script uses a "git working" directory to clone/update code, and then copies that directory into a "release" directory, ```releases/<tag_name>```. For staging and produciton sites, the deployment is expected to be a git tag since this gives an easy way to roll back to a previous release and to know at a glance which version is running in a given environment. For dev sites, the script can instead deploy HEAD of a given branch name. In this case, run ```site_deploy.sh``` with the '-f' flag to force overwriting the target release directory.

A typical Drupal deployment may follow the following steps:

1. Take snapshot of DB (```db_snapshot.sh```).
2. Enable maintenance mode (```drush_maint_mode.sh```), then cache-clear (```drush_cache_clear.sh```).
3. Deploy new code (```site_deploy.sh```).
4. Run DB updates (```drush_db_update.sh```).
5. Take site out of maintenance mode (```drush_maint_mode.sh```), then cache-clear (```drush_cache_clear.sh```).

Example, deploying the tag '1.0.1' to the site '@example.stage':
```
$ db_snapshot.sh -d @example.stage
$ sudo -u apache drush_maint_mode.sh -d @example.stage -m 1
$ sudo -u apache drush_cache_clear.sh -d @example.stage
$ site_deploy.sh -d @example.stage -t 1.0.1 -f
$ adjust_live_symlink.sh -d @example.stage -t 1.0.1
$ sudo -u apache drush_db_update.sh -d @example.stage
$ sudo -u apache drush_maint_mode.sh -d @example.stage -m 0
```


## Directory Structure
The scripts will setup a directory structure within the given base directory (definied in your Drush alias).

```
  /path/to/basedir
    /current
    /files
    /releases
      /<tag/branch name>
    /site_git
```

```current``` is a symlink to the current release. This is assumed to be the docroot defined in your webserver for the site.
```files``` is the drupal files directory (should be manually copied in place). A symlink will be created within the site's directory (sites/default/) to point to this location.
```releases``` holds multiple directories, one for each tag/branch deployed.
```site_git``` is the git "working" directory where ```git pull``` and ```git fetch``` commands are run prior to copying it out to a specific release directory.
