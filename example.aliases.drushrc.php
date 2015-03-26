<?php

$aliases['dev'] = array(
  'root' => '/var/www/d8-dev.tag1consulting.com/current',
  'uri'  => 'd8-dev.tag1consulting.com',
  'path-aliases' => array(
    '%files' => 'sites/default/files',
  ),
  # We abuse shell-aliases + "echo" to store settings used by the deployment scripts.
  # This way, all Drush and Deploy settings stay together.
  # These can be used in a script with e.g. 'BASEDIR=$(drush @site.dev basedir)'.
  'shell-aliases' => array(
    'basedir' => '!echo /var/www/d8-dev.tag1consulting.com',
    'giturl'  => '!echo git@github.com:tag1consulting/d8-tag1consulting.com.git',
    'db-snapshot-dir'  => '!echo /data/backup/mysql',
    'site-environment' => '!echo dev', # This should match the instance directory name in sites/default/instances/
    'link-services-yml' => '!echo true', # This is for D8 sites; D7 sites can remove or change to false.
  ),
);
